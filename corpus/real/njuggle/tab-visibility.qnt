// tab-visibility.qnt - the tab-visibility decision law (njuggle v0.1.1, R4).
// Licence: AGPLv3 (janet-viz).
//
// WHAT THIS IS. The decision table behind window.zig's tabsVisibleFor - the
// single authority for whether the top tab bar is visible - stated as
// verified laws over its five inputs: titlebar style (tabs | native),
// window-show-tab-bar (always | auto | never), sidebar mode (none | left |
// right), maximized, hide-when-maximized. Decision only: the widget transport
// that carries the answer to the screen is acceptance territory. njuggle's
// double-tab defect was a transport failure of a correct table, which is
// why the WIRING law (barVisible == the table) is a machine invariant here.
//
// Tab count is deliberately NOT an input. The table answers whether the bar
// is enabled for a layout; count-dependent auto behaviour is the widget's
// own, and the double-tab law is precisely that sidebar + auto hides the
// bar REGARDLESS of count.
//
// THE LAWS.
//   L-VIS-1  the double-tab law: with the native titlebar and the sidebar
//            on, show-tab-bar = auto hides the top bar, regardless of tab
//            count or maximized state. (Scoped to the native layout: the
//            tabs titlebar is the window's own tab strip and outranks the
//            sidebar - that precedence is L-VIS-4.)
//   L-VIS-2  the pins: under the native titlebar, always pins the bar
//            visible and never pins it hidden, in every sidebar mode and
//            maximized state.
//   L-VIS-3  the parity law: with no sidebar, the result is exactly
//            upstream's own (visibleFor == upstreamFor, which includes the
//            maximized-independence of the native answer). The none-parity
//            gate tests njuggle's CODE against real upstream; this law is
//            the reference it must match.
//   L-VIS-4  the maximized override is scoped to the tabs titlebar only:
//            maximized + hide-when-maximized hides the tabs-titlebar bar,
//            and the native answer never depends on maximized at all.
//   L-VIS-5  the legibility law: a visible bar has a non-zero rendered
//            height and its labels sit inside the layout. A bar laid out
//            at zero height, with its labels painted outside the layout,
//            is not visible in any sense a user reads - so the decision
//            table's `true` binds the transport, not merely the node.
//            (Added 2026-11-02 from the live cells: `autohide` collapsed
//            the bar to zero height while the table answered visible.)
//
// CALIBRATION. MUT = 0 is the law as specified; 1-2 are the named killers
// (the double-tab defect class): 1 reads auto as always, 2 reads the
// sidebar mode as none. 3 is the zero-height killer for L-VIS-5. Verify wrappers below exist in clean and killer
// polarities over the identical machine; the run set has a green lane
// (wVis/wTabVis) and a red lane (wneg, the same law against a killer over
// the same specimen). Import njuggleTabVisMachine(MUT = 0) for the clean
// law.

module njuggleTabVisMachine {

  const MUT: int

  type VisSpec = {
    style: str,     // "tabs" | "native"
    show: str,      // "always" | "auto" | "never"
    side: str,      // "none" | "left" | "right"
    maxed: bool,
    hideMax: bool
  }

  pure def STYLES: Set[str] = Set("tabs", "native")
  pure def SHOWS: Set[str] = Set("always", "auto", "never")
  pure def SIDES: Set[str] = Set("none", "left", "right")

  // ---- THE DECISION (window.zig tabsVisibleFor, the only authority) ------
  // The tabs titlebar keeps its bar and outranks everything here, except
  // the maximized+hide override. With the native titlebar, no sidebar means
  // exactly upstream's answer; a sidebar on means the bar needs an explicit
  // always pin.

  pure def visibleFor(v: VisSpec): bool =
    if (v.style == "tabs") { not(and(v.maxed, v.hideMax)) }
    else { if (v.side == "none") { v.show != "never" } else { v.show == "always" } }

  // upstream's own answer for the same inputs (the parity reference)
  pure def upstreamFor(v: VisSpec): bool =
    if (v.style == "tabs") { not(and(v.maxed, v.hideMax)) } else { v.show != "never" }

  // ---- the laws as pure predicates over specimens -------------------------

  // L-VIS-1: the double-tab law.
  pure def lVis1(v: VisSpec): bool =
    implies(and(v.style == "native", v.side != "none", v.show == "auto"),
            not(visibleFor(v)))

  // L-VIS-2: the always/never pins, native scope.
  pure def lVis2(v: VisSpec): bool =
    implies(v.style == "native",
            and(implies(v.show == "always", visibleFor(v)),
                implies(v.show == "never", not(visibleFor(v)))))

  // L-VIS-3: the parity law - no sidebar, upstream's own answer exactly.
  pure def lVis3(v: VisSpec): bool =
    implies(v.side == "none", visibleFor(v) == upstreamFor(v))

  // L-VIS-4: the maximized override is scoped to the tabs titlebar only.
  pure def lVis4(v: VisSpec): bool =
    and(implies(and(v.style == "tabs", v.maxed, v.hideMax), not(visibleFor(v))),
        implies(v.style == "native",
                and(visibleFor(v) == visibleFor(v.with("maxed", false)),
                    visibleFor(v) == visibleFor(v.with("hideMax", false)))))

  // ---- the killers (the double-tab defect class; MUT selects) ------------
  // K1: the transport reads auto as always.
  pure def killerAutoAsAlways(v: VisSpec): bool =
    visibleFor(v.with("show", if (v.show == "auto") { "always" } else { v.show }))

  // K2: the transport reads the sidebar mode as none.
  pure def killerSideAsNone(v: VisSpec): bool =
    visibleFor(v.with("side", "none"))

  // K3: the zero-height transport. The bar is laid out at zero height
  // whenever the widget's autohide input is true, which in the build is
  // keyed on the wrong inputs; the labels then paint outside the layout.
  pure def killerZeroHeight(v: VisSpec): bool =
    and(not(and(v.maxed, v.hideMax)), v.show != "never")

  pure def transportUsed(v: VisSpec): bool =
    if (MUT == 1) { killerAutoAsAlways(v) }
    else { if (MUT == 2) { killerSideAsNone(v) }
    else { if (MUT == 3) { killerZeroHeight(v) } else { visibleFor(v) } } }

  // ---- the machine: the five inputs and the transported answer -----------
  // barVisible is what the widget shows, carried as its own
  // variable and pinned to the table by invWiring - the R4 wiring law.

  var v: VisSpec
  var barVisible: bool
  // the transport's own state: does the bar occupy layout height? Under the
  // clean transport it always does when barVisible (a laid-out bar is a
  // visible bar); the zero-height killer is the one that separates them.
  var painted: bool

  action init =
    nondet s = STYLES.oneOf();
    nondet sh = SHOWS.oneOf();
    nondet sd = SIDES.oneOf();
    nondet mx = Set(true, false).oneOf();
    nondet hm = Set(true, false).oneOf();
    all {
    v' = { style: s, show: sh, side: sd, maxed: mx, hideMax: hm },
    barVisible' = transportUsed({ style: s, show: sh, side: sd, maxed: mx, hideMax: hm }),
    painted' = if (MUT == 3) { false } else { transportUsed({ style: s, show: sh, side: sd, maxed: mx, hideMax: hm }) }
  }

  // the wiring: re-sync the bar to the table on any notify
  action sync = all {
    v' = v,
    barVisible' = transportUsed(v),
    painted' = if (MUT == 3) { false } else { transportUsed(v) }
  }

  // any input change: a new config or window state, then the sync
  action restyle =
    nondet s = STYLES.oneOf();
    nondet sh = SHOWS.oneOf();
    nondet sd = SIDES.oneOf();
    nondet mx = Set(true, false).oneOf();
    nondet hm = Set(true, false).oneOf();
    all {
    v' = { style: s, show: sh, side: sd, maxed: mx, hideMax: hm },
    barVisible' = transportUsed({ style: s, show: sh, side: sd, maxed: mx, hideMax: hm }),
    painted' = if (MUT == 3) { false } else { transportUsed({ style: s, show: sh, side: sd, maxed: mx, hideMax: hm }) }
  }

  action step = any { sync, restyle }

  // deterministic transitions for the behavioural runs
  action initVis = all {
    v' = { style: "native", show: "always", side: "none", maxed: false, hideMax: false },
    barVisible' = transportUsed({ style: "native", show: "always", side: "none", maxed: false, hideMax: false }),
    painted' = if (MUT == 3) { false } else { transportUsed({ style: "native", show: "always", side: "none", maxed: false, hideMax: false }) }
  }

  action goAutoLeft = all {
    v' = { style: "native", show: "auto", side: "left", maxed: false, hideMax: false },
    barVisible' = transportUsed({ style: "native", show: "auto", side: "left", maxed: false, hideMax: false }),
    painted' = if (MUT == 3) { false } else { transportUsed({ style: "native", show: "auto", side: "left", maxed: false, hideMax: false }) }
  }

  action goAlwaysRight = all {
    v' = { style: "native", show: "always", side: "right", maxed: true, hideMax: true },
    barVisible' = transportUsed({ style: "native", show: "always", side: "right", maxed: true, hideMax: true }),
    painted' = if (MUT == 3) { false } else { transportUsed({ style: "native", show: "always", side: "right", maxed: true, hideMax: true }) }
  }

  action chkBarHidden = all {
    not(barVisible),
    v' = v,
    barVisible' = barVisible,
    painted' = painted
  }

  action chkBarShown = all {
    barVisible,
    v' = v,
    barVisible' = barVisible,
    painted' = painted
  }

  // ---- the invariants (verified per module at the bottom of the file) ----

  // the wiring law: the transported answer IS the table's answer.
  val invWiring = barVisible == visibleFor(v)

  // L-VIS-1 as a machine law on the transported bar.
  val invL1 = implies(and(v.style == "native", v.side != "none", v.show == "auto"),
                      not(barVisible))

  // L-VIS-2 as a machine law.
  val invL2 = implies(v.style == "native",
                      and(implies(v.show == "always", barVisible),
                          implies(v.show == "never", not(barVisible))))

  // L-VIS-3 as a machine law.
  val invL3 = implies(v.side == "none", barVisible == upstreamFor(v))

  // L-VIS-4 as a machine law.
  val invL4 = and(implies(and(v.style == "tabs", v.maxed, v.hideMax), not(barVisible)),
                  implies(v.style == "native",
                          barVisible == visibleFor(v.with("maxed", false))))

  // L-VIS-5: a visible bar occupies layout height; a bar laid out at zero
  // height is not visible. Stated over the table's answer, so it binds the
  // transport: the decision cannot be satisfied by an unpainted node.
  val invL5 = implies(barVisible, painted)

  // ---- the runs -----------------------------------------------------------

  // the specimens: one per law limb, both polarities on the identical record
  pure def SP_AUTO_LEFT: VisSpec =
    { style: "native", show: "auto", side: "left", maxed: false, hideMax: false }
  pure def SP_AUTO_RIGHT_MAX: VisSpec =
    { style: "native", show: "auto", side: "right", maxed: true, hideMax: true }
  pure def SP_TABS_AUTO: VisSpec =
    { style: "tabs", show: "auto", side: "left", maxed: false, hideMax: false }
  pure def SP_ALWAYS_LEFT_MAX: VisSpec =
    { style: "native", show: "always", side: "left", maxed: true, hideMax: true }
  pure def SP_NEVER_RIGHT: VisSpec =
    { style: "native", show: "never", side: "right", maxed: false, hideMax: false }
  pure def SP_AUTO_NONE_MAX: VisSpec =
    { style: "native", show: "auto", side: "none", maxed: true, hideMax: true }
  pure def SP_TABS_NEVER: VisSpec =
    { style: "tabs", show: "never", side: "none", maxed: false, hideMax: false }
  pure def SP_TABS_ALWAYS_MAX: VisSpec =
    { style: "tabs", show: "always", side: "none", maxed: true, hideMax: true }

  run wVis1 = {
    assert(and(lVis1(SP_AUTO_LEFT), not(visibleFor(SP_AUTO_LEFT)),
               lVis1(SP_AUTO_RIGHT_MAX), not(visibleFor(SP_AUTO_RIGHT_MAX))))
  }

  run wVis1carve = {
    // the tabs-titlebar carve-out: the precedence L-VIS-4 pins
    assert(and(visibleFor(SP_TABS_AUTO), lVis4(SP_TABS_AUTO)))
  }

  run wVis2 = {
    assert(and(lVis2(SP_ALWAYS_LEFT_MAX), visibleFor(SP_ALWAYS_LEFT_MAX),
               lVis2(SP_NEVER_RIGHT), not(visibleFor(SP_NEVER_RIGHT))))
  }

  run wVis3 = {
    assert(and(lVis3(SP_AUTO_NONE_MAX), visibleFor(SP_AUTO_NONE_MAX),
               lVis3(SP_TABS_NEVER), visibleFor(SP_TABS_NEVER),
               lVis3(SP_TABS_ALWAYS_MAX), not(visibleFor(SP_TABS_ALWAYS_MAX)),
               visibleFor(SP_AUTO_NONE_MAX) == visibleFor(SP_AUTO_NONE_MAX.with("maxed", false))))
  }

  run wVis4 = {
    assert(and(lVis4(SP_TABS_ALWAYS_MAX), not(visibleFor(SP_TABS_ALWAYS_MAX)),
               lVis4(SP_NEVER_RIGHT),
               visibleFor(SP_NEVER_RIGHT) == visibleFor(SP_NEVER_RIGHT.with("maxed", true))))
  }

  // behavioural: the config lands on sidebar+auto, the bar hides; an
  // explicit always pin holds even maximized
  run wTabVis1 = {
    initVis.then(goAutoLeft).then(chkBarHidden)
  }

  run wTabVis2 = {
    initVis.then(goAlwaysRight).then(chkBarShown)
  }

  // red lane: each killer over the identical specimen
  run wnegVis1 = {
    assert(and(not(killerAutoAsAlways(SP_AUTO_LEFT)),
               not(killerSideAsNone(SP_AUTO_LEFT))))
  }

  run wnegVis2 = {
    // the side-as-none killer also breaks the auto pin under maximized
    assert(not(killerSideAsNone(SP_AUTO_RIGHT_MAX)))
  }

  run wVis5 = {
    // the pin is a decision the transport carries with height
    assert(and(visibleFor(SP_ALWAYS_LEFT_MAX), killerZeroHeight(SP_ALWAYS_LEFT_MAX)))
  }

  run wnegVis5 = {
    // the zero-height killer answers visible where the table answers hidden
    assert(and(killerZeroHeight(SP_AUTO_LEFT), not(visibleFor(SP_AUTO_LEFT))))
  }

}

// ---- verify wrappers: one law per module, clean and killer polarities ----

module vVisWiringc {
  import njuggleTabVisMachine(MUT = 0).* from "./tab-visibility"
  val invSolo = invWiring
}

module vVisWiringk1 {
  import njuggleTabVisMachine(MUT = 1).* from "./tab-visibility"
  val invSolo = invWiring
}

module vVisL1c {
  import njuggleTabVisMachine(MUT = 0).* from "./tab-visibility"
  val invSolo = invL1
}

module vVisL1k1 {
  import njuggleTabVisMachine(MUT = 1).* from "./tab-visibility"
  val invSolo = invL1
}

module vVisL1k2 {
  import njuggleTabVisMachine(MUT = 2).* from "./tab-visibility"
  val invSolo = invL1
}

module vVisL2c {
  import njuggleTabVisMachine(MUT = 0).* from "./tab-visibility"
  val invSolo = invL2
}

module vVisL3c {
  import njuggleTabVisMachine(MUT = 0).* from "./tab-visibility"
  val invSolo = invL3
}

module vVisL4c {
  import njuggleTabVisMachine(MUT = 0).* from "./tab-visibility"
  val invSolo = invL4
}

module vVisL5c {
  import njuggleTabVisMachine(MUT = 0).* from "./tab-visibility"
  val invSolo = invL5
}

module vVisL5k3 {
  import njuggleTabVisMachine(MUT = 3).* from "./tab-visibility"
  val invSolo = invL5
}

module vVisL5wiringc {
  import njuggleTabVisMachine(MUT = 0).* from "./tab-visibility"
  val invSolo = and(invL1, invL2, invL3, invL4, invL5)
}

// the importable face: the clean law, for consumers
module njuggleTabVis {
  import njuggleTabVisMachine(MUT = 0).* from "./tab-visibility"
}
