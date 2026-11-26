// surface-trace.qnt - the shipped surface the witnesses' SPECIMENS are
// projections of. Licence: AGPLv3 (janet-viz).
//
// THE AGREEMENT GATE. The gate (scripts/surface-check.sh) diffs the CODE
// against a hand transcription of the law by a separate script;
// `quint` is not in that loop at all. So the model can be WRONG and every
// instrument is green: measured, the edit "the scatter family set loses
// error" (m-outside) leaves the gate at `RESULT: pass (3072 rows)`, the
// witnesses at 20/20 and `surfaceInv` at `[ok]`, while the code still
// RESOLVES `scatter + :error`.
//
// Why the model's own instruments cannot see it: `familyChannels` is the
// definition the limbs read AND the definition the witnesses build their
// specimens from, so an edit to the set moves every expected answer with it.
// The fix is an expected answer WRITTEN DOWN, not derived:
//
//   - EXPECTEDO / EXPECTEDA are projections of the shipped pool, stated here
//     as literal rows. They are NOT imported from the module under test: a
//     projection that calls the thing it checks is the same mirror one level
//     up. The answer column is the CODE's (tested rows are leg-asserted
//     against the CODE by the fourth gate leg's sibling check in
//     s9-surface-trace), never derived from a limb.
//   - EXPECTEDSETS pins the family sets themselves (S-02), the bar's interval
//     channel (S-04) and the :decimate slot (S-06): the definitions a limb
//     reads, which no limb edit can witness.
//   - The shipped side (shippedOutcome, shippedStat, shippedStrategy, ...) is
//     a KEEP-IN-STEP COPY of surface.qnt's pure defs;
//     tests/cells/s9-surface-trace.janet diffs it against the real limbs.
//
// The fourth leg (scripts/surface-trace-leg.janet) runs
// `quint test quint/surface-trace.qnt --main=vizSurfaceTrace --match=w[a-zA-Z]`
// on the model AS SHIPPED and fails on any row whose shipped answer differs
// from the written one. The m-outside edit therefore reddens the gate; the
// shipped tree is green.
//
// Evaluator and typechecker facts this file is written around (Quint 0.33.1;
// each reproduced in a minimal probe): (1) a NESTED ternaries chain
// evaluates wrongly - every dispatch here is a flat else-if chain; (2) a field
// named `over` shadows the builtin quantifier `over` and the definition is
// read as recursive - the field is `isOver`; (3) a record row written on one
// line past ~120 columns mis-parses as a row expression - rows are wrapped;
// (4) the answers above and below a row list must not be added by splicing
// the file mid-statement.

module vizSurfaceTrace {

  // the model's own input record (same fields as surface.qnt's SSpec, with
  // `over` renamed `isOver` - see the copy note below)
  type SSpec = {
    family: str,
    chans: Set[str],
    isOver: bool,
    decimate: bool,
    refusedKeys: Set[str],
  }

  type VizOutcome = (SSpec, str)

  type VizAnswer = {
    family: str,
    chans: Set[str],
    isOver: bool,
    decimate: bool,
    refusedKeys: Set[str],
    stat: str,
    strat: str,
  }

  // ---- the written-down expectations ------------------------------------
  //
  // EXPECTEDO: the outcome column, one row per shipped start row plus the two
  // scatter + :error rows the trace adds (the shipped pool does not carry the
  // under-budget one, which is exactly the row the m-outside edit moves).

  pure val EXPECTEDO: List[VizOutcome] = List(
    ( { family: "scatter", chans: Set("x", "y"), isOver: false,
        decimate: false, refusedKeys: Set() }, "resolved" ),
    ( { family: "scatter", chans: Set("x", "y"), isOver: true,
        decimate: true, refusedKeys: Set() }, "resolved" ),
    ( { family: "scatter", chans: Set("x", "y"), isOver: true,
        decimate: false, refusedKeys: Set() }, "resolved" ),
    ( { family: "line", chans: Set("x", "y"), isOver: true,
        decimate: false, refusedKeys: Set() }, "resolved" ),
    ( { family: "line", chans: Set("x", "y", "error"), isOver: false,
        decimate: false, refusedKeys: Set() }, "channel-family-mismatch" ),
    ( { family: "bar", chans: Set("x", "y", "error"), isOver: false,
        decimate: false, refusedKeys: Set() }, "channel-family-mismatch" ),
    ( { family: "bar", chans: Set("x", "error"), isOver: false,
        decimate: false, refusedKeys: Set() }, "channel-family-mismatch" ),
    ( { family: "bar", chans: Set("x", "y"), isOver: true,
        decimate: false, refusedKeys: Set() }, "unsupported-chart" ),
    ( { family: "bar", chans: Set("x", "y", "size"), isOver: false,
        decimate: false, refusedKeys: Set() }, "channel-family-mismatch" ),
    ( { family: "histogram", chans: Set("x"), isOver: false,
        decimate: false, refusedKeys: Set() }, "resolved" ),
    ( { family: "histogram", chans: Set("x", "colour"), isOver: false,
        decimate: false, refusedKeys: Set() }, "channel-family-mismatch" ),
    ( { family: "histogram", chans: Set("x", "size"), isOver: false,
        decimate: false, refusedKeys: Set() }, "channel-family-mismatch" ),
    ( { family: "histogram", chans: Set(), isOver: false,
        decimate: false, refusedKeys: Set() }, "channel-family-mismatch" ),
    ( { family: "scatter", chans: Set("y"), isOver: false,
        decimate: false, refusedKeys: Set() }, "channel-family-mismatch" ),
    ( { family: "scatter", chans: Set("x", "y", "colour"), isOver: true,
        decimate: true, refusedKeys: Set() }, "colour-under-reduction" ),
    ( { family: "scatter", chans: Set("x", "y"), isOver: false,
        decimate: false, refusedKeys: Set("sort") }, "unsupported-option" ),
    ( { family: "scatter", chans: Set("x", "y"), isOver: false,
        decimate: false, refusedKeys: Set("order") }, "unsupported-option" ),
    ( { family: "scatter", chans: Set("x", "y", "size"), isOver: false,
        decimate: false, refusedKeys: Set("sort", "order") }, "unsupported-option" ),
    // scatter + :error under budget RESOLVES on the code.
    ( { family: "scatter", chans: Set("x", "y", "error"), isOver: false,
        decimate: false, refusedKeys: Set() }, "resolved" ),
    // the same, over budget: :error alone is not a colour reduction ground.
    ( { family: "scatter", chans: Set("x", "y", "error"), isOver: true,
        decimate: false, refusedKeys: Set() }, "resolved" ),
  )

  // EXPECTEDA: the stat and strategy columns, one entry per resolve row, in
  // the SAME ORDER as RESOLVED_SPEC below (family, channel set, isOver and
  // decimate are read from that row). Two aligned literal lists, indexed by
  // the row's own position: this evaluator computes `F[ROW[k]]` (a nested
  // index into a literal list) wrongly - reproduced by a minimal probe -
  // while `F[k]` is exact.

  pure val EXPECTED_STAT: List[str] = List(
    "identity", "identity", "identity", "identity", "bin", "identity",
    "count", "identity",
  )

  pure val EXPECTED_STRAT: List[str] = List(
    "none", "decimate", "density-bin", "m4-envelope", "none", "none",
    "none", "none",
  )

  // Resolved rows in list order: 0,1,2,3 (scatter x3, line), 9 (histogram),
  // 5 (bar x/y), 6 (bar x), 18 (scatter + :error). The stat/strategy columns
  // of a row are read by its position in this list, and the row's channel set,
  // over flag and decimate key come from EXPECTEDO at the SAME position.

  pure val RESOLVED_SPEC: List[SSpec] = List(
    { family: "scatter", chans: Set("x", "y"), isOver: false,
      decimate: false, refusedKeys: Set() },
    { family: "scatter", chans: Set("x", "y"), isOver: true,
      decimate: true, refusedKeys: Set() },
    { family: "scatter", chans: Set("x", "y"), isOver: true,
      decimate: false, refusedKeys: Set() },
    { family: "line", chans: Set("x", "y"), isOver: true,
      decimate: false, refusedKeys: Set() },
    { family: "histogram", chans: Set("x"), isOver: false,
      decimate: false, refusedKeys: Set() },
    { family: "bar", chans: Set("x", "y"), isOver: false,
      decimate: false, refusedKeys: Set() },
    { family: "bar", chans: Set("x"), isOver: false,
      decimate: false, refusedKeys: Set() },
    { family: "scatter", chans: Set("x", "y", "error"), isOver: false,
      decimate: false, refusedKeys: Set() },
  )

  // ---- the family sets and slots, written down (S-02, S-04, S-06) -------

  pure val FAMILIES: List[str] = List("scatter", "line", "histogram", "bar")

  pure val CHANNELS: List[str] = List("x", "y", "colour", "size", "error")

  pure val EXPECTEDSETS: List[Set[str]] = List(
    Set("x", "y", "colour", "size", "error"),
    Set("x", "y", "colour"),
    Set("x"),
    Set("x", "y", "error"),
  )

  // ---- the shipped side: a copy of the model's own definitions ----------

  pure def shippedChannels(f: str): Set[str] =
      if (f == "scatter") Set("x", "y", "colour", "size", "error")
      else if (f == "line") Set("x", "y", "colour")
      else if (f == "histogram") Set("x")
      else Set("x", "y", "error")      // bar (S-02); :error is REFUSED at
                                       // resolve for both stats (S-04)

  pure def shippedFamIs(s: SSpec): bool = (s.family == "scatter") or (s.family == "line")
      or (s.family == "histogram") or (s.family == "bar")

  pure def shippedOutsideFamily(s: SSpec): Set[str] =
      s.chans.exclude(shippedChannels(s.family))

  pure def shippedMissingX(s: SSpec): bool = not(s.chans.contains("x"))

  pure def shippedBarError(s: SSpec): bool =
      s.family == "bar" and s.chans.contains("error")

  pure def shippedRefusedKey(s: SSpec): bool = s.refusedKeys.size() > 0

  pure def shippedRefused(s: SSpec): bool =
      shippedRefusedKey(s) or not(shippedFamIs(s)) or shippedOutsideFamily(s).size() > 0
        or shippedMissingX(s) or shippedBarError(s)

  pure def shippedGround(s: SSpec): str =
      if (shippedRefusedKey(s)) "unsupported-option"
      else if (not(shippedFamIs(s))) "unsupported-chart"
      else if (shippedOutsideFamily(s).size() > 0) "channel-family-mismatch"
      else if (shippedMissingX(s)) "channel-family-mismatch"
      else if (shippedBarError(s)) "channel-family-mismatch"
      else "resolved"

  pure def shippedDecimateLegal(s: SSpec): bool = (not(s.decimate)) or s.family == "scatter"

  pure def shippedStatOf(s: SSpec): str =
      if (s.family == "bar")
        if (s.chans.contains("y")) "identity" else "count"
      else if (s.family == "histogram") "bin"
      else "identity"

  pure def shippedStrategyOf(s: SSpec): str =
      if (s.isOver)
        if (s.family == "line") "m4-envelope"
        else if (s.family == "scatter")
          if (s.decimate) "decimate" else "density-bin"
        else "unsupported"
      else "none"

  pure def shippedReductionRefused(s: SSpec): bool =
      shippedStrategyOf(s) == "unsupported"

  pure def shippedColourRefused(s: SSpec): bool =
      s.chans.contains("colour") and not(s.isOver) == false
        and shippedStrategyOf(s) != "none"

  pure def shippedOutcome(s: SSpec): str =
      if (shippedRefused(s)) shippedGround(s)
      else if (shippedReductionRefused(s)) "unsupported-chart"
      else if (shippedColourRefused(s)) "colour-under-reduction"
      else "resolved"


  // ---- one written specimen per limb ------------------------------------
  //
  // Every limb in surface.qnt is a claim. Ten of ten survived being replaced
  // by `true` (scripts/surface-limb-sweep.janet, the limb-sweep instrument):
  // the witnesses draw from the same pool the limbs read, so deleting a
  // limb's body left every run green. The fix is a SPECIMEN PER LIMB with its
  // answer WRITTEN DOWN - one def per limb, and the limb itself re-stated over
  // the shipped copies.
  //
  // Each `wlimbX` run below therefore asserts THREE written facts about its
  // specimen: the code's outcome, the stat/strategy columns, and that the
  // limb's own claim holds on it. Deleting the limb cannot move any of them -
  // the answers are literals here, not reads of the def under test - which is
  // what makes the sweep possible (scripts/surface-limb-sweep.janet reddens
  // the matching run for every limb).
  //
  // One def per specimen, no index chains: a per-limb `if` chain and a record
  // read for several fields after a helper call were both answered wrongly by
  // this build (each reproduced in a minimal probe).

  // lDom: a line carrying :decimate is OUTSIDE the model's domain
  // (decimateLegal refuses it) and the code refuses the key on a line.
  pure def specDom: SSpec =
    { family: "line", chans: Set("x", "y"), isOver: false,
      decimate: true, refusedKeys: Set() }

  pure def lDomHolds: bool = not(shippedDecimateLegal(specDom))

  // lOutside: a bar carrying :size - outside the bar's set.
  pure def specOutside: SSpec =
    { family: "bar", chans: Set("x", "y", "size"), isOver: false,
      decimate: false, refusedKeys: Set() }

  pure def lOutsideHolds: bool =
    shippedOutsideFamily(specOutside).size() > 0
      and shippedOutcome(specOutside) == "channel-family-mismatch"

  // lMissingX: a histogram with no channels at all.
  pure def specMissingX: SSpec =
    { family: "histogram", chans: Set(), isOver: false,
      decimate: false, refusedKeys: Set() }

  pure def lMissingXHolds: bool =
    shippedMissingX(specMissingX)
      and shippedOutcome(specMissingX) == "channel-family-mismatch"

  // lBarError: the bar's interval channel, refused on its own ground (S-04).
  pure def specBarError: SSpec =
    { family: "bar", chans: Set("x", "y", "error"), isOver: false,
      decimate: false, refusedKeys: Set() }

  pure def lBarErrorHolds: bool =
    shippedBarError(specBarError)
      and shippedOutcome(specBarError) == "channel-family-mismatch"

  // lLineError: a line carrying :error - outside the line's set (SF-2).
  pure def specLineError: SSpec =
    { family: "line", chans: Set("x", "y", "error"), isOver: false,
      decimate: false, refusedKeys: Set() }

  pure def lLineErrorHolds: bool =
    shippedOutsideFamily(specLineError).size() > 0
      and shippedOutcome(specLineError) == "channel-family-mismatch"

  // lKeyFirst: :sort beside a channel ground - the key refusal wins.
  pure def specKeyFirst: SSpec =
    { family: "scatter", chans: Set("y"), isOver: false,
      decimate: false, refusedKeys: Set("sort") }

  pure def lKeyFirstHolds: bool =
    shippedRefusedKey(specKeyFirst)
      and shippedOutcome(specKeyFirst) == "unsupported-option"

  // lFamStat: a bar with no value column runs the count stat.
  pure def specFamStat: SSpec =
    { family: "bar", chans: Set("x"), isOver: false,
      decimate: false, refusedKeys: Set() }

  pure def lFamStatHolds: bool =
    shippedStatOf(specFamStat) == "count"
      and shippedOutcome(specFamStat) == "resolved"

  // lStrategy: a scatter over budget with no :decimate lane falls to the
  // density-bin default.
  pure def specStrategy: SSpec =
    { family: "scatter", chans: Set("x", "y"), isOver: true,
      decimate: false, refusedKeys: Set() }

  pure def lStrategyHolds: bool =
    shippedStrategyOf(specStrategy) == "density-bin"
      and shippedOutcome(specStrategy) == "resolved"

  // lColour: :colour under a reduction is refused whatever the strategy.
  pure def specColour: SSpec =
    { family: "scatter", chans: Set("x", "y", "colour"), isOver: true,
      decimate: true, refusedKeys: Set() }

  pure def lColourHolds: bool =
    shippedColourRefused(specColour)
      and shippedOutcome(specColour) == "colour-under-reduction"

  // lOverBarHist: a histogram over budget has no reduction lane.
  pure def specOverBarHist: SSpec =
    { family: "histogram", chans: Set("x"), isOver: true,
      decimate: false, refusedKeys: Set() }

  pure def lOverBarHistHolds: bool =
    shippedOutcome(specOverBarHist) == "unsupported-chart"

  // ---- the leg's checks --------------------------------------------------

  pure def specOf(e: VizOutcome): SSpec = e._1

  // One expectation row: the shipped outcome for the row's spec equals the
  // written answer.
  pure def outcomeAgrees(e: VizOutcome): bool =
    shippedOutcome(specOf(e)) == e._2

  // One resolve row: the stat column and the strategy column.
  pure def statColumnAgrees(k: int): bool = {
    val sp = RESOLVED_SPEC[k]
    val st = EXPECTED_STAT[k]
    val sy = EXPECTED_STRAT[k]
    val out = shippedOutcome(sp)
    val gotStat = if (out == "resolved") shippedStatOf(sp) else ""
    val gotStrat = if (out == "resolved") shippedStrategyOf(sp) else ""
    and(gotStat == st, gotStrat == sy)
  }

  // One acceptance cell: with the channel present (x present too, so the
  // missing-x ground never pre-empts), the shipped model refuses exactly the
  // channels written down as OUTSIDE the family's set and resolves exactly
  // those written down as inside. The bar's :error is inside its set and
  // refuses on its own ground - that cell is wtraceBarError.
  pure def setCell(f: str, c: str): bool = {
    val sp = { family: f, chans: Set("x", c), isOver: false,
               decimate: false, refusedKeys: Set() }
    val out = shippedOutcome(sp)
    val outside = shippedOutsideFamily(sp).size() > 0
    val accepted = if (f == "scatter") EXPECTEDSETS[0].contains(c)
      else if (f == "line") EXPECTEDSETS[1].contains(c)
      else if (f == "histogram") EXPECTEDSETS[2].contains(c)
      else EXPECTEDSETS[3].contains(c)
    // the bar's :error is inside its set and refuses on its own ground (S-04)
    val barred = f == "bar" and c == "error"
    val want = if (accepted and not(barred)) "resolved"
      else "channel-family-mismatch"
    and(out == want, outside == not(accepted))
  }

  // ---- the runs, one finite assertion per written row --------------------

  run wtraceAnswers = {
    assert(outcomeAgrees(EXPECTEDO[0]))
      .then(assert(outcomeAgrees(EXPECTEDO[1])))
      .then(assert(outcomeAgrees(EXPECTEDO[2])))
      .then(assert(outcomeAgrees(EXPECTEDO[3])))
      .then(assert(outcomeAgrees(EXPECTEDO[4])))
      .then(assert(outcomeAgrees(EXPECTEDO[5])))
      .then(assert(outcomeAgrees(EXPECTEDO[6])))
      .then(assert(outcomeAgrees(EXPECTEDO[7])))
      .then(assert(outcomeAgrees(EXPECTEDO[8])))
      .then(assert(outcomeAgrees(EXPECTEDO[9])))
      .then(assert(outcomeAgrees(EXPECTEDO[10])))
      .then(assert(outcomeAgrees(EXPECTEDO[11])))
      .then(assert(outcomeAgrees(EXPECTEDO[12])))
      .then(assert(outcomeAgrees(EXPECTEDO[13])))
      .then(assert(outcomeAgrees(EXPECTEDO[14])))
      .then(assert(outcomeAgrees(EXPECTEDO[15])))
      .then(assert(outcomeAgrees(EXPECTEDO[16])))
      .then(assert(outcomeAgrees(EXPECTEDO[17])))
      .then(assert(outcomeAgrees(EXPECTEDO[18])))
      .then(assert(outcomeAgrees(EXPECTEDO[19])))
      .then(assert(statColumnAgrees(0)))
      .then(assert(statColumnAgrees(1)))
      .then(assert(statColumnAgrees(2)))
      .then(assert(statColumnAgrees(3)))
      .then(assert(statColumnAgrees(4)))
      .then(assert(statColumnAgrees(5)))
      .then(assert(statColumnAgrees(6)))
      .then(assert(statColumnAgrees(7)))
  }

  // The CO-FIRE row - a refused key beside an outside-family channel. The key
  // ground answers first on the code, so this is the one written answer that
  // distinguishes the ground ORDER.
  run wtraceCoFire = {
    val e = ( { family: "histogram", chans: Set("x", "y"), isOver: false,
                decimate: false, refusedKeys: Set("sort") },
              "unsupported-option" )
    assert(outcomeAgrees(e))
      .then(assert(shippedOutsideFamily(specOf(e)).size() > 0))
      .then(assert(shippedRefusedKey(specOf(e))))
  }

  // The named rows the check turns on.
  run wtraceScatterError = {
    // scatter + :error under budget RESOLVES (the m-outside witness).
    val e = ( { family: "scatter", chans: Set("x", "y", "error"),
                isOver: false, decimate: false, refusedKeys: Set() },
              "resolved" )
    assert(outcomeAgrees(e))
  }

  run wtraceBarError = {
    // S-04: bar + :error refuses on the channel ground (not bar-interval).
    val e = ( { family: "bar", chans: Set("x", "y", "error"),
                isOver: false, decimate: false, refusedKeys: Set() },
              "channel-family-mismatch" )
    assert(outcomeAgrees(e))
  }

  run wtraceLineSet = {
    val e = ( { family: "line", chans: Set("x", "y", "error"),
                isOver: false, decimate: false, refusedKeys: Set() },
              "channel-family-mismatch" )
    assert(outcomeAgrees(e))
  }

  run wtraceHistogramSet = {
    val e = ( { family: "histogram", chans: Set("x", "colour"),
                isOver: false, decimate: false, refusedKeys: Set() },
              "channel-family-mismatch" )
    assert(outcomeAgrees(e))
  }

  // The sets: one run per family, one assertion per channel.
  run wtraceSetsScatter = {
    assert(setCell("scatter", "x"))
      .then(assert(setCell("scatter", "y")))
      .then(assert(setCell("scatter", "colour")))
      .then(assert(setCell("scatter", "size")))
      .then(assert(setCell("scatter", "error")))
  }

  run wtraceSetsLine = {
    assert(setCell("line", "x"))
      .then(assert(setCell("line", "y")))
      .then(assert(setCell("line", "colour")))
      .then(assert(setCell("line", "size")))
      .then(assert(setCell("line", "error")))
  }

  run wtraceSetsHistogram = {
    assert(setCell("histogram", "x"))
      .then(assert(setCell("histogram", "y")))
      .then(assert(setCell("histogram", "colour")))
      .then(assert(setCell("histogram", "size")))
      .then(assert(setCell("histogram", "error")))
  }

  run wtraceSetsBar = {
    assert(setCell("bar", "x"))
      .then(assert(setCell("bar", "y")))
      .then(assert(setCell("bar", "colour")))
      .then(assert(setCell("bar", "size")))
      .then(assert(setCell("bar", "error")))
  }

  // :decimate is a scatter slot (S-06).
  run wtraceDecimate = {
    assert(shippedDecimateLegal({ family: "scatter", chans: Set("x", "y"),
                                  isOver: false, decimate: true, refusedKeys: Set() }))
      .then(assert(not(shippedDecimateLegal({ family: "line", chans: Set("x", "y"),
                                              isOver: false, decimate: true, refusedKeys: Set() }))))
      .then(assert(not(shippedDecimateLegal({ family: "histogram", chans: Set("x"),
                                              isOver: false, decimate: true, refusedKeys: Set() }))))
      .then(assert(not(shippedDecimateLegal({ family: "bar", chans: Set("x", "y"),
                                              isOver: false, decimate: true, refusedKeys: Set() }))))
  }


  // One run per limb: the specimen's written answer first, the limb's own
  // claim on it second, each as its own assertion.

  run wlimbDom = {
    assert(shippedOutcome(specDom) == "resolved")
      .then(assert(lDomHolds))
  }

  run wlimbOutside = {
    assert(shippedOutcome(specOutside) == "channel-family-mismatch")
      .then(assert(lOutsideHolds))
  }

  run wlimbMissingX = {
    assert(shippedOutcome(specMissingX) == "channel-family-mismatch")
      .then(assert(lMissingXHolds))
  }

  run wlimbBarError = {
    assert(shippedOutcome(specBarError) == "channel-family-mismatch")
      .then(assert(lBarErrorHolds))
  }

  run wlimbLineError = {
    assert(shippedOutcome(specLineError) == "channel-family-mismatch")
      .then(assert(lLineErrorHolds))
  }

  run wlimbKeyFirst = {
    assert(shippedOutcome(specKeyFirst) == "unsupported-option")
      .then(assert(lKeyFirstHolds))
  }

  run wlimbFamStat = {
    assert(shippedOutcome(specFamStat) == "resolved")
      .then(assert(lFamStatHolds))
  }

  run wlimbStrategy = {
    assert(shippedOutcome(specStrategy) == "resolved")
      .then(assert(lStrategyHolds))
  }

  run wlimbColour = {
    assert(shippedOutcome(specColour) == "colour-under-reduction")
      .then(assert(lColourHolds))
  }

  run wlimbOverBarHist = {
    assert(shippedOutcome(specOverBarHist) == "unsupported-chart")
      .then(assert(lOverBarHistHolds))
  }

}
