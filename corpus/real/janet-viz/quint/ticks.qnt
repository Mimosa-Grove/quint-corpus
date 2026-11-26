// ticks.qnt - the Wilkinson tick construction as a Quint specification.
//
// The closed design: Wilkinson's tick algorithm as the book states it:
// Q = [1, 5, 2, 2.5, 3] (preference-ordered), zero-inclusion, target
// m = 5, 5% domain padding, simplicity/coverage/granularity scoring,
// the hard 20% whitespace minimum.
//
// Model scale: hundredths of data units (integers only; the float
// arithmetic of the real scale is a spec-scale abstraction).
// Q mantissas in hundredths: [100, 500, 200, 250, 300].
//
// The points the specification text left open, each settled here and
// encoded as a named definition or property:
//   - The candidate tick-COUNT range k was not pinned by the text.
//     K_HI = m + 2, 2m and 3m each leave a domain in the verified band
//     with no admissible candidate, so the range is K_LO = 3,
//     K_HI = 20 (asserted explicitly as val t1k; t1 quantifies over
//     exactly this band).
//   - The tie-break order among equal-scoring candidates was
//     unpinned: lexicographic on (Q index, exponent j, k), first
//     maximum wins - stated as the explicit invariant t7 (was
//     incidental structure; idx is now a FAITHFUL lexicographic
//     encoding - the old qi*100+(j+1)*10+k collided at k > 9, e.g.
//     (qi=1, j=0, k=13) vs (qi=1, j=1, k=3)).
//   - The application point of the 5% padding was ambiguous: padding
//     applies AFTER the search; the search domain is the raw
//     (EMPTY_DOM/floor-expanded) domain - asserted explicitly as val
//     t10 (at or above the floor, pmin/pmax ARE dmin/dmax, never
//     1.05x).
//   - The whitespace denominator was ambiguous. The data-range
//     reading (coverage >= 5/6) is FALSE: domain (2019, 2101)
//     hundredths admits NO candidate at any k. The denominator is the
//     Talbot label range (coverage >= 4/5 of the LABEL range),
//     asserted explicitly as val t4c. That domain is the named
//     passing cell witnessCounterexample.
//   - Sub-unit domains can have an EMPTY admissible set, so a DOMAIN
//     FLOOR applies (behaviour, not error): the domain expands to
//     MIN_DOMAIN_SPAN before the search. See the derivation at the
//     constant. The floor composes with EMPTY_DOM: [v-1, v+1] has
//     span 200 >= MIN_DOMAIN_SPAN, so the degenerate rule always
//     dominates and the two rules never interact. Both rules share
//     ONE state space: init draws spans from 0 (degenerate) through
//     sub-floor to the band top.
//   - Domain spans above the search band: t1's existence guarantee held
//     only for spans up to 80000 hundredths, and nothing stated what
//     happens beyond it - the implementation answered with an EMPTY
//     tick set, so the existence guarantee silently lapsed outside a
//     band no document presents as a limit. Existence is TOTAL over
//     the state space. A search input whose span exceeds BAND_SPAN_MAX
//     is divided by the power of two that brings it under, searched at
//     that scale, and its resolved values multiplied back. Every
//     mantissa, exponent and k keeps its meaning: the reduction changes
//     the SCALE of the search, never the table. The mapping back is
//     exact (integer hundredths, power-of-two divisor, no rounding), and
//     the divisor is chosen from the span alone, so the reduction is
//     deterministic. See witnessWideSpan.

module vizTicks {

  // ---- parameters ----

  pure def M: int = 5              // target tick count (overridable)
  pure def K_LO: int = 3           // the standing default, not pinned
  // K_HI: the standing default m + 2 is false for some domains (the
  // domain (-2000, 40001) hundredths admits no candidate: the
  // floor-wasted sequence needs k = 10 at step 0.5); 2m and 3m fail
  // similarly, so the default is 20 - a named parameter, never
  // silently pinned.
  pure def K_HI: int = 20
  // EMPTY_DOM: the degenerate-domain expansion is [v-1, v+1] units -
  // half-span 100 hundredths
  pure def DEG_HALFSPAN: int = 100
  // MIN_DOMAIN_SPAN: the domain floor, 1 unit = 100
  // hundredths. DERIVED, not guessed: 100 is the lower edge of the
  // search's VERIFIED band (t1 was verified for spans 100..80000
  // hundredths at K_HI = 20), so flooring every sub-band domain to
  // exactly 100 hundredths lands every post-expansion domain INSIDE
  // the verified band - the existence guarantee re-verifies over the
  // whole input space instead of needing a new proof at a new edge.
  // Existence at span 100 holds with slack for EVERY alignment: the
  // smallest step (10, q=1 j=-1) gives worst-case label range
  // ceil((100+9)/10)*10 = 110 <= 5*100/4 = 125 (coverage 4/5),
  // k = 12 <= K_HI = 20. It composes with EMPTY_DOM (span 200), and
  // is unit-aligned; the true existence minimum (72 hundredths) has
  // no contract meaning and is not the pin.
  pure def MIN_DOMAIN_SPAN: int = 100

  // BAND_SPAN_MAX: the span at which the power-of-two reduction takes
  // over. 950000 hundredths = 9500 units.
  // DERIVED, not guessed: it is the LARGEST span any candidate in the
  // table admits, measured over the whole space - step 50000 at k = 20
  // has a label range of 19 * 50000 = 950000 hundredths, coverage
  // 4 * 950000 <= 5 * 950000 is exactly tight, and at 950001 no
  // (step, k) in the table passes. Halving an input above it gives at
  // most 475000, well inside - and every input at or below it is
  // searched raw, so the reduction never touches a domain the table
  // already covers.
  pure def BAND_SPAN_MAX: int = 950000

  // ---- the step space: 20 constant steps (Q x exponent) ----
  // Q = [1, 5, 2, 2.5, 3] in preference order (qi 1..5); step = q * 10^j
  // in hundredths; j in -1..2.

  type Step = { qi: int, j: int, step: int }

  pure def STEPSET: Set[Step] = Set(
    { qi: 1, j: -1, step: 10 },     { qi: 1, j: 0, step: 100 },
    { qi: 1, j: 1, step: 1000 },    { qi: 1, j: 2, step: 10000 },
    { qi: 2, j: -1, step: 50 },     { qi: 2, j: 0, step: 500 },
    { qi: 2, j: 1, step: 5000 },    { qi: 2, j: 2, step: 50000 },
    { qi: 3, j: -1, step: 20 },     { qi: 3, j: 0, step: 200 },
    { qi: 3, j: 1, step: 2000 },    { qi: 3, j: 2, step: 20000 },
    { qi: 4, j: -1, step: 25 },    { qi: 4, j: 0, step: 250 },
    { qi: 4, j: 1, step: 2500 },   { qi: 4, j: 2, step: 25000 },
    { qi: 5, j: -1, step: 30 },    { qi: 5, j: 0, step: 300 },
    { qi: 5, j: 1, step: 3000 },   { qi: 5, j: 2, step: 30000 })

  pure def KSET: Set[int] = 3.to(20)  // K_LO..K_HI (m+2, 2m and 3m fail; 20 verifies the band)

  // ---- integer floor division (quint / truncates toward zero) ----

  pure def fdiv(a: int, b: int): int = {
    val q = a / b
    if (q * b > a) { q - 1 } else { q }
  }

  pure def ab(x: int): int = if (x < 0) { -x } else { x }

  // ---- candidates: (step, k) with the zero-inclusion flooring ----
  // lmin = step * floor(dmin / step) grounds the sequence at a
  // multiple of the step at or below dmin; lmax = lmin + (k-1)*step.

  type Cand = { st: Step, k: int, lmin: int, lmax: int }

  pure def mkCand(dmin: int, dmax: int, s: Step, k: int): Cand = {
    val lo = s.step * fdiv(dmin, s.step)
    { st: s, k: k, lmin: lo, lmax: lo + (k - 1) * s.step }
  }

  // ---- the wide-span reduction ----
  // A search input above BAND_SPAN_MAX is searched at 1/2^h of its own
  // scale (h counted, so the reduction is a pure function) and its
  // chosen values are multiplied back by 2^h. Both directions are
  // DEFINED HERE, above the candidates, because the candidate builder
  // and the tick reporter both use them: the reduction is a property of
  // the search input, not of any one candidate.

  pure def halvings(dmin: int, dmax: int): int =
    (if (dmax - dmin > BAND_SPAN_MAX) { 1 } else { 0 })
    + (if (dmax - dmin > 2 * BAND_SPAN_MAX) { 1 } else { 0 })
    + (if (dmax - dmin > 4 * BAND_SPAN_MAX) { 1 } else { 0 })
    + (if (dmax - dmin > 8 * BAND_SPAN_MAX) { 1 } else { 0 })
    + (if (dmax - dmin > 16 * BAND_SPAN_MAX) { 1 } else { 0 })
    + (if (dmax - dmin > 32 * BAND_SPAN_MAX) { 1 } else { 0 })
    + (if (dmax - dmin > 64 * BAND_SPAN_MAX) { 1 } else { 0 })

  pure def divisor(dmin: int, dmax: int): int = pow2(halvings(dmin, dmax))

  pure def pow2(h: int): int =
    if (h <= 0) { 1 }
    else { if (h == 1) { 2 }
    else { if (h == 2) { 4 }
    else { if (h == 3) { 8 }
    else { if (h == 4) { 16 }
    else { if (h == 5) { 32 }
    else { if (h == 6) { 64 } else { 128 } } } } } } }

  pure def sLo(dmin: int, dmax: int): int = fdiv(dmin, divisor(dmin, dmax))
  pure def sHi(dmin: int, dmax: int): int = dmax / divisor(dmin, dmax)

  // The SEARCH INPUT: the EMPTY_DOM/floor-expanded domain, reduced
  // by the power of two that brings its span under the ceiling. The
  // floor is applied BEFORE the reduction on purpose - a reduced span
  // that rounds down must not fall under MIN_DOMAIN_SPAN and re-enter
  // an expansion that would move it again, or the reduction would not
  // be idempotent.
  pure def searchLo(dmin: int, dmax: int): int =
    sLo(expandLo(dmin, dmax), expandHi(dmin, dmax))

  pure def searchHi(dmin: int, dmax: int): int =
    sHi(expandLo(dmin, dmax), expandHi(dmin, dmax))

  // the candidate space AT THE SEARCH SCALE: every candidate the search
  // considers for (dmin, dmax) is a candidate of the reduced input
  pure def mkCandS(dmin: int, dmax: int, s: Step, k: int): Cand =
    mkCand(searchLo(dmin, dmax), searchHi(dmin, dmax), s, k)

  // admissible: the sequence covers the domain and leaves no more
  // than 20% whitespace, as a fraction of the LABEL range, i.e.
  // coverage >= 4/5, the Wilkinson/Talbot hard minimum; the
  // data-range reading, coverage >= 5/6, fails the existence
  // requirement: domain (2019, 2101) hundredths admits no candidate
  // under it)
  pure def adm(dmin: int, dmax: int, c: Cand): bool =
    c.lmin <= dmin and c.lmax >= dmax
    and 4 * (c.lmax - c.lmin) <= 5 * (dmax - dmin)

  // ---- the scoring (Wilkinson, as transcribed) ----
  // score = simplicity + coverage + granularity, where
  //   simplicity = 1 - i/|Q| + v/|Q|     (numerator simN over 5)
  //   coverage   = R / (lmax - lmin)     (rational; compared exactly
  //                                       by cross-multiplication)
  //   granularity = 1 - |k - m| / m      (numerator granN over 5)
  // score = A / (5 * lr) with A = (simN + granN) * lr + 5 * R.

  pure def simN(c: Cand): int = {
    val v = if (c.lmin <= 0 and c.lmax >= 0) { 1 } else { 0 }
    5 - c.st.qi + v
  }

  pure def granN(c: Cand): int = M - ab(c.k - M)

  pure def scoreA(dmin: int, dmax: int, c: Cand): int =
    (simN(c) + granN(c)) * (c.lmax - c.lmin) + 5 * (dmax - dmin)

  pure def scoreD(c: Cand): int = 5 * (c.lmax - c.lmin)

  // strictly better: c1 > c2
  pure def better(dmin: int, dmax: int, c1: Cand, c2: Cand): bool =
    scoreA(dmin, dmax, c1) * scoreD(c2) > scoreA(dmin, dmax, c2) * scoreD(c1)

  // equal score (exact rational equality)
  pure def tie(dmin: int, dmax: int, c1: Cand, c2: Cand): bool =
    scoreA(dmin, dmax, c1) * scoreD(c2) == scoreA(dmin, dmax, c2) * scoreD(c1)

  // scan order: lexicographic on (Q index, j, k).
  // FAITHFUL encoding - each field gets its own digit band (k reaches
  // 20, so the old (j+1)*10 + k collided at k > 9)
  pure def idx(c: Cand): int = c.st.qi * 10000 + (c.st.j + 1) * 1000 + c.k

  // THE CHOSEN CANDIDATE: admissible, weakly maximal, first in scan
  // order among the equal-scoring maxima
  pure def isChosen(dmin: int, dmax: int, c: Cand): bool =
    adm(dmin, dmax, c)
    and STEPSET.forall(s => KSET.forall(k => {
      val c2 = mkCand(dmin, dmax, s, k)
      implies(adm(dmin, dmax, c2),
              not(better(dmin, dmax, c2, c))
              and implies(tie(dmin, dmax, c2, c), idx(c) <= idx(c2)))
    }))

  // ---- the picker: a fold over the constant step x k space ----
  // (deterministic: the fold's result depends only on the comparison,
  // not the traversal order)

  pure def NONEC: Cand = { st: { qi: 0, j: 0, step: 0 }, k: 0, lmin: 0, lmax: 0 }

  pure def consider(dmin: int, dmax: int, acc: Cand, s: Step, k: int): Cand = {
    val c = mkCand(dmin, dmax, s, k)
    if (adm(dmin, dmax, c)
        and (acc.st.qi == 0
             or better(dmin, dmax, c, acc)
             or (tie(dmin, dmax, c, acc) and idx(c) < idx(acc)))) {
      c
    } else {
      acc
    }
  }

  pure def pick(dmin: int, dmax: int): Cand =
    STEPSET.fold(NONEC, (acc, s) => KSET.fold(acc, (acc2, k) =>
      consider(searchLo(dmin, dmax), searchHi(dmin, dmax), acc2, s, k)))

  // the ticks the search REPORTS for a domain: the chosen candidate's
  // values, multiplied back out of the wide-span reduction. Identity below
  // the band (halvings = 0).
  pure def ticksAt(dmin: int, dmax: int): List[int] =
    wideTicks(pick(dmin, dmax), dmin, dmax)

  // ---- the tick values ----

  pure def ticksOf(c: Cand): List[int] =
    if (c.k == 3) { [c.lmin, c.lmin + c.st.step, c.lmin + 2 * c.st.step] }
    else { if (c.k == 4) { [c.lmin, c.lmin + c.st.step, c.lmin + 2 * c.st.step, c.lmin + 3 * c.st.step] }
           else { if (c.k == 5) { [c.lmin, c.lmin + c.st.step, c.lmin + 2 * c.st.step, c.lmin + 3 * c.st.step, c.lmin + 4 * c.st.step] }
                  else { if (c.k == 6) { [c.lmin, c.lmin + c.st.step, c.lmin + 2 * c.st.step, c.lmin + 3 * c.st.step, c.lmin + 4 * c.st.step, c.lmin + 5 * c.st.step] }
                         else { [c.lmin, c.lmin + c.st.step, c.lmin + 2 * c.st.step, c.lmin + 3 * c.st.step, c.lmin + 4 * c.st.step, c.lmin + 5 * c.st.step, c.lmin + 6 * c.st.step] } } } }

  // ---- domain expansion: EMPTY_DOM, then the MIN_DOMAIN_SPAN floor ----
  // One pass, one state space: a zero-range domain takes EMPTY_DOM
  // [v-1, v+1]; a nondegenerate span below MIN_DOMAIN_SPAN expands
  // centre-preservingly to EXACTLY the floor (pmax = pmin + 100);
  // spans at or above the floor pass through raw (the 5%
  // padding applies AFTER the search, never here).

  pure def expandLo(dmin: int, dmax: int): int =
    if (dmin == dmax) { dmin - DEG_HALFSPAN }
    else { if (dmax - dmin < MIN_DOMAIN_SPAN) { dmin - ((MIN_DOMAIN_SPAN - (dmax - dmin)) / 2) } else { dmin } }

  pure def expandHi(dmin: int, dmax: int): int =
    if (dmin == dmax) { dmax + DEG_HALFSPAN }
    else { if (dmax - dmin < MIN_DOMAIN_SPAN) { expandLo(dmin, dmax) + MIN_DOMAIN_SPAN } else { dmax } }

  // ---- the wide-span reduction ----
  // A search input wider than the band is divided by 2 until it fits.
  // The counted steps make the reduction a pure function (no recursion).

  // the widened tick sequence: the chosen candidate's values scaled back
  // up. Only the reported values move, never the choice.
  pure def wideTicks(c: Cand, dmin: int, dmax: int): List[int] = {
    val f = divisor(dmin, dmax)
    val t = ticksOf(c)
    if (c.k == 3) { [t[0] * f, t[1] * f, t[2] * f] }
    else { if (c.k == 4) { [t[0] * f, t[1] * f, t[2] * f, t[3] * f] }
           else { if (c.k == 5) { [t[0] * f, t[1] * f, t[2] * f, t[3] * f, t[4] * f] }
                  else { if (c.k == 6) { [t[0] * f, t[1] * f, t[2] * f, t[3] * f, t[4] * f, t[5] * f] }
                         else { [t[0] * f, t[1] * f, t[2] * f, t[3] * f, t[4] * f, t[5] * f, t[6] * f] } } } }
  }

  // ---- the state machine ----
  // raw data domain (dmin, dmax) -> the floor/EMPTY_DOM expansion
  // (pmin, pmax) -> the search; a zero-range domain is expanded BEFORE
  // the search and never reaches it.

  var dmin: int
  var dmax: int
  var pmin: int
  var pmax: int
  var cand: Cand

  action init =
    nondet lo = (-40000).to(40000).oneOf();
    // The domain draw: spans from 0 (degenerate, EMPTY_DOM)
    // through sub-floor (the domain floor) to the verified band top -
    // every expansion rule shares this one state space
    nondet w = 0.to(80000).oneOf();
    // The same state space, extended above the band top. ONE pipeline
    // runs for every draw - the raw domain (rmin, rmax), then
    // expandLo/expandHi, then the wide-span reduction, and the
    // candidate is built at that search scale - so the wide regime
    // cannot drift from the banded one.
    nondet wide = 0.to(1).oneOf();
    nondet wl = (-200000).to(200000).oneOf();
    nondet ww = 0.to(2000000).oneOf();
    nondet s = STEPSET.oneOf();
    nondet kk = KSET.oneOf();
    all {
      dmin' = if (wide == 1) { wl } else { lo },
      dmax' = if (wide == 1) { wl + ww } else { lo + w },
      pmin' = searchLo(if (wide == 1) { wl } else { lo }, if (wide == 1) { wl + ww } else { lo + w }),
      pmax' = searchHi(if (wide == 1) { wl } else { lo }, if (wide == 1) { wl + ww } else { lo + w }),
      cand' = mkCandS(if (wide == 1) { wl } else { lo }, if (wide == 1) { wl + ww } else { lo + w }, s, kk),
    }

  // The verify model draws an ARBITRARY candidate (nondet s, k); the
  // properties below are stated so the arbitrary draw still proves
  // them: existence via exists, uniqueness via isChosen, zero-
  // inclusion and structure over every admissible candidate. pick
  // (the fold) is verified at runtime: the witnesses and the
  // simulation runs evaluate it directly.

  action stutter = all {
    dmin' = dmin, dmax' = dmax, pmin' = pmin, pmax' = pmax, cand' = cand,
  }

  // ---- the properties ----

  // T0: degenerate domains never reach the search: the search input is
  // always nondegenerate, and the EMPTY_DOM expansion is [v-1, v+1]
  val t0 = pmin < pmax
  val t0b = implies(dmin == dmax, pmin == dmin - DEG_HALFSPAN and pmax == dmax + DEG_HALFSPAN)

  // T0c (the domain floor): a nondegenerate span below the floor expands
  // to EXACTLY MIN_DOMAIN_SPAN, containing the raw domain
  val t0c = implies(dmin != dmax and dmax - dmin < MIN_DOMAIN_SPAN,
                    pmax - pmin == MIN_DOMAIN_SPAN and pmin <= dmin and dmax <= pmax)

  // T0d: every search input is at or above the floor and contains the
  // raw domain (both expansion rules, one statement)
  val t0d = pmax - pmin >= MIN_DOMAIN_SPAN and pmin <= dmin and dmax <= pmax

  // T1k (explicit): the k band is exactly K_LO = 3, K_HI = 20 - the
  // band t1 quantifies over
  val t1k = K_LO == 3 and K_HI == 20 and K_LO < K_HI

  // T10 (explicit): padding applies AFTER the search - at or above
  // the floor, the search domain IS the raw domain (never the 1.05x
  // padded domain)
  val t10 = implies(dmin != dmax and dmax - dmin >= MIN_DOMAIN_SPAN,
                    pmin == dmin and pmax == dmax)

  // T4c (explicit): the coverage minimum is 4/5 of the LABEL range
  // (the Talbot label-range reading) - witnessed on every admissible
  // candidate, not just incidentally inside adm
  val t4c = implies(adm(pmin, pmax, cand),
                    4 * (cand.lmax - cand.lmin) <= 5 * (pmax - pmin))

  // T1: existence (every domain admits) - for EVERY search
  // input in the state space (now spans 0..80000 hundredths, through
  // EMPTY_DOM and the floor), SOME candidate is admissible
  val t1 = STEPSET.exists(s => KSET.exists(k => adm(pmin, pmax, mkCand(pmin, pmax, s, k))))

  // T5: zero-inclusion - if the domain contains 0, every admissible
  // covering sequence includes a zero tick
  val t5 = implies(pmin <= 0 and 0 <= pmax,
                   implies(adm(pmin, pmax, cand), cand.lmin <= 0 and 0 <= cand.lmax))

  // T6: nice steps - the sequence is a uniform arithmetic progression
  // of the chosen step (structural, for every candidate)
  val t6 = cand.st.step > 0
       and cand.lmax == cand.lmin + (cand.k - 1) * cand.st.step

  // T7 (an explicit invariant): the tie-break is lexicographic on (Q
  // index, j, k) - a CHOSEN candidate is never displaced in scan
  // order by an equal-scoring admissible candidate (first maximum
  // wins)
  val t7 = implies(isChosen(pmin, pmax, cand),
                   STEPSET.forall(s2 => KSET.forall(k2 => {
                     val c2 = mkCand(pmin, pmax, s2, k2)
                     implies(adm(pmin, pmax, c2) and tie(pmin, pmax, c2, cand),
                             idx(cand) <= idx(c2))
                   })))

  // T2: determinism - the chosen candidate is UNIQUE (any two
  // candidates satisfying isChosen are the same): two independent
  // implementations must produce the same tick set
  val t2 = STEPSET.forall(s1 => KSET.forall(k1 =>
           implies(isChosen(pmin, pmax, mkCand(pmin, pmax, s1, k1)),
                   STEPSET.forall(s2 => KSET.forall(k2 =>
                     implies(isChosen(pmin, pmax, mkCand(pmin, pmax, s2, k2)),
                             mkCand(pmin, pmax, s1, k1) == mkCand(pmin, pmax, s2, k2)))))))


  // runtime forms for the simulation runs (pick is concrete at
  // runtime): pick selects THE chosen candidate, and nothing beats it
  pure def optimalAgainst(dmin: int, dmax: int, c: Cand): bool =
    STEPSET.forall(s => KSET.forall(k =>
      implies(adm(dmin, dmax, mkCand(dmin, dmax, s, k)),
              not(better(dmin, dmax, mkCand(dmin, dmax, s, k), c)))))

  val t1brt = optimalAgainst(pmin, pmax, pick(pmin, pmax))
  val t2rt = isChosen(pmin, pmax, pick(pmin, pmax))

  // t7 runtime form for the simulation runs: the concrete pick is
  // tie-break minimal - no equal-scoring admissible candidate scans
  // earlier
  val t7rt = STEPSET.forall(s2 => KSET.forall(k2 => {
    val c2 = mkCand(pmin, pmax, s2, k2)
    implies(adm(pmin, pmax, c2) and tie(pmin, pmax, c2, pick(pmin, pmax)),
            idx(pick(pmin, pmax)) <= idx(c2))
  }))

  // ---- witnesses ----

  // the worked example: [0, 800] units, m = 5 ->
  // {0, 200, 400, 600, 800} (hundredths: 80000)

  run witnessTicksWorked = {
    val c = pick(0, 80000)
    assert(ticksOf(c) == [0, 20000, 40000, 60000, 80000])
  }

  // the chosen candidate is the unique chosen one (determinism on the
  // worked example)
  run witnessChosenUnique = {
    val c = pick(0, 80000)
    assert(isChosen(0, 80000, c))
  }

  // degenerate domain: [v, v] expands to [v-1, v+1] and the SAME
  // search produces its ticks - v = 10 units: the winner is q=5 at
  // 0.5 units, k=5 (score 2.6 beats q=1 at 1 unit, k=3, score 2.4)
  run witnessDegenerate = {
    val lo = expandLo(1000, 1000)
    val hi = expandHi(1000, 1000)
    assert(lo == 900 and hi == 1100)
    .then(assert(ticksOf(pick(lo, hi)) == [900, 950, 1000, 1050, 1100]))
    .then(assert(isChosen(lo, hi, pick(lo, hi))))
  }

  // The data-range reading's counterexample domain, now a named
  // PASSING cell: 20.19-21.01 units = (2019, 2101) hundredths. Under
  // the data-range reading (coverage >= 5/6 of the DATA range) the raw
  // domain admits NO candidate at any k - that failure is asserted
  // here; under the Talbot label-range reading plus the domain floor
  // it expands to (2010, 2110) hundredths and admits. The winner is a
  // genuine SCORE TIE (q=2 at 0.2 units, k=7 vs q=3 at 0.3 units,
  // k=5, both 1100/600) broken by the lexicographic (Q, j, k) order -
  // the tie-break rule visible on a real cell.
  run witnessCounterexample = {
    val lo = expandLo(2019, 2101)
    val hi = expandHi(2019, 2101)
    assert(lo == 2010 and hi == 2110)
    .then(assert(not(STEPSET.exists(s => KSET.exists(k => {
          val c = mkCand(2019, 2101, s, k)
          c.lmin <= 2019 and c.lmax >= 2101 and 5 * (c.lmax - c.lmin) <= 6 * (2101 - 2019)
        }))) ))
    .then(assert(adm(lo, hi, mkCand(lo, hi, { qi: 3, j: -1, step: 20 }, 7))))
    .then(assert(tie(lo, hi, mkCand(lo, hi, { qi: 3, j: -1, step: 20 }, 7),
                        mkCand(lo, hi, { qi: 5, j: -1, step: 30 }, 5))))
    .then(assert(pick(lo, hi) == mkCand(lo, hi, { qi: 3, j: -1, step: 20 }, 7)))
    .then(assert(isChosen(lo, hi, pick(lo, hi))))
  }

  // the two expansion rules compose without interaction: EMPTY_DOM
  // (span 2 units) is above the floor and passes through raw; a 0.5-
  // unit span floors to exactly 1 unit; a 1-unit span (the floor
  // edge) passes through raw
  run witnessFloorInterplay = {
    assert(expandLo(1000, 1000) == 900 and expandHi(1000, 1000) == 1100)
    .then(assert(expandLo(1000, 1050) == 975 and expandHi(1000, 1050) == 1075))
    .then(assert(expandLo(1000, 1100) == 1000 and expandHi(1000, 1100) == 1100))
    .then(assert(isChosen(expandLo(1000, 1050), expandHi(1000, 1050),
                          pick(expandLo(1000, 1050), expandHi(1000, 1050)))))
  }

  // the wide-span reduction divides a search input above BAND_SPAN_MAX
  // by the power of two that fits, so the operand is always inside the
  // band t1 quantifies over and the reduction is the IDENTITY where
  // the band already applies - the reduction never moves a resolvable
  // domain's ticks.
  run witnessWideSpan = {
    // in band: no halving, the operand is the input itself (0..800
    // units passes through untouched - the worked example's domain)
    assert(halvings(0, 80000) == 0 and sLo(0, 80000) == 0 and sHi(0, 80000) == 80000)
    // at the boundary: the largest span the table admits is searched
    // raw, one hundredth above takes one halving
    .then(assert(halvings(0, 950000) == 0 and halvings(0, 950001) == 1))
    // the table's ceiling, as a property of the RAW table: at 950000
    // hundredths exactly step 50000 at k = 20 admits (coverage 4/5
    // tight on the unreduced span) - the derivation the boundary rests
    // on, asserted rather than commented. The scale-aware adm below
    // does not use this: it reduces first, so every span admits.
    .then(assert(adm(0, 950000, mkCand(0, 950000, { qi: 2, j: 2, step: 50000 }, 20))))
    // a domain the raw table cannot reach: data x in [0, 392000] units =
    // 39200000 hundredths. Six halvings land it at 612500 hundredths
    // = 6125 units, and that operand admits a candidate - non-empty
    // ticks where the implementation emitted none.
    .then(assert(halvings(0, 39200000) == 6))
    .then(assert(sLo(0, 39200000) == 0 and sHi(0, 39200000) == 612500))
    .then(assert(STEPSET.exists(s => KSET.exists(k =>
            adm(sLo(0, 39200000), sHi(0, 39200000), mkCandS(0, 39200000, s, k))))))
    // and the widened values land back on the raw scale, covering the
    // raw domain and still zero-inclusive
    .then(assert(ticksAt(0, 39200000).length() >= 3))
    .then(assert(ticksAt(0, 39200000)[0] == 0))
    .then(assert(pick(0, 39200000).lmax * 64 >= 39200000))
  }

  // determinism: recompute - identical
  run witnessStable = {
    assert(pick(0, 80000) == pick(0, 80000))
    .then(assert(pick(-350, 1200) == pick(-350, 1200)))
  }
}
