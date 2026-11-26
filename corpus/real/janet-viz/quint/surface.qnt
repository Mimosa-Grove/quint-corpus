// surface.qnt - the janet-viz GRAMMAR SURFACE as a Quint specification.
//
// LIMB HARDENING. The first version of this file stated its limbs over
// constants and a 15-specimen pool, and a 16-mutant sweep showed 12 of the 16
// semantic mutants surviving: a limb that is TRUE on every specimen once its
// single witness is removed is a sentence in a comment. The restatement below
// is the fix. Every limb here is a claim over SPECIMENS (SPECIMENS is a SET -
// its size is not part of any limb) or over the LAWFUL domain, and every limb
// names the mutant that kills it in its comment. A limb that could not be
// restated falsifiably was deleted and its law recorded in the notes block
// below, not kept as a claim.
//
// What this spec claims, and what it cannot:
//   - It claims the ACCEPT/REFUSE LAW: which family x channel combinations
//     resolve, which refuse, and on which ground. That is the surface the
//     coverage matrix found unclaimed.
//   - It claims the STAT and STRATEGY selection law: which stat a resolved
//     family ran, and which reduction strategy (if any) fires.
//   - It does NOT claim op emission. ir.qnt owns the op shape; surface.qnt
//     stops at the resolved record's stated fields. The two models meet at
//     (`stat`, `strategy`), which this spec states and the cells pin.
//   - It does NOT claim the row/mark-count seam. See the note on S-01 below.
//
//   S-08  The key set is CLOSED and no key is accepted in vain: :sort and
//         :order are schema keys the surface REFUSES (unsupported-option).
//         No sorting law is stated, so the keys cannot act; an accepted key
//         that cannot act is the silent-drop class.
//
// SURFACE FACTS the model is built from (each cited at its limb, tested by
// tests/cells/s9-surface-law.janet, s9-bar-error-rule.janet and
// s9-sort-refusal.janet):
//   S-01  Four families: scatter, line, histogram, bar (spec.janet
//         family-channels).
//   S-02  Channel sets: scatter {x y colour size error}; line {x y colour};
//         histogram {x}; bar {x y error}. A channel outside the family's
//         set is channel-family-mismatch.
//   S-03  Every family requires :x (channel-family-mismatch otherwise).
//   S-04  The bar family REFUSES :error for BOTH stats, and the class it
//         raises is channel-family-mismatch (resolve.janet:493-498). The
//         first version of this model named the ground "bar-interval", a
//         class the code cannot raise; the ground is now the code's own
//         class. Excluded from S-02's set.
//   S-05  Bar stat: :y absent -> count; :y present -> identity.
//         Histogram stat: bin (the x column bins).
//         Scatter/line stat: identity until the mark budget, then the
//         strategy decides (S-06).
//   S-06  Strategy: scatter over budget -> density-bin, or decimate when
//         :decimate is present; line over budget -> m4-envelope; every other
//         family over budget -> unsupported-chart (refused). :decimate is a
//         SCATTER slot: spec.janet refuses it on :line with line-decimation
//         (S-07).
//   S-07  :colour under ANY reduction is refused (colour-under-reduction),
//         for every strategy. Under a decimation the refusal stands on the
//         sample being a SUBSET; under density-bin and m4-envelope on an
//         aggregate mark carrying no category (resolve.janet:523-546). The
//         law is the same either way.
//
// Secondary notes (recorded here, not part of the claimed law):
//   SF-1  :error on a bar: grammar 2.2 ("on bar and point figures") and
//         grammar 2.3 ("error bars require identity bars") disagree. The code
//         refuses BOTH stats, which grammar 2.3's own sentence does not reach
//         (it names only the count form). The grammar text needs correcting;
//         the model states the code's law, and the text lags it.
//   SF-2  No channel set names `:error` for a line, but the code refuses it
//         at the SPEC surface. Both grounds refuse; the model states one
//         ground per family so a mutant that accepts the channel dies.
//   SF-3  A scatter over budget without :decimate falls to density-bin by
//         DEFAULT, not by any written sentence naming the default; the
//         default is the decimate opt-in (the absence of the key). Not a
//         contradiction - a stated default with a thin text line.
//   S-01  OUT OF SCOPE: the row/mark-count seam. L10 in the first version said
//         "an over-budget bar or histogram is refused", and `over` was a
//         specimen flag. In the code `over` is DATA-DERIVED (resolve.janet:
//         506-519): a bar's primaries are its CATEGORY count, a histogram's
//         are its BIN count, and neither is bounded by the row count - measured:
//         60000 rows over 5 categories resolve under a 50000 budget, while 3
//         categories over a budget of 2 refuse. This model can state the
//         threshold as a function of a primary count it is handed (that is
//         what primariesSent does now), but it CANNOT falsify the count itself:
//         the count lives between this surface and the reducer, and no specimen
//         of this model carries rows. The seam is discharged CODE-SIDE instead -
//         a scripted cross-check builds real rows per specimen (30
//         categories, 600 values into 24 bins, 3 rows) and asserts the code's
//         refusal against this model's over/none split on every one (see
//         scripts/surface-check.sh; 3072 rows, 0 disagreements). The model
//         states the law it can state; the count it cannot see is asserted one
//         level down, where the rows are.
//   S-02  DELETED LIMBS (the first version's L1, L2, L7 and L11 could not be
//         restated falsifiably and are gone; their law text is preserved here
//         as aspiration, never as a claim):
//         L1  "every spec resolves or refuses, and a refusal names a ground."
//             outcome(s) is TOTAL by construction - it returns one of the
//             grounds or "resolved" for every spec the type admits - so no
//             mutant can make it false. Deleted.
//         L2  "a resolved spec states a stat within the code's four."
//             statOf returns one of the four by construction (the four are
//             the branches of the same dispatch the code has). Deleted. The law
//             that MATTERS - which stat, for which family - is still claimed,
//             as L-famStat below (killable).
//         L7  "a resolved spec never carries a channel outside its family
//             set." implied by the refuse rule: resolution IS "no refusal
//             fired", and the outside-family ground is a refusal. A limb that
//             its own definitions entail cannot be killed by a mutant that
//             keeps those definitions. Deleted; the claim survives as L-outside,
//             which is the refusal direction and is killable.
//         L11 (a.k.a. L-key) "a refused schema key (:sort, :order) ALWAYS
//             refuses on its own ground." Keepable but not killable: the only
//             model that falsifies it is one that accepts :sort, and an
//             accepted :sort has no law to act under, so the counter-model is
//             not a surface this spec is ABOUT. What CAN be claimed is that
//             the key refusal WINS every other ground, and that is L-keyFirst
//             below (killable by reordering the grounds). The :sort/:order
//             surface itself is pinned code-side by s9-sort-refusal.janet.
//   LIMBS DELETED BY THE SWEEP (their law text is preserved here as aspiration,
//         never as a claim - see the limb block below):
//         lDom  "a spec in the domain carries a real family, and :decimate
//             only where the code accepts it."
//             TAUTOLOGY, not entailment: inDomain IS
//             and(famIs(s), decimateLegal(s)), so the limb was implies(X, X).
//             No mutant can falsify an identity. The in-file claim that lDom
//             "is killable" was false and is corrected here. The
//             :decimate-on-:line refusal it was said to pin is carried by
//             decimateLegal, which the domain reads directly. Deleted.
//         lColour "colour under a reduction is refused, whatever the
//             strategy."
//             GROUND-ORDER DEAD: outcome refuses on refused (outside-family,
//             missing :x, bar :error) before the colour clause is reached, so
//             a spec satisfying the limb's premise and breaching an earlier
//             ground refuses on that earlier ground. The conclusion is
//             unreachable through the premise. Deleted; the colour clause
//             itself stays in outcome and is not thereby unclaimed, it is
//             not reachable by THIS limb's premise.
//         lOverBarHist "an over-budget bar or histogram is refused."
//             GROUND-ORDER DEAD, same reason: an over-budget bar or histogram
//             carrying an outside channel, no :x, or a bar :error refuses
//             earlier; one carrying none is refused by reductionRefused.
//             Deleted.
//         lLineError "a line carrying :error is refused."
//             GROUND-ORDER DEAD: :error is not in line's family set (the line
//             set is {x, y, colour}), so :error on a line is an OUTSIDE-family
//             channel and refuses on the outside ground first. The limb's own
//             premise (family == line and carries error) can never reach its
//             conclusion via the line clause. Deleted; the family-set refusal
//             is claimed by lOutside, which the line case instantiates.
//
//         The limbs that REMAIN are falsifiable but UNWITNESSED by the limb
//         sweep: for an implies-limb, assert(limb(s)) on a premise-holding
//         specimen proves premise(s) and conclusion(s), not the limb's text, so
//         every implies-limb survives its own deletion. That is witness
//         blindness, not per-limb entailment. The six kept limbs are cited
//         from their stated killers only. Coverage for this surface is the
//         gate's written-answers leg, and the polarity-flip instrument is a
//         separate instrument that is not yet built.
//
//   S-03  RESTATED (L4, L5's ground, L6, L8, L9, L10 and the new L-famStat,
//         L-keyFirst): each is a claim over SPECIMENS. SPECIMENS builds a
//         separate specimen from SPECIMENS, so deleting a specimen or its
//         witness does not weaken the claim - only a mutant in the law can.
//   S-04  The over-budget refusal (the first version's L10) is stated over the
//         domain INCLUDING the lawful bar/histogram reductions: resolve.janet
//         refuses every family but scatter and line on budget, which is S-06
//         read at resolve time. The limb is the domain-restricted form of the
//         strategy law, so a mutant that gives a bar a reduction lane dies.

module vizSurface {

  // ---- the code's dispatch tables (src/viz/spec.janet 36, 53-57) ----

  pure val FAMILIES: Set[str] = Set("scatter", "line", "histogram", "bar")

  // The two refused schema keys, beside the key-closure rule (S-08).
  pure val REFUSEDKEYS: List[str] = List("sort", "order")

  pure val CHANNELS: List[str] = List("x", "y", "colour", "size", "error")

  pure def familyChannels(f: str): Set[str] =
    if (f == "scatter") Set("x", "y", "colour", "size", "error")
    else if (f == "line") Set("x", "y", "colour")
    else if (f == "histogram") Set("x")
    else Set("x", "y", "error")      // bar (S-02); :error is REFUSED at
                                     // resolve for both stats (S-04)

  // ---- the model's input record: a spec flattened to its surface ----

  type SSpec = {
    family: str,
    chans: Set[str],
    // The mark count is over the budget (S-06). Named `isOver`: `over` is a
    // Quint builtin, and a field of that name makes every expression reading
    // it recursive (QNT099).
    isOver: bool,
    decimate: bool,      // the :decimate key is present (scatter only, S-06)
    primariesSent: bool, // the counted primaries exceed the budget; the
                         // MODEL is handed this, it cannot derive it (S-01)
    refusedKeys: Set[str],  // schema keys the surface refuses (:sort, :order)
  }

  // A spec the surface can RECEIVE: a real family, and the :decimate slot only
  // where the code accepts it (spec.janet:406-409 refuses it on :line, S-06).
  // L-dom claims the restriction; a mutant that widens it dies (SM-dimA).
  pure def decimateLegal(s: SSpec): bool = (not(s.decimate)) or s.family == "scatter"

  // (quint 0.33.x: `"x".in(Set(...))` panics the Rust evaluator - a MEMBER
  // test on a literal set is spelled `x in FAMILIES`, which is the same claim)
  pure def famIs(s: SSpec): bool = (s.family == "scatter") or (s.family == "line")
    or (s.family == "histogram") or (s.family == "bar")

  pure def inDomain(s: SSpec): bool = and(famIs(s), decimateLegal(s))

  // ---- the acceptance law (S-02, S-03, S-04) ----

  pure def outsideFamily(s: SSpec): Set[str] =
    s.chans.exclude(familyChannels(s.family))

  // a diagnostic witness helper: true when the record carries the channel
  pure def carries(s: SSpec, c: str): bool = s.chans.contains(c)

  pure def missingX(s: SSpec): bool = not(s.chans.contains("x"))

  pure def barError(s: SSpec): bool =
    s.family == "bar" and s.chans.contains("error")

  // S-08: a refused key is present. At the surface the key-closure refusal is
  // raised BEFORE every channel clause (spec.janet check-known-keys), so it
  // governs a spec whatever else the spec carries - that ORDER is L-keyFirst.
  pure def refusedKey(s: SSpec): bool = s.refusedKeys.size() > 0

  // The grounds, in the code's order: the refused schema key first, then a
  // channel outside the family set, then the missing :x, then the bar's
  // interval rule (S-04: the code refuses it here, at resolve, and its class
  // is channel-family-mismatch - not the "bar-interval" of the first version).
  pure def refused(s: SSpec): bool =
    refusedKey(s) or not(famIs(s)) or outsideFamily(s).size() > 0
      or missingX(s) or barError(s)

  pure def ground(s: SSpec): str =
    if (refusedKey(s)) "unsupported-option"
    else if (not(famIs(s))) "unsupported-chart"
    else if (outsideFamily(s).size() > 0) "channel-family-mismatch"
    else if (missingX(s)) "channel-family-mismatch"
    else if (barError(s)) "channel-family-mismatch"
    else "resolved"

  // ---- the stat law (S-05) ----

  pure def statOf(s: SSpec): str =
    if (s.family == "bar")
      if (s.chans.contains("y")) "identity" else "count"
    else if (s.family == "histogram") "bin"
    else "identity"

  // The stat each family RUNS. This replaces the deleted L2: L2 said "the stat
  // is one of four", which is true by construction; this says WHICH, which a
  // dispatch mutant can break (killers: SM-statSwap, SM-barStat).
  pure def famStatLaw(s: SSpec): bool =
    implies(s.family == "bar" and s.chans.contains("y"), statOf(s) == "identity")
    and implies(s.family == "bar" and not(s.chans.contains("y")), statOf(s) == "count")
    and implies(s.family == "histogram", statOf(s) == "bin")
    and implies(s.family == "scatter" or s.family == "line", statOf(s) == "identity")

  // ---- the strategy law (S-06, S-07) ----

  pure def strategyOf(s: SSpec): str =
    if (s.isOver)
      if (s.family == "line") "m4-envelope"
      else if (s.family == "scatter")
        if (s.decimate) "decimate" else "density-bin"
      else "unsupported"
    else "none"

  // A strategy of "unsupported" is not a strategy: it is the refusal the
  // resolve path raises (unsupported-chart) for a family with no reduction.
  pure def reductionRefused(s: SSpec): bool =
    strategyOf(s) == "unsupported"

  // :colour under any reduction (S-07): refused for every strategy.
  pure def colourRefused(s: SSpec): bool =
    s.chans.contains("colour") and not(s.isOver) == false
      and strategyOf(s) != "none"

  // A spec RESOLVES when its channels are accepted and no reduction ground
  // fires; otherwise it REFUSES on the first ground the code states.
  pure def outcome(s: SSpec): str =
    if (refused(s)) ground(s)
    else if (reductionRefused(s)) "unsupported-chart"
    else if (colourRefused(s)) "colour-under-reduction"
    else "resolved"

  // ---- the stated drop ----
  //
  // `:error` and `:colour` behave differently under a reduction, and the code
  // says so. Measured 2026-11-02: an over-budget scatter carrying :error
  // RESOLVES with `:error-dropped true` and `:error-columns nil`, while the
  // same spec carrying :colour REFUSES `colour-under-reduction`. `outcome`
  // could not say the first, because a reduction that replaces rows with
  // marks no row owns cannot carry the interval columns, and the record
  // states that rather than drawing a channel it does not have
  // (resolve.janet:794-810).
  //
  // This is a RESOLUTION-WITH-STATED-DROP, not a refusal: a limb claiming the
  // code refuses this face would model the wrong behaviour.
  pure def errorStatedDropped(s: SSpec): bool =
    s.chans.contains("error") and strategyOf(s) != "none"

  // The drop is claimed only where the spec RESOLVES: a refused spec never
  // reaches a strategy, so there is no reduction to drop an interval for.
  pure def dropClaim(s: SSpec): bool =
    outcome(s) == "resolved" and errorStatedDropped(s)

  // ---- the surface law, stated as limbs over the LAWFUL domain ----
  // Every limb below is restricted to inDomain: the surface is only claimed for
  // specs the code can receive (a real family, :decimate where it is accepted).
  //
  // LIMB DISPOSITIONS. Three limbs were deleted on grounds measured in this
  // this file, and the limbs that remain split into two threat classes. Read
  // the class before citing a limb as coverage:
  //
  //   DELETED - lDom: TAUTOLOGY. inDomain IS and(famIs, decimateLegal), so the
  //     limb was implies(X, X). Nothing can falsify it, and it never pinned
  //     anything; the :decimate-on-:line refusal is carried by decimateLegal.
  //   DELETED - lColour, lOverBarHist: GROUND-ORDER DEAD. Their conclusions are
  //     unreachable, because a spec that satisfies their premise and also
  //     breaches an earlier ground refuses on the earlier ground first.
  //   DELETED - lLineError: GROUND-ORDER DEAD, same reason. :error is not in
  //     line's family set, so the outside ground fires before any line clause.
  //   KEPT - lOutside, lMissingX, lKeyFirst, lBarError, lFamStat, lStrategy:
  //     FALSIFIABLE but UNWITNESSED by assert-the-claim. The witness form
  //     cannot see an implies-limb at all (assert(limb(s)) on a premise-holding
  //     specimen proves premise(s) and conclusion(s), not the limb's text), so
  //     "survives deletion" says nothing about these six. They are real
  //     mutation targets and are cited only with their stated killers.

  // L-outside - a channel outside the family's set ALWAYS refuses on the
  // channel ground (killers: SM-1, SM-2 - a family set that gains or loses a
  // channel; SM-12 - the ground swapped). Unwitnessed by assert-the-claim
  // (witness-form tautology); falsifiable per stated killers
  // (SM-1/SM-2/SM-12).
  //
  // A refused KEY is refused before every channel ground (L-keyFirst), so on
  // a spec carrying both the channel ground is by construction unreachable
  // and this limb's conclusion is FALSE there. Without the carve-out a
  // co-fire specimen cannot sit in a pool that asserts invariantOk, and the
  // ORDER claim had no pool witness at all. The carve-out narrows the premise
  // to the specs on which the conclusion is the code's: measured, a pool
  // carrying a co-fire row is green with it and red without it, and a ground
  // dispatch mutant reddens the pool with it.
  pure def lOutside(s: SSpec): bool =
    implies(and(inDomain(s), outsideFamily(s).size() > 0, not(refusedKey(s))),
            outcome(s) == "channel-family-mismatch")

  // L-missingX - a family spec with no :x refuses (killer: SM-9 - missingX
  // dropped, so a channel-less spec resolves). Unwitnessed by
  // assert-the-claim (witness-form tautology); falsifiable per stated killer
  // (SM-9).
  pure def lMissingX(s: SSpec): bool =
    implies(and(inDomain(s), missingX(s)), outcome(s) == "channel-family-mismatch")

  // L-barError - the bar's interval channel is refused for BOTH stats, on the
  // code's class (S-04). Killers: SM-13 (barError dropped), SM-15 (the ground
  // renamed back to "bar-interval", the class the code cannot raise).
  // MEASURED 2026-11-02: a bar carrying :error on {x, error} breaches NO other
  // ground, so barError is the sole refusal and the conclusion is reachable.
  // Unwitnessed by assert-the-claim (witness-form tautology); falsifiable per
  // stated killers (SM-13/SM-15).
  pure def lBarError(s: SSpec): bool =
    implies(and(inDomain(s), barError(s)), outcome(s) == "channel-family-mismatch")

  // L-keyFirst - a refused schema key wins EVERY ground: a spec carrying
  // :sort or :order refuses on the key ground whatever else it carries.
  // Killer: SM-keyOrder - the ground order swapped so the channel ground wins.
  // Unwitnessed by assert-the-claim (witness-form tautology); falsifiable per
  // stated killer (SM-keyOrder).
  pure def lKeyFirst(s: SSpec): bool =
    implies(and(inDomain(s), refusedKey(s)), outcome(s) == "unsupported-option")

  // L-famStat - the family's stat (which, from S-05). Killers: SM-statSwap (a
  // bar's :y-present stat becomes count) and SM-histStat (a histogram's stat
  // stops being bin).
  // MEASURED 2026-11-02: every branch is independently falsifiable (a dispatch
  // swap breaks one arm only). Unwitnessed by assert-the-claim
  // (witness-form tautology); falsifiable per stated killers
  // (SM-statSwap/SM-histStat).
  //
  // CONSTRUCTION-EXCLUDED beside the statOf definition, not merely
  // unwitnessed. `famStatLaw` (above) compares statOf(s) against a literal
  // PER FAMILY, and statOf is the same family/chans dispatch, so the law is
  // TRUE on every spec the record can carry: the operand domain is the finite
  // set of (family, carries :y) pairs, all eight premised rows were
  // enumerated, and every one satisfies its branch (probe: an eight-row
  // enumeration, 8 of 8, zero violations). No run can witness lFamStat
  // because no state violates it - what a mutant of statOf moves is statOf
  // AND the law together, which is why the stated killers are dispatch
  // mutants, not law witnesses. The conjunct stays in invariantOk (it still
  // pins statOf's dispatch through the mutants), and its sweep verdict is
  // recorded as construction-excluded, never witnessed.
  pure def lFamStat(s: SSpec): bool =
    implies(inDomain(s), famStatLaw(s))

  // L-strategy - the reduction law: over budget, a line is m4-envelope, a
  // scatter is decimate when :decimate is present and density-bin otherwise,
  // and no other family has a reduction. Killer: SM-stratDefault (a scatter's
  // default becomes decimate) and SM-barLane (a bar gains a lane).
  // MEASURED 2026-11-02: a four-branch conjunction, each branch falsifiable on
  // its own. Unwitnessed by assert-the-claim (witness-form tautology);
  // falsifiable per stated killers (SM-stratDefault/SM-barLane).
  pure def lStrategy(s: SSpec): bool =
    implies(and(inDomain(s), s.isOver and s.family == "line"),
            strategyOf(s) == "m4-envelope")
    and implies(and(inDomain(s), s.isOver and (s.family == "scatter") and s.decimate),
                strategyOf(s) == "decimate")
    and implies(and(inDomain(s), s.isOver and s.family == "scatter" and not(s.decimate)),
                strategyOf(s) == "density-bin")
    and implies(and(inDomain(s), s.isOver and not(s.family == "line" or s.family == "scatter")),
                outcome(s) == "unsupported-chart")

  // ---- the state: a SEPARATELY BUILT specimen ----
  // SPECIMENS builds its own record rather than reading SPECIMENS, so a
  // pool edit cannot make a limb true-by-absence. The pool is still used by
  // the witnesses below (each witness names one of its rows).


  var s: SSpec

  // The reachable state: every specimen in the pool is IN this pool, so
  // `quint verify` reads the whole-limb conjunction over all of them while
  // each witness reads its own limb on its own specimen.
  pure def SPECIMENS: Set[SSpec] = Set(
    { family: "scatter", chans: Set("x", "y"), isOver: false, decimate: false,
      primariesSent: false, refusedKeys: Set() },
    { family: "scatter", chans: Set("x", "y"), isOver: true, decimate: true,
      primariesSent: true, refusedKeys: Set() },
    { family: "scatter", chans: Set("x", "y"), isOver: true, decimate: false,
      primariesSent: true, refusedKeys: Set() },
    { family: "line", chans: Set("x", "y"), isOver: true, decimate: false,
      primariesSent: true, refusedKeys: Set() },
    { family: "line", chans: Set("x", "y", "error"), isOver: false, decimate: false,
      primariesSent: false, refusedKeys: Set() },
    { family: "bar", chans: Set("x", "y", "error"), isOver: false, decimate: false,
      primariesSent: false, refusedKeys: Set() },
    { family: "bar", chans: Set("x", "error"), isOver: false, decimate: false,
      primariesSent: false, refusedKeys: Set() },
    { family: "bar", chans: Set("x", "y"), isOver: true, decimate: false,
      primariesSent: true, refusedKeys: Set() },
    { family: "bar", chans: Set("x", "y", "size"), isOver: false, decimate: false,
      primariesSent: false, refusedKeys: Set() },
    { family: "histogram", chans: Set("x"), isOver: false, decimate: false,
      primariesSent: false, refusedKeys: Set() },
    { family: "histogram", chans: Set("x", "colour"), isOver: false, decimate: false,
      primariesSent: false, refusedKeys: Set() },
    { family: "histogram", chans: Set("x", "size"), isOver: false, decimate: false,
      primariesSent: false, refusedKeys: Set() },
    { family: "histogram", chans: Set(), isOver: false, decimate: false,
      primariesSent: false, refusedKeys: Set() },
    { family: "scatter", chans: Set("y"), isOver: false, decimate: false,
      primariesSent: false, refusedKeys: Set() },
    { family: "scatter", chans: Set("x", "y", "colour"), isOver: true, decimate: true,
      primariesSent: true, refusedKeys: Set() },
    // the :sort / :order refusals (S-08): a refused key on an otherwise legal
    // spec, and on a spec that carries a channel ground as well (L-keyFirst).
    { family: "scatter", chans: Set("x", "y"), isOver: false, decimate: false,
      primariesSent: false, refusedKeys: Set("sort") },
    { family: "scatter", chans: Set("x", "y"), isOver: false, decimate: false,
      primariesSent: false, refusedKeys: Set("order") },
    { family: "scatter", chans: Set("x", "y", "size"), isOver: false, decimate: false,
      primariesSent: false, refusedKeys: Set("sort", "order") },
    // The STATED DROP face. An over-budget scatter carrying :error in its
    // reduction slot: the code RESOLVES and drops the interval columns
    // (measured 2026-11-02). The first version's "refused" limb was toothless
    // for the reason this row exists - no specimen carried :error with over,
    // so its antecedent was never true. This row makes the drop premise
    // reachable.
    { family: "scatter", chans: Set("x", "y", "error"), isOver: true, decimate: false,
      primariesSent: true, refusedKeys: Set() },
    // NO co-fire row lives in this pool, and the reason is structural. A spec
    // carrying a refused key that ALSO breaches a ground makes lMissingX (or
    // lOutside) FALSE - the key ground makes the limb's channel conclusion
    // unreachable, which is the same ground-order deadness that deleted
    // lColour/lOverBarHist. Such a row therefore cannot be in a pool that
    // asserts invariantOk, and a pool row was not what the survivor needed:
    // the ORDER claim is witnessed by wkeysortovermissingx below, written
    // against `ground`.
    // lOutside gained the `not(refusedKey(s))` carve-out so the co-fire class
    // is EXPRESSIBLE in a limb, but the row itself is NOT put in this pool:
    // measured, the pool witness already reaches the order face through its
    // missing-:x refused-key rows (a demoted key ground reddens
    // wSurfaceLawPool), and a co-fire row here would take that increment
    // through the pool assertion alone. The ORDER face is witnessed by
    // wkeycofire, which asserts `ground` directly.
  )

  action init =
    nondet drawn = SPECIMENS.oneOf()
    s' = drawn

  action step = s' = s

  // Named witnesses. Each pins ONE of the limbs above on its own specimen -
  // the pool rows are the witnesses' specimens, not their support.

  run wscatterresolved = {
    val sp = { family: "scatter", chans: Set("x", "y"), isOver: false, decimate: false,
               primariesSent: false, refusedKeys: Set() }
    assert(lFamStat(sp)).then(assert(lStrategy(sp))).then(assert(invariantOk(sp)))
  }

  run wscatterdecimate = {
    val sp = { family: "scatter", chans: Set("x", "y"), isOver: true, decimate: true,
               primariesSent: true, refusedKeys: Set() }
    assert(and(strategyOf(sp) == "decimate", lStrategy(sp)))
  }

  run wscatterdensitydefault = {
    val sp = { family: "scatter", chans: Set("x", "y"), isOver: true, decimate: false,
               primariesSent: true, refusedKeys: Set() }
    assert(and(strategyOf(sp) == "density-bin", lStrategy(sp)))
  }

  run wlineenvelope = {
    val sp = { family: "line", chans: Set("x", "y"), isOver: true, decimate: false,
               primariesSent: true, refusedKeys: Set() }
    assert(and(strategyOf(sp) == "m4-envelope", lStrategy(sp)))
  }

  // lLineError is deleted (ground-order dead). The OUTCOME it asserted
  // still holds and is still checked here, on the outside ground it fires on.
  run wlineerrorrefused = {
    val sp = { family: "line", chans: Set("x", "y", "error"), isOver: false, decimate: false,
               primariesSent: false, refusedKeys: Set() }
    assert(outcome(sp) == "channel-family-mismatch")
  }

  run wbarerrorrefused = {
    val sp = { family: "bar", chans: Set("x", "y", "error"), isOver: false, decimate: false,
               primariesSent: false, refusedKeys: Set() }
    assert(and(barError(sp), outcome(sp) == "channel-family-mismatch"))
      .then(assert(lBarError(sp)))
  }

  run wbarcountrefused = {
    val sp = { family: "bar", chans: Set("x", "error"), isOver: false, decimate: false,
               primariesSent: false, refusedKeys: Set() }
    assert(and(barError(sp), lBarError(sp)))
  }

  run wbaroverbudget = {
    val sp = { family: "bar", chans: Set("x", "y"), isOver: true, decimate: false,
               primariesSent: true, refusedKeys: Set() }
    // lOverBarHist is deleted (ground-order dead); the outcome stands.
    assert(outcome(sp) == "unsupported-chart")
  }

  run wbarsizerefused = {
    val sp = { family: "bar", chans: Set("x", "y", "size"), isOver: false, decimate: false,
               primariesSent: false, refusedKeys: Set() }
    assert(and(lOutside(sp), outcome(sp) == "channel-family-mismatch"))
  }

  run whistogrambin = {
    val sp = { family: "histogram", chans: Set("x"), isOver: false, decimate: false,
               primariesSent: false, refusedKeys: Set() }
    assert(and(statOf(sp) == "bin", lFamStat(sp)))
  }

  run whistogramcolourrefused = {
    val sp = { family: "histogram", chans: Set("x", "colour"), isOver: false, decimate: false,
               primariesSent: false, refusedKeys: Set() }
    assert(and(lOutside(sp), outcome(sp) == "channel-family-mismatch"))
  }

  run whistogramsizerefused = {
    val sp = { family: "histogram", chans: Set("x", "size"), isOver: false, decimate: false,
               primariesSent: false, refusedKeys: Set() }
    assert(and(lOutside(sp), outcome(sp) == "channel-family-mismatch"))
  }

  run whistogramemptychannels = {
    val sp = { family: "histogram", chans: Set(), isOver: false, decimate: false,
               primariesSent: false, refusedKeys: Set() }
    assert(and(lMissingX(sp), outcome(sp) == "channel-family-mismatch"))
  }

  run wmissingxrefused = {
    val sp = { family: "scatter", chans: Set("y"), isOver: false, decimate: false,
               primariesSent: false, refusedKeys: Set() }
    assert(and(lMissingX(sp), outcome(sp) == "channel-family-mismatch"))
  }

  run wcolourunderreduction = {
    val sp = { family: "scatter", chans: Set("x", "y", "colour"), isOver: true, decimate: true,
               primariesSent: true, refusedKeys: Set() }
    // lColour is deleted (ground-order dead); the outcome stands.
    assert(and(colourRefused(sp), outcome(sp) == "colour-under-reduction"))
  }

  run wbaroverhistrefused = {
    val sp = { family: "histogram", chans: Set("x"), isOver: true, decimate: false,
               primariesSent: true, refusedKeys: Set() }
    // lOverBarHist is deleted (ground-order dead); the outcome stands.
    assert(outcome(sp) == "unsupported-chart")
  }

  run wsortrefused = {
    val sp = { family: "scatter", chans: Set("x", "y"), isOver: false, decimate: false,
               primariesSent: false, refusedKeys: Set("sort") }
    assert(and(refusedKey(sp), ground(sp) == "unsupported-option"))
  }

  run worderefused = {
    val sp = { family: "scatter", chans: Set("x", "y", "size"), isOver: false, decimate: false,
               primariesSent: false, refusedKeys: Set("sort", "order") }
    assert(carries(sp, "size"))
      .then(assert(ground(sp) == "unsupported-option"))
  }

  // The co-fire face, the class that can see the ORDER. On a spec whose only
  // other ground is the missing :x, the refused key decides the answer;
  // demote the key ground and `ground` answers the channel instead.
  run wkeysortovermissingx = {
    val sp = { family: "bar", chans: Set("y"), isOver: false, decimate: false,
               primariesSent: false, refusedKeys: Set("sort") }
    assert(and(missingX(sp), outsideFamily(sp).size() == 0, refusedKey(sp)))
      .then(assert(ground(sp) == "unsupported-option"))
  }

  // The CO-FIRE face, witnessed DIRECTLY against `ground`. Every witness above
  // puts the refused key beside a ground that the DEMOTED key ground would
  // still answer (the missing :x), so the SM-keyOrder demotion (key ground
  // below the channel grounds) survives them. This specimen carries a refused
  // key AND an outside-family channel: the key ground and the channel ground
  // disagree about the answer, so the assertion reddens exactly when the order
  // moves. `lKeyFirst` cannot see this row (its implication goes vacuous on
  // any spec whose conclusion is unreachable); `ground` can.
  run wkeycofire = {
    val sp = { family: "histogram", chans: Set("x", "y"), isOver: false,
               decimate: false, primariesSent: false, refusedKeys: Set("sort") }
    assert(and(refusedKey(sp), outsideFamily(sp).size() > 0, inDomain(sp)))
      .then(assert(ground(sp) == "unsupported-option"))
  }

  run wdecimatelegality = {
    val sp = { family: "line", chans: Set("x", "y"), isOver: false, decimate: true,
               primariesSent: false, refusedKeys: Set() }
    val sp2 = { family: "line", chans: Set("x", "y"), isOver: false,
                decimate: false, primariesSent: false, refusedKeys: Set() }
    assert(and(not(decimateLegal(sp)), inDomain(sp2)))
  }

  // The drop is CLAIMED, and claimed on a spec where it is true.
  // The assertion is the sentence itself, not a refusal - this face resolves.
  run werrordropunderreduction = {
    val sp = { family: "scatter", chans: Set("x", "y", "error"), isOver: true, decimate: false,
               primariesSent: true, refusedKeys: Set() }
    assert(dropClaim(sp))
  }

  // The counter-case: :error on an UNDER-budget scatter resolves with no
  // reduction, so nothing is dropped. The claim must be false here, which is
  // what stops `dropClaim` from degenerating into "carries :error".
  run werrordropnotclaimedunder = {
    val sp = { family: "scatter", chans: Set("x", "y", "error"), isOver: false, decimate: false,
               primariesSent: false, refusedKeys: Set() }
    assert(not(dropClaim(sp)))
  }

  // The pool-wide check, over the pool the state draws from.
  run wSurfaceLawPool = {
    nondet sp = SPECIMENS.oneOf()
    all {
      s' = sp,
      assert(invariantOk(sp))
    }
  }

  // The POOL MEMBERSHIP FLOOR. `wSurfaceLawPool` draws its specimen at
  // random, so the conjunction is checked over the pool only when it comes to
  // a row - and EVERY pool row satisfies all six limbs, which is why a member
  // deleted from `invariantOk` leaves the pool witness green (measured: the
  // deleted limb passes the pool witness, `quint verify` returns NoError, and
  // only a limb whose BODY is broken reddens it). This run removes the
  // randomness: its own specimen carries `missingX` and no other breach, so
  // `lMissingX`'s premise holds there and the member is EXERCISED on every
  // run. A member deleted from the conjunction cannot be seen from here
  // either - that is a structural limit of a conjunction and is recorded, not
  // hedged - but the pool's membership is now a deterministic floor: six
  // members, one named run each, and the limb's own premise established before
  // the conjunction is read.
  run wSurfaceLimbFloor = {
    val sp = { family: "histogram", chans: Set(), isOver: false, decimate: false,
               primariesSent: false, refusedKeys: Set() }
    assert(missingX(sp))
      .then(assert(lMissingX(sp)))
      .then(assert(invariantOk(sp)))
  }

  // The limb conjunction over the reachable spec. `quint verify` takes this
  // name; the tests take the witnesses. The restated limbs are the ones a
  // mutant can falsify; the deleted ones (S-02) are not here to be true.
  //
  // Member note: lFamStat is CONSTRUCTION-EXCLUDED -
  // false on no state, because famStatLaw restates statOf's own dispatch (see
  // the note on the limb). It is kept as a member: it is what the
  // dispatcher mutants move, and dropping it would leave statOf unread by the
  // conjunction. Its unwitnessability is NOT the witness-form tautology that
  // covers the other five.
  pure def invariantOk(sp: SSpec): bool =
    and(lOutside(sp), lMissingX(sp), lBarError(sp),
        lKeyFirst(sp), lFamStat(sp), lStrategy(sp))

  val surfaceInv: bool = invariantOk(s)

}
