// surface-limb-calibration.qnt - the limb sweep's instrument calibration.
// Licence: AGPLv3 (janet-viz).
//
// HARD GATE. Before any limb is deleted, the sweep's instrument must answer a
// KNOWN-TRUE and a KNOWN-FALSE question correctly, in BOTH polarities, over
// the IDENTICAL specimen.
//
// Why both polarities. The failure this gate exists for is the signature
//     assert(P) green  AND  assert(not(P)) red      (same expression, same data)
// which is not a wrong answer to P - it is no answer at all, and a limb
// "surviving" under it says nothing about the limb. A one-sided check cannot
// see it, because a green assert(P) looks exactly like a true P. Requiring the
// negation to be red FORCES the pair to be consistent, and requiring the
// complement specimen's pair to invert pins the direction.
//
// The specimens are the model's own six-field records, written here with every
// field (`primariesSent` is declared and never read; it is given here only
// because a record literal must name every declared field).
//
// Every run is expected GREEN except the two marked EXPECT-RED, which the
// sweep harness runs separately and requires to FAIL. The file is written so
// that a reader can run the green set with one --match and the red set with
// another.

module vizLimbCalibration {

  import vizSurface as M from "./surface"

  // ---- the IN specimen and its complement -------------------------------
  //
  // IN: a bar carrying :size - a channel outside the bar's set {x, y, error}.
  //     M::outsideFamily(IN) is non-empty, so lOutside's premise holds.
  // OUT: the same bar without :size - inside its set, so the premise fails.

  val inSpec: M::SSpec = {
    family: "bar", chans: Set("x", "y", "size"), isOver: false,
    decimate: false, primariesSent: false, refusedKeys: Set()
  }

  val outSpec: M::SSpec = {
    family: "bar", chans: Set("x", "y"), isOver: false,
    decimate: false, primariesSent: false, refusedKeys: Set()
  }

  // ---- PROBE 1: a known-true fact about the specimen --------------------
  // The claim must be TRUE by the model's own definitions, independently of
  // any limb: the bar's set does not carry :size.

  val probeTrueHolds: bool = M::outsideFamily(inSpec).contains("size")

  // ---- PROBE 2: the same fact negated, over the IDENTICAL specimen ------
  // Must be FALSE. If this is green, the instrument is not evaluating the
  // expression (a fault seen before in this model) and nothing built on it is
  // evidence.

  val probeTrueNegation: bool = not(M::outsideFamily(inSpec).contains("size"))

  // ---- PROBE 3: the polarity inverted on the COMPLEMENT specimen --------
  // outSpec is inside its set, so "outside carries size" must be FALSE here.
  // Together with probe 1 this pins direction: the same predicate is true on
  // IN and false on OUT, so a constant answer cannot pass both.

  val probeComplement: bool = M::outsideFamily(outSpec).contains("size")

  // ---- PROBE 4: a limb-shaped claim, true and then negated --------------
  // lOutside's own shape, on IN: premise holds and the outcome is the channel
  // ground, so the claim is TRUE.

  val limbShapeTrue: bool =
    implies(and(M::inDomain(inSpec), M::outsideFamily(inSpec).size() > 0),
            M::outcome(inSpec) == "channel-family-mismatch")

  // Its negation must be FALSE.

  val limbShapeNegation: bool = not(limbShapeTrue)

  // ---- PROBE 5: a known-true ROW comparison -----------------------------
  // The written answer the sweep relies on: the code's ground for IN is the
  // channel mismatch, and for OUT it resolves.

  val answerIn: bool = M::outcome(inSpec) == "channel-family-mismatch"
  val answerOut: bool = M::outcome(outSpec) == "resolved"
  val answerInNegation: bool = not(M::outcome(inSpec) == "channel-family-mismatch")

  // ---- the runs ---------------------------------------------------------
  // --match='wcal[A-Z]' runs the GREEN set; --match='wcalNeg[A-Z]' the RED set.

  run wcalTrue = {
    assert(probeTrueHolds)
  }

  run wcalComplementFalse = {
    // the complement specimen must NOT satisfy probe 1's predicate
    assert(not(probeComplement))
  }

  run wcalLimbShape = {
    assert(limbShapeTrue)
  }

  run wcalAnswerIn = {
    assert(answerIn)
  }

  run wcalAnswerOut = {
    assert(answerOut)
  }

  run wnegTrue = {
    // EXPECT-RED: the negation of a known-true fact
    assert(probeTrueNegation)
  }

  run wnegLimbShape = {
    // EXPECT-RED: the negation of the limb-shaped true claim
    assert(limbShapeNegation)
  }

  run wnegAnswerIn = {
    // EXPECT-RED: the negation of the true answer
    assert(answerInNegation)
  }

}
