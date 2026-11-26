// geom.qnt - the janet-viz geometry page as a Quint specification.
//
// The margin derivation and placement rules as functions, with the worked
// example's numbers as a model-level witness.
//
// Model scale: half-milli-logical-pixels (hm), 1 hm = 1/2000 px, so
// every pinned constant and every HALF-constant (line-height/2 for the
// optically centred baselines and the rotated y-title band) is
// integral. The measured font metrics are taken at the printed 3-decimal
// precision.
//
// Points the printed page leaves inconsistent, each modelled explicitly:
//   - The worked example's printed derivation TERM for margin-left
//     (15.270) and its printed TOTAL (43.402) are inconsistent at
//     display precision (the terms sum to 43.403): the underlying
//     measured advance is sub-milli (~15.2695). The spec pins
//     maxAdvY = 30,538 hm so the derived margin and panel are exact;
//     the printed term is display-rounded. No semantic change.
//   - The printed y-title band centre 7.566 and the metrics table's
//     line-height(13) 15.133 are inconsistent at display precision
//     (centre = lh13/2 = 7.5665, which prints 7.567): the measured
//     line-height is sub-milli. The spec's centre is 15,133 hm
//     (7.5665 px), within 1 hm of the printed value.
//   - The no-legend margin-right "(12 - a small pad)": SMALL_PAD is
//     fixed at 4 px (8000 hm). Not derivable from the measured margins
//     - the only measured figure (the worked example) has the legend
//     present, so the no-legend branch never appears in a measured
//     output; the standing placeholder becomes the fixed value. The
//     value is unchanged, so the g1..g5b properties and witnesses
//     remain in force.
//   - The printed panel height 435.602 differs from the printed panel
//     bounds (457.898 - 22.297 = 435.601) by 1 milli - display rounding
//     of independently printed floats. The spec's panel bounds are
//     exact and mutually consistent.

module vizGeom {

  // ---- pinned constants (hm) ----

  pure def TICKLEN: int = 10000       // 5 px
  pure def LBLGAP: int = 8000         // 4 px
  pure def BANDGAP: int = 8000        // 4 px
  pure def TITLEGAP: int = 12000      // 6 px
  pure def LH12: int = 27938          // 13.969 px
  pure def LH13: int = 30266          // 15.133 px
  pure def LH14: int = 32594          // 16.297 px
  pure def ASC12: int = 22278         // 11.139 px
  pure def ASC13: int = 24134         // 12.067 px
  pure def ASC14: int = 25990         // 12.995 px
  pure def LEG_SWATCH: int = 24000   // 12 px
  pure def LEG_GAP: int = 16000       // 8 px
  pure def LEG_PAD: int = 24000       // 12 px
  pure def LEG_PITCHGAP: int = 12000 // 6 px

  // SMALL_PAD: 4 px - pinned, not derived (no no-legend measured figure
  // exists); the value is unchanged, so the g1..g5b properties and
  // witnesses remain in force
  pure def SMALL_PAD: int = 8000     // 4 px

  // ---- the margin derivation ----
  // a sum over PRESENT furniture; each element's absence removes its
  // term. The model derives the full-furniture margins and the
  // no-legend right margin; absence of titles removes constant terms
  // (checked as band identities, not separate derivations).

  // margin-left = max-adv(YT, 12) + label-gap + tick-length + band-gap + line-height(13)
  pure def marL(advY: int): int = advY + LBLGAP + TICKLEN + BANDGAP + LH13

  // margin-bottom = line-height(12) + label-gap + tick-length + band-gap + line-height(13)
  pure def marB: int = LH12 + LBLGAP + TICKLEN + BANDGAP + LH13

  // margin-top = line-height(14) + title-gap
  pure def marT: int = LH14 + TITLEGAP

  // margin-right, legend present: legend-pad + legend-swatch + legend-gap + max-adv(L, 12)
  // margin-right, no legend: 12 px minus a small pad
  pure def marR(advL: int, legend: bool): int =
    if (legend) { LEG_PAD + LEG_SWATCH + LEG_GAP + advL } else { LEG_PAD - SMALL_PAD }

  pure def panelOf(w: int, h: int, ml: int, mt: int, mr: int, mb: int): { left: int, top: int, right: int, bottom: int } =
    { left: ml, top: mt, right: w - mr, bottom: h - mb }

  // ---- the placement rules ----

  // x tick labels: centred under the tick; baseline = panel-bottom +
  // tick-length + label-gap + ascent(12)
  pure def xTickLblBase(pb: int): int = pb + TICKLEN + LBLGAP + ASC12

  // y tick labels: right-aligned to panel-left - tick-length - label-gap
  // (the advance is resolved into the anchor by the producer; this is
  // the right edge of the label band)
  pure def yTickLblRight(pl: int): int = pl - TICKLEN - LBLGAP

  // y tick label baseline: tick-y + ascent(12) - line-height(12)/2
  // (optically centred on the tick)
  pure def yTickLblBase(ty: int): int = ty + ASC12 - 13969

  // x axis title: baseline = panel-bottom + tick-length + label-gap +
  // line-height(12) + band-gap + ascent(13)
  pure def xTitleBase(pb: int): int = pb + TICKLEN + LBLGAP + LH12 + BANDGAP + ASC13

  // y axis title: ROTATED -90. The composed placement: the centre of
  // the title band - x = panel-left - tick-length - label-gap -
  // max-adv(YT,12) - band-gap - line-height(13)/2, y = the panel's
  // vertical centre - with the rotation carried by the op.
  pure def yTitleCentreX(ml: int, advY: int): int =
    ml - TICKLEN - LBLGAP - advY - BANDGAP - 15133

  pure def yTitleCentreY(pt: int, pb: int): int = (pt + pb) / 2

  // figure title: baseline = ascent(14) from the canvas top
  pure def figTitleBase: int = ASC14

  // legend: entry pitch = line-height(12) + legend-pitch-gap;
  // label baseline = entry-y + ascent(12)
  pure def legendPitch: int = LH12 + LEG_PITCHGAP
  pure def legendLblBase(entryY: int): int = entryY + ASC12

  // ---- the state machine ----
  // measured advances and panel spans are symbolic; the canvas is
  // CONSTRUCTED so the panel fits (the geometry contract).

  var advY: int   // max measured advance of the y tick labels @12
  var advL: int   // max measured advance of the legend labels @12
  var legend: bool
  var w: int
  var h: int
  var ml: int
  var mt: int
  var mr: int
  var mb: int
  var pl: int
  var pt: int
  var pr: int
  var pb: int

  action init =
    nondet ay = 10000.to(60000).oneOf();
    nondet al = 10000.to(100000).oneOf();
    nondet lg = Set(true, false).oneOf();
    nondet spanX = 200000.to(600000).oneOf();
    nondet spanY = 200000.to(600000).oneOf();
    all {
      advY' = ay,
      advL' = al,
      legend' = lg,
      ml' = marL(ay),
      mt' = marT,
      mr' = marR(al, lg),
      mb' = marB,
      w' = marL(ay) + marR(al, lg) + spanX,
      h' = marT + marB + spanY,
      pl' = marL(ay),
      pt' = marT,
      pr' = marL(ay) + spanX,
      pb' = marT + spanY,
    }

  action stutter = all {
    advY' = advY, advL' = advL, legend' = legend,
    w' = w, h' = h, ml' = ml, mt' = mt, mr' = mr, mb' = mb,
    pl' = pl, pt' = pt, pr' = pr, pb' = pb,
  }

  // ---- the properties ----

  // G1: the panel is strictly inside the canvas with positive extent;
  // the margins are non-negative
  val g1 = 0 <= ml and ml < pr and pr <= w and 0 <= mt and mt < pb and pb <= h

  // G2: every furniture baseline lands in its margin band - inside
  // the canvas, outside the panel
  val g2 = and(
    pb < xTickLblBase(pb) and xTickLblBase(pb) < h,             // x tick labels: the bottom band
    pb < xTitleBase(pb) and xTitleBase(pb) < h,                 // x axis title: the bottom band
    0 <= yTickLblRight(pl) - advY,                              // y tick labels: the left band
    0 <= figTitleBase and figTitleBase <= mt,                   // figure title: the top band
  )

  // G3: the y-title band sits entirely left of the y tick labels
  val g3 = {
    val cx = yTitleCentreX(ml, advY)
    cx - 15133 >= 0 and cx + 15133 <= yTickLblRight(pl) - advY - BANDGAP
  }

  // G4 (theorem): the y-title band centre is INDEPENDENT of the
  // measured advance - the band's width is exactly line-height(13),
  // so its centre is line-height(13)/2 from the canvas left
  val g4 = yTitleCentreX(ml, advY) == 15133

  // G5: the legend fits its margin band: the legend block's width is
  // covered by margin-right, the pitch is the pinned constant
  val g5 = implies(legend, LEG_PAD + LEG_SWATCH + LEG_GAP <= mr)
  val g5b = legendPitch == LH12 + LEG_PITCHGAP

  // ---- witnesses: the worked example ----
  // 800x500 canvas, x "duration_ms" ticks {0,200,400,600,800}
  // (Wilkinson for [0,800], m=5), y "errors" ticks {0..10},
  // colour host (3 series), error +/- 0.5, title present, legend
  // present. maxAdvY = 30,538 hm (15.2695 px), maxAdvL =
  // 91,008 hm (45.504 px, "host-01").

  pure def EX_W: int = 1600000        // 800 px
  pure def EX_H: int = 1000000        // 500 px
  pure def EX_ADVY: int = 30538
  pure def EX_ADVL: int = 91008

  run witnessMargins = {
    // margins: 43.402 / 42.102 / 22.297 / 77.504 px - EXACT
    assert(marL(EX_ADVY) == 86804)        // 43.402
    .then(assert(marB == 84204))          // 42.102
    .then(assert(marT == 44594))          // 22.297
    .then(assert(marR(EX_ADVL, true) == 155008))  // 77.504
  }

  run witnessPanel = {
    // panel [43.402 22.297 722.496 457.898] px - EXACT
    val p = panelOf(EX_W, EX_H, marL(EX_ADVY), marT, marR(EX_ADVL, true), marB)
    assert(p.left == 86804 and p.top == 44594)
    .then(assert(p.right == 1444992 and p.bottom == 915796))
  }

  run witnessYTitle = {
    // y-title band centre: 7.5665 px (printed 7.566, within 1 hm);
    // panel vertical centre: 240.0975 px (printed 240.098)
    val cx = yTitleCentreX(marL(EX_ADVY), EX_ADVY)
    val cy = yTitleCentreY(44594, 915796)
    assert(cx == 15133 and cx >= 15131 and cx <= 15134)
    .then(assert(cy == 480195 and cy >= 480194 and cy <= 480196))
  }

  run witnessPlacement = {
    // baselines against the worked example's panel
    assert(xTickLblBase(915796) == 956074)          // 478.037 px
    .then(assert(xTitleBase(915796) == 993868))     // 496.934 px
    .then(assert(yTickLblBase(44594) == 44594 + 22278 - 13969))
    .then(assert(figTitleBase == 25990))            // 12.995 px
    .then(assert(yTickLblRight(86804) == 68804))    // 34.402 px
  }

  // ---- witnesses: the derivation is a function (determinism) ----

  run witnessStable = {
    assert(marL(EX_ADVY) == marL(EX_ADVY))
    .then(assert(panelOf(EX_W, EX_H, marL(EX_ADVY), marT, marR(EX_ADVL, true), marB)
                 == panelOf(EX_W, EX_H, marL(EX_ADVY), marT, marR(EX_ADVL, true), marB)))
  }
}
