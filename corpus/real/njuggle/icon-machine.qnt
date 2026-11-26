// icon-machine.qnt - the status-icon state machine law (njuggle v0.1.1, R1).
// Licence: AGPLv3 (janet-viz).
//
// WHAT THIS IS. The decision logic of the per-pane status-icon tracker and
// the tab-level aggregation over panes, stated as verified laws. Decision
// only: no GTK, no widgets, no PTYs - the transport that carries these
// decisions to the screen is acceptance-test territory. njuggle's double-tab
// defect was a transport failure of a correct pure function, which is why
// the WIRING law (tabAgg == the aggregation of the pane states) is a machine
// invariant here, not just arithmetic.
//
// SYMBOLIC THRESHOLDS. The attention threshold and the long threshold are
// specimens (THRESH below), not constants of any law: every law is stated
// and verified over all specimen values, so the shipped durations are a
// build parameter (candidates: 5s attention, 60s long) that the proven laws
// are indifferent to. No law below names a number.
//
// THE EVENTS. "start" (OSC 133 command start), "finish" (command end,
// focused or not), "bell" (bell / OSC 9 while a command runs), "look" (the
// pane gained focus), "tick" (one clock unit passed under a running
// command).
//
// THE LAWS.
//   L-ICON-1  red outranks all: any pane needing attention paints the tab
//             red, over running and long_running alike.
//   L-ICON-2  dim green outranks bright green: with no attention pending, a
//             long-running pane masks a fresh one in the tab aggregate.
//   L-ICON-3  the long threshold is the ONLY path into long_running: a pane
//             occupies long_running only past the threshold (invL3a), a
//             crossing tick always promotes (invL3b), and no other event
//             enters the state (lIcon3c).
//   L-ICON-4  look clears attention, not the run state (invL4).
//
// CALIBRATION. The machine is instantiated through MUT: 0 is the law as
// specified; 1-4 are the named killers, one mutation each (see the KILLER
// defs). Every verify wrapper at the bottom of this file exists in a clean
// and a killer polarity over the identical machine, and the run set has a
// green lane (wIcon/wTab, the laws on specimens) and a red lane (wneg, the
// same laws asserted against a killer over the same specimens). Import
// njuggleIconMachine(MUT = 0) for the clean law.

module njuggleIconMachine {

  const MUT: int

  type PaneState = str   // "idle" | "running" | "long_running" | "needs_attention"
  type Event = str       // "start" | "finish" | "bell" | "look" | "tick"

  type Pane = {
    st: PaneState,
    elapsed: int,        // clock units since the current command started
    runActive: bool      // a command is underway in this pane
  }

  pure def THRESH: Set[int] = Set(0, 1, 2)

  pure def IDLE_PANE: Pane = { st: "idle", elapsed: 0, runActive: false }

  // ---- the rank law: the aggregation order over pane states --------------
  // L-ICON-1 puts needs_attention above everything; L-ICON-2 puts
  // long_running above running; running above idle.

  pure def rank(s: PaneState): int =
    if (s == "needs_attention") { 3 }
    else { if (s == "long_running") { 2 }
    else { if (s == "running") { 1 } else { 0 } } }

  pure def agg2(a: PaneState, b: PaneState): PaneState =
    if (rank(a) >= rank(b)) { a } else { b }

  // ---- the per-event decision functions (pure; the machine composes them)

  pure def startNext(p: Pane): Pane =
    { st: "running", elapsed: 0, runActive: true }

  pure def finishNext(p: Pane, focused: bool, attSecs: int): Pane =
    if (and(not(focused), p.elapsed > attSecs))
      { { st: "needs_attention", elapsed: p.elapsed, runActive: false } }
    else { { st: "idle", elapsed: p.elapsed, runActive: false } }

  pure def bellNext(p: Pane): Pane =
    { st: "needs_attention", elapsed: p.elapsed, runActive: p.runActive }

  pure def tickNext(p: Pane, longSecs: int): Pane =
    { st: if (and(p.st == "running", p.elapsed + 1 > longSecs)) { "long_running" } else { p.st },
      elapsed: p.elapsed + 1,
      runActive: p.runActive }

  pure def lookNext(p: Pane, longSecs: int): Pane =
    if (p.runActive)
      { { st: if (p.elapsed > longSecs) { "long_running" } else { "running" },
          elapsed: p.elapsed,
          runActive: true } }
    else { { st: "idle", elapsed: p.elapsed, runActive: false } }

  // ---- the laws as pure predicates over specimens ------------------------

  // L-ICON-1: red outranks all in the aggregate.
  pure def lIcon1(a: PaneState, b: PaneState): bool =
    implies(or(a == "needs_attention", b == "needs_attention"),
            agg2(a, b) == "needs_attention")

  // L-ICON-2: dim green outranks bright green in the aggregate.
  pure def lIcon2(a: PaneState, b: PaneState): bool =
    implies(and(a != "needs_attention", b != "needs_attention",
                or(a == "long_running", b == "long_running")),
            agg2(a, b) == "long_running")

  // L-ICON-3, three parts: occupancy, the crossing always promotes, and no
  // other event enters long_running.
  pure def lIcon3a(p: Pane, longSecs: int): bool =
    implies(p.st == "long_running", and(p.runActive, p.elapsed > longSecs))

  pure def lIcon3b(p: Pane, longSecs: int): bool =
    implies(and(p.st == "running", p.runActive, p.elapsed + 1 > longSecs),
            tickNext(p, longSecs).st == "long_running")

  pure def lIcon3c(p: Pane, attSecs: int, longSecs: int): bool =
    and(startNext(p).st != "long_running",
        finishNext(p, true, attSecs).st != "long_running",
        finishNext(p, false, attSecs).st != "long_running",
        bellNext(p).st != "long_running",
        implies(lookNext(p, longSecs).st == "long_running", p.elapsed > longSecs))

  // L-ICON-4: look clears attention, not the run state.
  pure def lIcon4(p: Pane, longSecs: int): bool =
    and(lookNext(p, longSecs).runActive == p.runActive,
        lookNext(p, longSecs).elapsed == p.elapsed,
        lookNext(p, longSecs).st != "needs_attention",
        implies(and(p.runActive, p.elapsed > longSecs),
                lookNext(p, longSecs).st == "long_running"),
        implies(and(p.runActive, p.elapsed <= longSecs),
                lookNext(p, longSecs).st == "running"),
        implies(not(p.runActive), lookNext(p, longSecs).st == "idle"))

  // ---- the killers (one mutation each; MUT selects) ----------------------
  // K1 rank-collapse: the aggregate ranks a running pane above red.
  pure def killerRank1(s: PaneState): int =
    if (s == "running") { 3 }
    else { if (s == "needs_attention") { 2 }
    else { if (s == "long_running") { 1 } else { 0 } } }

  pure def killerAgg1(a: PaneState, b: PaneState): PaneState =
    if (killerRank1(a) >= killerRank1(b)) { a } else { b }

  // K2 dim/bright collapse: the aggregate ranks a fresh run above long.
  pure def killerRank2(s: PaneState): int =
    if (s == "needs_attention") { 3 }
    else { if (s == "running") { 2 }
    else { if (s == "long_running") { 1 } else { 0 } } }

  pure def killerAgg2(a: PaneState, b: PaneState): PaneState =
    if (killerRank2(a) >= killerRank2(b)) { a } else { b }

  // K3 threshold-never-fires: the clock advances, promotion never happens.
  pure def killerTick3(p: Pane, longSecs: int): Pane =
    { st: p.st, elapsed: p.elapsed + 1, runActive: p.runActive }

  // K4 look-clears-run: look wipes the run state along with the attention.
  pure def killerLook4(p: Pane, longSecs: int): Pane =
    { st: "idle", elapsed: p.elapsed, runActive: false }

  // the composition the machine uses
  pure def aggUsed(a: PaneState, b: PaneState): PaneState =
    if (MUT == 1) { killerAgg1(a, b) }
    else { if (MUT == 2) { killerAgg2(a, b) } else { agg2(a, b) } }

  pure def tickUsed(p: Pane, longSecs: int): Pane =
    if (MUT == 3) { killerTick3(p, longSecs) } else { tickNext(p, longSecs) }

  pure def lookUsed(p: Pane, longSecs: int): Pane =
    if (MUT == 4) { killerLook4(p, longSecs) } else { lookNext(p, longSecs) }

  // ---- the machine: a two-pane tab (the multi-pane case) ------------------
  // p1/p2 are the pane trackers; q1/q2 snapshot the pre-step panes; tabAgg is
  // the DISPLAY value the tab shows, carried as its own variable and pinned
  // to the aggregate by invTabAgg - the wiring law.

  var p1: Pane
  var p2: Pane
  var q1: Pane
  var q2: Pane
  var attSecs: int
  var longSecs: int
  var tabAgg: PaneState
  var lastEvent: Event
  var lastPane: int

  action init =
    nondet a = THRESH.oneOf();
    nondet l = THRESH.oneOf();
    all {
    p1' = IDLE_PANE,
    p2' = IDLE_PANE,
    q1' = IDLE_PANE,
    q2' = IDLE_PANE,
    attSecs' = a,
    longSecs' = l,
    tabAgg' = "idle",
    lastEvent' = "start",
    lastPane' = 1
  }

  // deterministic inits for the behavioural runs: att=1/long=1 and
  // att=1/long=0 (actions take no parameters in this quint version)
  action initSpecR = all {
    p1' = IDLE_PANE,
    p2' = IDLE_PANE,
    q1' = IDLE_PANE,
    q2' = IDLE_PANE,
    attSecs' = 1,
    longSecs' = 1,
    tabAgg' = "idle",
    lastEvent' = "start",
    lastPane' = 1
  }

  action initSpecD = all {
    p1' = IDLE_PANE,
    p2' = IDLE_PANE,
    q1' = IDLE_PANE,
    q2' = IDLE_PANE,
    attSecs' = 1,
    longSecs' = 0,
    tabAgg' = "idle",
    lastEvent' = "start",
    lastPane' = 1
  }

  action evStart1 = all {
    or(p1.st == "idle", p1.st == "long_running"),
    not(p1.runActive),
    p1' = startNext(p1),
    p2' = p2,
    q1' = p1,
    q2' = p2,
    tabAgg' = aggUsed(startNext(p1).st, p2.st),
    attSecs' = attSecs,
    longSecs' = longSecs,
    lastEvent' = "start",
    lastPane' = 1
  }

  action evStart2 = all {
    or(p2.st == "idle", p2.st == "long_running"),
    not(p2.runActive),
    p1' = p1,
    p2' = startNext(p2),
    q1' = p1,
    q2' = p2,
    tabAgg' = aggUsed(p1.st, startNext(p2).st),
    attSecs' = attSecs,
    longSecs' = longSecs,
    lastEvent' = "start",
    lastPane' = 2
  }

  action evFinish1 =
    nondet focused1 = Set(true, false).oneOf();
    all {
    p1.runActive,
    p1' = finishNext(p1, focused1, attSecs),
    p2' = p2,
    q1' = p1,
    q2' = p2,
    tabAgg' = aggUsed(finishNext(p1, focused1, attSecs).st, p2.st),
    attSecs' = attSecs,
    longSecs' = longSecs,
    lastEvent' = "finish",
    lastPane' = 1
  }

  action evFinish2 =
    nondet focused2 = Set(true, false).oneOf();
    all {
    p2.runActive,
    p1' = p1,
    p2' = finishNext(p2, focused2, attSecs),
    q1' = p1,
    q2' = p2,
    tabAgg' = aggUsed(p1.st, finishNext(p2, focused2, attSecs).st),
    attSecs' = attSecs,
    longSecs' = longSecs,
    lastEvent' = "finish",
    lastPane' = 2
  }

  action evBell1 = all {
    p1.runActive,
    or(p1.st == "running", p1.st == "long_running"),
    p1' = bellNext(p1),
    p2' = p2,
    q1' = p1,
    q2' = p2,
    tabAgg' = aggUsed(bellNext(p1).st, p2.st),
    attSecs' = attSecs,
    longSecs' = longSecs,
    lastEvent' = "bell",
    lastPane' = 1
  }

  action evBell2 = all {
    p2.runActive,
    or(p2.st == "running", p2.st == "long_running"),
    p1' = p1,
    p2' = bellNext(p2),
    q1' = p1,
    q2' = p2,
    tabAgg' = aggUsed(p1.st, bellNext(p2).st),
    attSecs' = attSecs,
    longSecs' = longSecs,
    lastEvent' = "bell",
    lastPane' = 2
  }

  action evLook1 = all {
    p1.st == "needs_attention",
    p1' = lookUsed(p1, longSecs),
    p2' = p2,
    q1' = p1,
    q2' = p2,
    tabAgg' = aggUsed(lookUsed(p1, longSecs).st, p2.st),
    attSecs' = attSecs,
    longSecs' = longSecs,
    lastEvent' = "look",
    lastPane' = 1
  }

  action evLook2 = all {
    p2.st == "needs_attention",
    p1' = p1,
    p2' = lookUsed(p2, longSecs),
    q1' = p1,
    q2' = p2,
    tabAgg' = aggUsed(p1.st, lookUsed(p2, longSecs).st),
    attSecs' = attSecs,
    longSecs' = longSecs,
    lastEvent' = "look",
    lastPane' = 2
  }

  action evTick1 = all {
    p1.runActive,
    p1' = tickUsed(p1, longSecs),
    p2' = p2,
    q1' = p1,
    q2' = p2,
    tabAgg' = aggUsed(tickUsed(p1, longSecs).st, p2.st),
    attSecs' = attSecs,
    longSecs' = longSecs,
    lastEvent' = "tick",
    lastPane' = 1
  }

  action evTick2 = all {
    p2.runActive,
    p1' = p1,
    p2' = tickUsed(p2, longSecs),
    q1' = p1,
    q2' = p2,
    tabAgg' = aggUsed(p1.st, tickUsed(p2, longSecs).st),
    attSecs' = attSecs,
    longSecs' = longSecs,
    lastEvent' = "tick",
    lastPane' = 2
  }

  // check actions: the law as a guard over the reached state, riding a
  // stutter (assertions that read state cannot chain through .then in this
  // quint version; a guard conjunct fails the run the same way)
  action chkRedA = all {
    and(p1.st == "needs_attention", tabAgg == "needs_attention"),
    p1' = p1, p2' = p2, q1' = q1, q2' = q2, attSecs' = attSecs,
    longSecs' = longSecs, tabAgg' = tabAgg, lastEvent' = "tick", lastPane' = lastPane }

  action chkRedB = all {
    tabAgg == "needs_attention",
    p1' = p1, p2' = p2, q1' = q1, q2' = q2, attSecs' = attSecs,
    longSecs' = longSecs, tabAgg' = tabAgg, lastEvent' = "tick", lastPane' = lastPane }

  action chkDimA = all {
    and(p1.st == "long_running", p1.elapsed == 1),
    p1' = p1, p2' = p2, q1' = q1, q2' = q2, attSecs' = attSecs,
    longSecs' = longSecs, tabAgg' = tabAgg, lastEvent' = "tick", lastPane' = lastPane }

  action chkDimB = all {
    and(tabAgg == "long_running", p2.st == "running"),
    p1' = p1, p2' = p2, q1' = q1, q2' = q2, attSecs' = attSecs,
    longSecs' = longSecs, tabAgg' = tabAgg, lastEvent' = "tick", lastPane' = lastPane }

  action chkLookA = all {
    p1.st == "needs_attention",
    p1' = p1, p2' = p2, q1' = q1, q2' = q2, attSecs' = attSecs,
    longSecs' = longSecs, tabAgg' = tabAgg, lastEvent' = "tick", lastPane' = lastPane }

  action chkLookB = all {
    and(p1.st == "long_running", p1.runActive, tabAgg == "long_running"),
    p1' = p1, p2' = p2, q1' = q1, q2' = q2, attSecs' = attSecs,
    longSecs' = longSecs, tabAgg' = tabAgg, lastEvent' = "tick", lastPane' = lastPane }

  action step = any {
    evStart1, evStart2,
    evFinish1, evFinish2,
    evBell1, evBell2,
    evLook1, evLook2,
    evTick1, evTick2
  }

  // ---- the invariants (verified per module at the bottom of the file) ----

  // structural: the state fields and the run flag agree
  val invShape = and(
    implies(p1.runActive, or(p1.st == "running", p1.st == "long_running", p1.st == "needs_attention")),
    implies(not(p1.runActive), or(p1.st == "idle", p1.st == "needs_attention")),
    implies(p2.runActive, or(p2.st == "running", p2.st == "long_running", p2.st == "needs_attention")),
    implies(not(p2.runActive), or(p2.st == "idle", p2.st == "needs_attention")))

  // L-ICON-1: red outranks all in the tab display.
  val invL1 = implies(or(p1.st == "needs_attention", p2.st == "needs_attention"),
                      tabAgg == "needs_attention")

  // L-ICON-2: dim green outranks bright green in the tab display.
  val invL2 = implies(and(p1.st != "needs_attention", p2.st != "needs_attention",
                          or(p1.st == "long_running", p2.st == "long_running")),
                      tabAgg == "long_running")

  // the wiring law: the display value IS the aggregation of the panes.
  val invTabAgg = tabAgg == agg2(p1.st, p2.st)

  // L-ICON-3a: occupancy - long_running only past the threshold.
  val invL3a = and(
    implies(p1.st == "long_running", and(p1.runActive, p1.elapsed > longSecs)),
    implies(p2.st == "long_running", and(p2.runActive, p2.elapsed > longSecs)))

  // L-ICON-3b: a run past the threshold shows dim green unless red masks it.
  val invL3b = and(
    implies(and(p1.runActive, p1.elapsed > longSecs),
            or(p1.st == "long_running", p1.st == "needs_attention")),
    implies(and(p2.runActive, p2.elapsed > longSecs),
            or(p2.st == "long_running", p2.st == "needs_attention")))

  // L-ICON-4: look clears attention, not the run state.
  val invL4 = implies(lastEvent == "look", and(
    q1.st == "needs_attention" or q2.st == "needs_attention",
    implies(lastPane == 1, and(
      p1.runActive == q1.runActive,
      p1.elapsed == q1.elapsed,
      p1.st != "needs_attention",
      implies(q1.runActive,
              p1.st == if (q1.elapsed > longSecs) { "long_running" } else { "running" }),
      implies(not(q1.runActive), p1.st == "idle"),
      p2 == q2)),
    implies(lastPane == 2, and(
      p2.runActive == q2.runActive,
      p2.elapsed == q2.elapsed,
      p2.st != "needs_attention",
      implies(q2.runActive,
              p2.st == if (q2.elapsed > longSecs) { "long_running" } else { "running" }),
      implies(not(q2.runActive), p2.st == "idle"),
      p1 == q1))))

  // ---- the runs -----------------------------------------------------------
  // green lane: the laws over specimens and over machine behaviour; red lane:
  // the same laws against a killer over the identical specimens.

  pure def SP_RUNNING: Pane = { st: "running", elapsed: 2, runActive: true }
  pure def SP_LONG: Pane = { st: "long_running", elapsed: 2, runActive: true }
  pure def SP_BELL_ATT: Pane = { st: "needs_attention", elapsed: 2, runActive: true }
  pure def SP_FIN_ATT: Pane = { st: "needs_attention", elapsed: 0, runActive: false }
  pure def SP_FRESH: Pane = { st: "running", elapsed: 0, runActive: true }

  run wIcon1 = {
    assert(and(lIcon1("running", "needs_attention"),
               lIcon1("needs_attention", "long_running"),
               lIcon1("long_running", "needs_attention"),
               agg2(agg2("needs_attention", "running"), "idle") == "needs_attention"))
  }

  run wIcon2 = {
    assert(and(lIcon2("running", "long_running"),
               lIcon2("long_running", "running"),
               agg2(agg2("long_running", "running"), "idle") == "long_running"))
  }

  run wIcon3 = {
    assert(and(lIcon3a(SP_LONG, 1),
               lIcon3b(SP_RUNNING, 1),
               lIcon3b(SP_FRESH, 0),
               tickNext(SP_RUNNING, 3).st == "running",
               lIcon3c(SP_RUNNING, 1, 1),
               lIcon3c(SP_BELL_ATT, 1, 1),
               lIcon3c(SP_FIN_ATT, 1, 1),
               lIcon3c(SP_FRESH, 1, 1),
               tickNext(SP_FRESH, 2).st == "running",
               tickNext(SP_RUNNING, 1).st == "long_running"))
  }

  run wIcon4 = {
    assert(and(lIcon4(SP_BELL_ATT, 1),
               lIcon4(SP_FIN_ATT, 1),
               lIcon4(SP_FRESH, 1),
               lookNext(SP_BELL_ATT, 1).st == "long_running",
               lookNext({ st: "needs_attention", elapsed: 0, runActive: true }, 1).st == "running",
               lookNext(SP_FIN_ATT, 1).st == "idle"))
  }

  // behavioural: the multi-pane tab through real event sequences
  run wTabRed = {
    initSpecR
      .then(evStart1)
      .then(evBell1)
      .then(chkRedA)
      .then(evStart2)
      .then(chkRedB)
  }

  run wTabDim = {
    initSpecD
      .then(evStart1)
      .then(evTick1)
      .then(chkDimA)
      .then(evStart2)
      .then(chkDimB)
  }

  run wTabLook = {
    initSpecD
      .then(evStart1)
      .then(evTick1)
      .then(evBell1)
      .then(chkLookA)
      .then(evLook1)
      .then(chkLookB)
  }

  // red lane: each killer fails its law on the identical specimen
  run wnegIcon1 = {
    assert(killerAgg1("running", "needs_attention") == "needs_attention")
  }

  run wnegIcon2 = {
    assert(killerAgg2("running", "long_running") == "long_running")
  }

  run wnegIcon3 = {
    assert(killerTick3(SP_RUNNING, 1).st == "long_running")
  }

  run wnegIcon4 = {
    assert(and(killerLook4(SP_BELL_ATT, 1).runActive == SP_BELL_ATT.runActive,
               killerLook4(SP_BELL_ATT, 1).st == "long_running"))
  }

}

// ---- verify wrappers: one law per module, clean and killer polarities ----
// clean: MUT = 0, every law [ok]; killers: the named mutation, the law it
// must break [violation].

module vIconL1c {
  import njuggleIconMachine(MUT = 0).* from "./icon-machine"
  val invSolo = invL1
}

module vIconL1k {
  import njuggleIconMachine(MUT = 1).* from "./icon-machine"
  val invSolo = invL1
}

module vIconL2c {
  import njuggleIconMachine(MUT = 0).* from "./icon-machine"
  val invSolo = invL2
}

module vIconL2k {
  import njuggleIconMachine(MUT = 2).* from "./icon-machine"
  val invSolo = invL2
}

module vIconTabAggc {
  import njuggleIconMachine(MUT = 0).* from "./icon-machine"
  val invSolo = invTabAgg
}

module vIconTabAggk {
  import njuggleIconMachine(MUT = 1).* from "./icon-machine"
  val invSolo = invTabAgg
}

module vIconL3ac {
  import njuggleIconMachine(MUT = 0).* from "./icon-machine"
  val invSolo = and(invL3a, invShape)
}

module vIconL3bc {
  import njuggleIconMachine(MUT = 0).* from "./icon-machine"
  val invSolo = invL3b
}

module vIconL3bk {
  import njuggleIconMachine(MUT = 3).* from "./icon-machine"
  val invSolo = invL3b
}

module vIconL4c {
  import njuggleIconMachine(MUT = 0).* from "./icon-machine"
  val invSolo = invL4
}

module vIconL4k {
  import njuggleIconMachine(MUT = 4).* from "./icon-machine"
  val invSolo = invL4
}

// the importable face: the clean law, for consumers
module njuggleIcon {
  import njuggleIconMachine(MUT = 0).* from "./icon-machine"
}
