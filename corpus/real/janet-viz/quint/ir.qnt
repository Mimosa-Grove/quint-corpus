// ir.qnt - the janet-viz display-list IR as a Quint specification.
//
// The op enumeration with properties P1-P6. The op set is SIGNED: where
// this spec needs an interpretation or finds a tension, it models that
// reading explicitly instead of editing the enumeration.
//
// Model scale: half-milli-logical-pixels (hm), 1 hm = 1/2000 px, so that
// every pinned geometry constant (line-heights, halves) stays integral.
// Colours are modelled as small ints; P1 checks the u32 band abstractly.
// Degrees (not radians) for the text rotation field.
//
// Points the enumeration leaves open, each modelled explicitly:
//   - P2's literal text ("every tick coordinate lies within the
//     panel") conflicts with the outward tick placement (5 px out from
//     the panel edge). Modelled: marks/grid/error within the panel;
//     ticks within the panel expanded by the tick length; text anchors
//     within the canvas. Interpretation, not an edit.
//   - The mark coordinate boundedness delegation: the IR carries
//     panel-space coordinates; the scale contract (data -> panel
//     offsets within the panel span) is upstream. The spec assumes
//     offsets within the span and verifies the emitter's translate
//     stays in-panel.
//   - Legend emission is not modelled (P5 is about mark groups; the
//     legend channel rank is reserved). Non-goal, not a refutation.
//   - The op-count arithmetic. Three different sums for one figure (20,
//     21, 22) were in play and none of them was the emitter's. The
//     single arithmetic, from the emitter path for three groups WITH
//     intervals:
//       grid 1 + marks 9 (3 groups x fill, stroke, error)
//       + furniture 9 (2 tick ops, 4 tick labels, 2 axis titles,
//         1 figure title) = 19 ops in `ops`.
//     The canvas header is `header`, not an op; the legend rank is
//     reserved and not drawn. MAXOPS 22 is therefore a FITTED bound, not
//     a derived count: it stands 3 above the measured shape, and
//     recR1's `MAXOPS == e.ops.length() + 3` is the only claim made
//     about the gap. The bound stays as it was; changing it in the same
//     change would hide which number was wrong. The earlier recorded
//     cause (the six-arm append ladder dropping the last group's op) was
//     real and is fixed: `catOps` is exact. Witnesses no longer pin
//     `errors: false`.
//   The empty-figure domain value is a NAMED PARAMETER with a standing
//   placeholder, never pinned (EMPTY_DOM below) - the IR's shape does
//   not depend on it.

module vizIR {

  // ---- constants (hm) ----

  pure def TICKLEN: int = 10000      // 5 px, outward from the panel edge
  pure def LBLGAP: int = 8000        // label-gap 4 px
  pure def BANDGAP: int = 8000       // band-gap 4 px
  pure def LH12: int = 27938         // line-height(12) = 13.969 px
  pure def LH13: int = 30266         // line-height(13) = 15.133 px
  pure def ASC12: int = 22278        // ascent(12) = 11.139 px
  pure def ASC13: int = 24134        // ascent(13) = 12.067 px
  pure def ASC14: int = 25990        // ascent(14) = 12.995 px
  pure def SZ_TICK: int = 24000     // 12 px
  pure def SZ_AXIS: int = 26000      // 13 px
  pure def SZ_TITLE: int = 28000     // 14 px
  pure def U32MAX: int = 4294967295
  // constant op-count bound, FITTED. The emitter's three-group figure with
  // intervals is 19 ops. 22 = 19 + 3; the +3 is not the header (that is
  // `header`, modelled separately) and not the legend (one reserved rank),
  // and is not decomposed here. recR1 pins exactly that relation and
  // nothing more.
  pure def MAXOPS: int = 22
  pure def MAXXY: int = 7         // constant xy index bound (max 8 xy pairs, the grid op)

  // named parameter: the empty-figure domain VALUE is a standing
  // placeholder [-1, +1] px, the same expansion the degenerate-domain
  // rule uses. Never pinned here.
  pure def EMPTY_DOM_LO: int = -2000
  pure def EMPTY_DOM_HI: int = 2000

  // ---- types ----

  type Panel = { left: int, top: int, right: int, bottom: int }

  // one flat, stateless op record: every field the op needs is IN the op.
  // `chan` is a spec-model field: the producer channel that emitted the op
  // (the producer ordering P3 is stated over it); it is not an IR field.
  type Op = {
    kind: str,     // one of the 7 body ops
    chan: str,     // "grid" | "fill" | "stroke" | "error" | "tick" | "ticklabel" | "axistitle" | "figtitle"
    group: str,    // mark group; "" for furniture ops
    xy: List[int], // interleaved coordinates / the text anchor pair
    colour: int,   // modelled u32
    width: int,    // stroke width
    size: int,     // font size / mark size
    text: str,     // payload iff kind == "text"
    rot: int,      // 0 | -90 (degrees)
  }

  // the single leading header record (canvas-init)
  type Header = { w: int, h: int, panel: Panel, background: int }

  type OpList = { header: Header, ops: List[Op] }

  // the resolved-spec slice the emitter consumes. The panel is CONCRETE
  // in this spec (panel variation is the geometry target's job); data
  // offsets, tick positions and the measured advance are symbolic.
  type FigSpec = {
    w: int, h: int,
    panel: Panel,
    grid: bool,
    groups: List[str],    // first-appearance order: [], ["primary"], ["primary","secondary"]
    offs: List[int],      // data x offsets within the panel span (upstream scale contract)
    markY: int,           // the marks' panel-space y
    errors: bool,
    hasAxisTitles: bool,
    hasTitle: bool,
    ticksX: List[int],    // panel-space tick x positions (Wilkinson output mapped upstream)
    ticksY: List[int],
    maxAdvY: int,         // maximum measured advance of the y tick labels (hm)
  }

  // ---- the model canvas (one concrete panel; 400 x 300 px) ----

  pure def PANEL: Panel = { left: 160000, top: 100000, right: 760000, bottom: 520000 }
  pure def W: int = 800000
  pure def H: int = 600000
  pure def SPAN: int = 600000            // panel width, the offsets' bound
  pure def PCX: int = 460000              // panel centre x (concrete: left + span/2)
  pure def PCY: int = 310000              // panel vertical centre

  // ---- small list helpers (no list map/fold in quint 0.33) ----

  pure def cat2(a: List[int], b: List[int]): List[int] =
    if (b.length() == 0) { a }
    else { if (b.length() == 1) { a.append(b[0]) } else { a.append(b[0]).append(b[1]) } }

  // ---- the emitter (the producer layers, one pinned order) ----
  // `shift` is the colour-mutation parameter of the P4 mutant family:
  // emit(s, 0) is the reference; emit(s, 1) is the mutated list.

  pure def op(kind: str, chan: str, group: str, xy: List[int], colour: int, width: int, sz: int, text: str, rot: int): Op =
    { kind: kind, chan: chan, group: group, xy: xy, colour: colour, width: width, size: sz, text: text, rot: rot }

  // mark coordinates: the translate of in-span offsets by the panel
  // left edge (offsets within the span translate inside the panel -
  // the upstream scale contract's half of boundedness)
  pure def markXy(s: FigSpec): List[int] =
    if (s.offs.length() == 0) { [] }
    else { if (s.offs.length() == 1) { [s.panel.left + s.offs[0], s.markY] } else { [s.panel.left + s.offs[0], s.markY, s.panel.left + s.offs[1], s.markY] } }

  pure def errXy(s: FigSpec): List[int] =
    if (s.offs.length() == 0) { [] }
    else { if (s.offs.length() == 1)
             { [s.panel.left + s.offs[0], s.markY - 20000, s.panel.left + s.offs[0], s.markY + 20000] }
             else { [s.panel.left + s.offs[0], s.markY - 20000, s.panel.left + s.offs[0], s.markY + 20000,
                     s.panel.left + s.offs[1], s.markY - 20000, s.panel.left + s.offs[1], s.markY + 20000] } }

  // one group's mark block: filled, then stroked, then error-bars riding
  // the group
  pure def groupOps(s: FigSpec, g: str, t: int): List[Op] = {
    val circ = op("fill-circles", "fill", g, markXy(s), 10 + t, 0, 6000, "", 0)
    val poly = op("stroke-polylines", "stroke", g, markXy(s), 10 + t, 2000, 0, "", 0)
    if (s.errors) {
      val err = op("error-bars", "error", g, errXy(s), 10 + t, 3000, 0, "", 0)
      [circ, poly, err]
    } else {
      [circ, poly]
    }
  }

  // concat, EXACT for every block the model can produce. The former ladder
  // stopped at six elements and silently truncated the last group's block:
  // `markOps` wraps `catOps(catOps(g0, g1), g2)`, the inner call is exact,
  // and the outer one dropped `g2`'s third op. Flat branches, one append
  // per element, so no call nests two appends and no level can truncate.
  // The longest block the emitter produces is 3 (a group with intervals);
  // 9 leaves headroom without a decaying arity ladder.
  pure def catOps(a: List[Op], b: List[Op]): List[Op] = {
    val a1 = if (b.length() <= 0) { a } else { a.append(b[0]) }
    val a2 = if (b.length() <= 1) { a1 } else { a1.append(b[1]) }
    val a3 = if (b.length() <= 2) { a2 } else { a2.append(b[2]) }
    val a4 = if (b.length() <= 3) { a3 } else { a3.append(b[3]) }
    val a5 = if (b.length() <= 4) { a4 } else { a4.append(b[4]) }
    val a6 = if (b.length() <= 5) { a5 } else { a5.append(b[5]) }
    val a7 = if (b.length() <= 6) { a6 } else { a6.append(b[6]) }
    val a8 = if (b.length() <= 7) { a7 } else { a7.append(b[7]) }
    if (b.length() <= 8) { a8 } else { a8.append(b[8]) }
  }

  // grid: one stroke-segments op carrying every grid line, full panel span
  // at every tick position; grid and ticks are the same primitive
  pure def gridXy(s: FigSpec): List[int] =
    [s.ticksX[0], s.panel.top, s.ticksX[0], s.panel.bottom,
     s.ticksX[1], s.panel.top, s.ticksX[1], s.panel.bottom,
     s.panel.left, s.ticksY[0], s.panel.right, s.ticksY[0],
     s.panel.left, s.ticksY[1], s.panel.right, s.ticksY[1]]

  // furniture placement constants: the producer resolves the placement
  // rules into literals
  pure def XLBL_BASE(s: FigSpec): int = s.panel.bottom + TICKLEN + LBLGAP + ASC12
  pure def YLBL_ANCHOR_X(s: FigSpec): int = s.panel.left - TICKLEN - LBLGAP - s.maxAdvY
  pure def YLBL_BASE(ty: int): int = ty + ASC12 - 13969        // ascent(12) - line-height(12)/2
  pure def XTITLE_BASE(s: FigSpec): int = s.panel.bottom + TICKLEN + LBLGAP + LH12 + BANDGAP + ASC13
  pure def YTITLE_ANCHOR_X(s: FigSpec): int = s.panel.left - TICKLEN - LBLGAP - s.maxAdvY - BANDGAP - 15133  // line-height(13)/2

  // A group's mark block, extended over the group-index list the model keeps
  // in `groups`, so three names are three blocks.
  pure def markOps(s: FigSpec, t: int): List[Op] =
    if (s.groups.length() == 0) { [] }
    else if (s.groups.length() == 1) { groupOps(s, s.groups[0], t) }
    else if (s.groups.length() == 2) { catOps(groupOps(s, s.groups[0], t), groupOps(s, s.groups[1], t)) }
    else { catOps(catOps(groupOps(s, s.groups[0], t), groupOps(s, s.groups[1], t)), groupOps(s, s.groups[2], t)) }

  pure def emit(s: FigSpec, t: int): OpList = {
    val gridOp = op("stroke-segments", "grid", "", gridXy(s), 2 + t, 2000, 0, "", 0)
    val tickX = op("stroke-segments", "tick", "",
                   [s.ticksX[0], s.panel.bottom, s.ticksX[0], s.panel.bottom + TICKLEN,
                    s.ticksX[1], s.panel.bottom, s.ticksX[1], s.panel.bottom + TICKLEN], 1 + t, 2000, 0, "", 0)
    val tickY = op("stroke-segments", "tick", "",
                   [s.panel.left - TICKLEN, s.ticksY[0], s.panel.left, s.ticksY[0],
                    s.panel.left - TICKLEN, s.ticksY[1], s.panel.left, s.ticksY[1]], 1 + t, 2000, 0, "", 0)
    val lblX1 = op("text", "ticklabel", "", [s.ticksX[0], XLBL_BASE(s)], 1 + t, 0, SZ_TICK, "x1", 0)
    val lblX2 = op("text", "ticklabel", "", [s.ticksX[1], XLBL_BASE(s)], 1 + t, 0, SZ_TICK, "x2", 0)
    val lblY1 = op("text", "ticklabel", "", [YLBL_ANCHOR_X(s), YLBL_BASE(s.ticksY[0])], 1 + t, 0, SZ_TICK, "y1", 0)
    val lblY2 = op("text", "ticklabel", "", [YLBL_ANCHOR_X(s), YLBL_BASE(s.ticksY[1])], 1 + t, 0, SZ_TICK, "y2", 0)
    val xTitle = op("text", "axistitle", "", [PCX, XTITLE_BASE(s)], 1 + t, 0, SZ_AXIS, "xt", 0)
    val yTitle = op("text", "axistitle", "", [YTITLE_ANCHOR_X(s), PCY], 1 + t, 0, SZ_AXIS, "yt", -90)
    val figTitle = op("text", "figtitle", "", [PCX, ASC14], 1 + t, 0, SZ_TITLE, "ft", 0)
    // assembly in the ONE pinned producer order:
    // grid -> marks (per group, filled/stroked/error) -> furniture
    // (ticks, tick labels, axis titles, figure title; legend rank
    // reserved), with the canvas header at index 0
    val base = if (s.grid) { [gridOp] } else { [] }
    // grid -> marks -> ticks -> labels -> axis titles -> figure title: the
    // ONE pinned producer order, with the marks APPENDED before any
    // furniture so the list the witnesses index is the list the emitter
    // emits (the OLD form appended two tick ops before the marks, so index 1
    // was a tick on every figure - ordering cells read positions that did not
    // exist where the order said).
    val afterMarks = catOps(catOps(base, markOps(s, t)), [tickX])
    val afterTicks = afterMarks.append(tickY)
    val afterLbls = afterTicks.append(lblX1).append(lblX2).append(lblY1).append(lblY2)
    val afterTitles = if (s.hasAxisTitles) { afterLbls.append(xTitle).append(yTitle) } else { afterLbls }
    val opsFinal = if (s.hasTitle) { afterTitles.append(figTitle) } else { afterTitles }
    val hdr = { w: s.w, h: s.h, panel: s.panel, background: 0 + t }
    { header: hdr, ops: opsFinal }
  }

  // ---- the properties ----

  // P1 totality: every field of every op present (record construction
  // forces presence; the type system is the proof) with a value of its
  // type domain: colour in the u32 band, rotation in {0, -90}, text
  // carried iff kind is text, kind in the op set, xy even.
  pure def kinds: Set[str] =
    Set("fill-circles", "stroke-polylines", "fill-rects", "fill-polygon",
        "stroke-segments", "error-bars", "text")

  pure def p1op(o: Op): bool =
    o.colour >= 0 and o.colour <= U32MAX
    and (o.rot == 0 or o.rot == -90)
    and (kinds.contains(o.kind))
    and implies(o.kind == "text", o.text != "" and o.xy.length() == 2)
    and implies(o.kind != "text", o.text == "")
    and (o.xy.length() % 2 == 0)

  // The domain is the list's TRUE length, not `0.to(MAXOPS - 1)`: a guard
  // against a constant the list is free to exceed turns the limb silent for
  // every op past the bound. `0.to(-1)` is the empty range, so the empty
  // list still passes without a separate non-empty guard.
  val p1 = 0.to(MAXOPS - 1).forall(j => implies(j < out.ops.length(), p1op(out.ops[j])))

  // P1's length limb. The totality limbs iterate the list's own length;
  // this is the only limb that says the list cannot exceed MAXOPS. The two
  // are a pair: without this one the restated domains merely move the
  // blindness inside the bound.
  val maxOps = out.ops.length() <= MAXOPS

  // ---- P2 boundedness (with the outward tick band) ----

  pure def inPanel(p: Panel, v: int): bool = p.left <= v and v <= p.right

  // interleaved xy: even indices are x, odd indices are y; guarded
  // constant ranges (Apalache cannot encode 0.to(symbolic - 1))
  pure def xOK(o: Op, lo: int, hi: int): bool =
    0.to(MAXXY).forall(i => implies(i < o.xy.length() / 2, lo <= o.xy[i * 2] and o.xy[i * 2] <= hi))
  pure def yOK(o: Op, lo: int, hi: int): bool =
    0.to(MAXXY).forall(i => implies(i < o.xy.length() / 2, lo <= o.xy[i * 2 + 1] and o.xy[i * 2 + 1] <= hi))

  pure def p2op(l: OpList, j: int): bool = {
    val o = l.ops[j]
    if (o.chan == "grid") {
      xOK(o, l.header.panel.left, l.header.panel.right)
      and yOK(o, l.header.panel.top, l.header.panel.bottom)
    } else {
      if (o.chan == "tick") {
        // x ticks run outward from the bottom edge, y ticks from the
        // left edge (the outward tick band)
        xOK(o, l.header.panel.left - TICKLEN, l.header.panel.right)
        and yOK(o, l.header.panel.top, l.header.panel.bottom + TICKLEN)
      } else {
        if (or(o.chan == "fill", o.chan == "stroke", o.chan == "error")) {
          xOK(o, l.header.panel.left, l.header.panel.right)
          and yOK(o, l.header.panel.top, l.header.panel.bottom)
        } else {
          // text: the anchor lies within the canvas (furniture text
          // legitimately occupies the margin bands)
          o.xy.length() == 2 and 0 <= o.xy[0] and o.xy[0] <= l.header.w
          and 0 <= o.xy[1] and o.xy[1] <= l.header.h
        }
      }
    }
  }

  // mark-channel ops additionally carry y within the panel
  pure def p2markY(l: OpList, j: int): bool = {
    val o = l.ops[j]
    implies(or(o.chan == "fill", o.chan == "stroke", o.chan == "error"),
            yOK(o, l.header.panel.top, l.header.panel.bottom))
  }

  // P2, verify form: stated over the resolved spec's own values (the
  // upstream scale contract + the furniture constants), not over the
  // emitted list - Apalache encodes it as a small linear formula. The
  // list-level realisation (p2op/p2markY over out.ops) is checked by
  // the witnesses on concrete figures; the two layers are the
  // janet-stats pattern (spec verifies the contract, tests execute
  // the emission).
  val p2 = and(
    // marks and their error extents within the panel
    implies(spec.groups.length() > 0,
      0 <= spec.offs[0] and spec.offs[0] <= SPAN
      and 0 <= spec.offs[1] and spec.offs[1] <= SPAN
      and spec.panel.top + 20000 <= spec.markY and spec.markY + 20000 <= spec.panel.bottom),
    // grid and tick positions within the panel (Wilkinson mapped)
    spec.panel.left <= spec.ticksX[0] and spec.ticksX[0] <= spec.panel.right,
    spec.panel.left <= spec.ticksX[1] and spec.ticksX[1] <= spec.panel.right,
    spec.panel.top <= spec.ticksY[0] and spec.ticksY[0] <= spec.panel.bottom,
    spec.panel.top <= spec.ticksY[1] and spec.ticksY[1] <= spec.panel.bottom,
    // text anchors within the canvas (furniture occupies margin bands)
    spec.panel.bottom + TICKLEN + LBLGAP + ASC12 < spec.h,
    0 <= spec.panel.left - TICKLEN - LBLGAP - spec.maxAdvY,
    0 <= spec.panel.left - TICKLEN - LBLGAP - spec.maxAdvY - BANDGAP - 15133,
  )

  // ---- P3 ordering: the producer order, coarse rank then fine key ----
  // coarse: grid(0) < marks(1) < furniture(2..); fine: within marks,
  // (group first-appearance index, fill < stroke < error) lexicographic;
  // within furniture: tick < ticklabel < axistitle < figtitle < legend.

  pure def coarse(chan: str): int =
    if (chan == "grid") { 0 }
    else { if (or(chan == "fill", chan == "stroke", chan == "error")) { 1 } else { 2 } }

  // The group alphabet is CLOSED at three names. The former `else { 3 }`
  // was a band no modelled figure emits and no limb reads: a mis-named
  // third group landed on a distinct key and P3 could not see the swap.
  // `-1` is out of the fill/stroke/error key bands, so an unknown name
  // makes the ordering limb false wherever it appears.
  pure def gAlphabet: Set[str] = Set("primary", "secondary", "tertiary")

  pure def gIdx(g: str): int =
    if (g == "primary") { 0 }
    else { if (g == "secondary") { 1 } else { if (g == "tertiary") { 2 } else { -1 } } }

  pure def key(o: Op): int =
    if (o.chan == "grid") { 0 }
    else { if (o.chan == "fill") { 100 + gIdx(o.group) * 10 }
           else { if (o.chan == "stroke") { 100 + gIdx(o.group) * 10 + 1 }
                  else { if (o.chan == "error") { 100 + gIdx(o.group) * 10 + 2 }
                         else { if (o.chan == "tick") { 200 }
                                else { if (o.chan == "ticklabel") { 201 }
                                       else { if (o.chan == "axistitle") { 202 }
                                              else { if (o.chan == "figtitle") { 203 } else { 204 } } } } } } } }

  val p3 = 0.to(out.ops.length() - 2).forall(i => key(out.ops[i]) <= key(out.ops[i + 1]))

  // ---- P4 implementation equivalence as list equality ----

  pure def eqv(a: OpList, b: OpList): bool =
    a.header == b.header and a.ops.length() == b.ops.length()
    and 0.to(a.ops.length() - 1).forall(i => a.ops[i] == b.ops[i])

  // re-emission of the same resolved spec is the identical list
  val p4 = eqv(out, emit(spec, 0))

  // the mutant family: one mutated colour field on every op. Refutable:
  // emit(s, 1) != emit(s, 0) whenever the list has an op.
  val mutantEq = eqv(out, emit(spec, 1))
  val p4MutantRefuted = implies(out.ops.length() > 0, not(mutantEq))

  // ---- P5 shared-scale multi-group ----

  // P5 states the pair over a NON-EMPTY list: `exists(implies(...))` alone is
  // true on an empty list (recR4), so a limb written that way passes on an
  // emitter that emitted nothing - the vacuity recR4 witnesses. The
  // non-emptiness limb is what makes the two group limbs constrain anything.
  val p5 = implies(spec.groups.length() == 2,
                   out.ops.length() > 0
                   and 0.to(out.ops.length() - 1).exists(j => out.ops[j].group == "primary")
                   and 0.to(out.ops.length() - 1).exists(j => out.ops[j].group == "secondary"))

  // ---- P6 degenerate inputs ----

  // the empty figure: a legal list with NO mark ops (grid + furniture only)
  val p6empty = implies(spec.groups.length() == 0,
                        0.to(out.ops.length() - 1).forall(j =>
                          not(or(out.ops[j].chan == "fill", out.ops[j].chan == "stroke", out.ops[j].chan == "error"))))

  // ---- the state machine ----

  var spec: FigSpec
  var out: OpList

  pure def mkSpec(nGroups: int, o1: int, o2: int, my: int, tx1: int, tx2: int, ty1: int, ty2: int, adv: int, g: bool, e: bool, at: bool, ft: bool): FigSpec = {
    w: W, h: H, panel: PANEL, grid: g,
    groups: if (nGroups == 0) { [] } else { if (nGroups == 1) { ["primary"] } else { ["primary", "secondary"] } },
    offs: if (nGroups == 0) { [] } else { [o1, o2] },
    markY: my, errors: e, hasAxisTitles: at, hasTitle: ft,
    ticksX: [tx1, tx2], ticksY: [ty1, ty2], maxAdvY: adv,
  }

  // init fixes the furniture flags (grid, errors, axis titles, figure
  // title all PRESENT): a verify-scale simplification that keeps every
  // property live (P6-empty arrives via nGroups = 0); the flags only
  // multiply emission case paths. The witnesses keep flag variety.
  action init =
    nondet nGroups = Set(0, 1, 2).oneOf();
    nondet o1 = 0.to(SPAN).oneOf();
    nondet o2 = 0.to(SPAN).oneOf();
    nondet my = 120000.to(500000).oneOf();   // mark y with the error band inside the panel
    nondet tx1 = 160000.to(760000).oneOf();
    nondet tx2 = 160000.to(760000).oneOf();
    nondet ty1 = 100000.to(520000).oneOf();
    nondet ty2 = 100000.to(520000).oneOf();
    nondet adv = 30000.to(60000).oneOf();
    all {
    spec' = mkSpec(nGroups, o1, o2, my, tx1, tx2, ty1, ty2, adv, true, true, true, true),
    out' = emit(mkSpec(nGroups, o1, o2, my, tx1, tx2, ty1, ty2, adv, true, true, true, true), 0),
    }

  // the re-emission step: same resolved spec, a fresh emission (P4)
  action step = all {
    spec' = spec,
    out' = emit(spec, 0),
  }

  // the stutter step: for verifying the P1/P2/P3/P5/P6 cluster over
  // the init emission without a second unrolling of the emitter
  action stutter = all {
    spec' = spec,
    out' = out,
  }

  // ---- witnesses ----

  pure def listP1P2(l: OpList): bool =
    0.to(l.ops.length() - 1).forall(j => p1op(l.ops[j]) and p2op(l, j) and p2markY(l, j))
  // the empty-figure witness: ticks from the EMPTY_DOM placeholder
  // domain (a named parameter) mapped over the span
  // Every figure below names all THIRTEEN fields. Positional construction is
  // silent: the figures used to list twelve, `grid` landed on `groups`, and
  // every later flag shifted one slot - the three-group figure emitted its
  // mark blocks with `errors` off and no axis titles, and `witnessThreeGroup`
  // still passed, because its limbs only ask that tertiary's fill and stroke
  // EXIST.
  pure def emptyFig(): FigSpec = {
    w: W, h: H, panel: PANEL, grid: true, groups: [], offs: [], markY: 310000,
    errors: false, hasAxisTitles: true, hasTitle: true,
    ticksX: [160000 + 200000, 160000 + 400000],      // EMPTY_DOM_LO..HI over the span, placeholder
    ticksY: [100000 + 140000, 100000 + 280000],
    maxAdvY: 40000,
  }

  // one group: the vacuous-pair reading's control. The emitter has no pair
  // guard, so this figure is where a pair limb without a guard would pass
  // vacuously - and where the guarded form is seen to be non-vacuous.
  pure def oneGroupFig(): FigSpec = {
    w: W, h: H, panel: PANEL, grid: true, groups: ["primary"],
    offs: [300000, 300000], markY: 310000,
    errors: true, hasAxisTitles: true, hasTitle: true,
    ticksX: [160000, 460000], ticksY: [220000, 400000],
    maxAdvY: 40000,
  }

  // the degenerate-data witness: every point equal; the domain was
  // expanded upstream (EMPTY_DOM [v-1, v+1]); the marks ride the same
  // op set
  pure def degenerateFig(): FigSpec = {
    w: W, h: H, panel: PANEL, grid: true, groups: ["primary"],
    offs: [300000, 300000], markY: 310000,
    errors: true, hasAxisTitles: true, hasTitle: true,
    ticksX: [160000, 460000], ticksY: [220000, 400000],
    maxAdvY: 40000,
  }

  pure def twoGroupFig(): FigSpec = {
    w: W, h: H, panel: PANEL, grid: true, groups: ["primary", "secondary"],
    offs: [100000, 500000], markY: 310000,
    errors: true, hasAxisTitles: true, hasTitle: true,
    ticksX: [160000, 760000], ticksY: [100000, 520000],
    maxAdvY: 40000,
  }

  // Three groups: the emission must carry ONE mark block per group, in
  // :group-order. The two-group witness cannot tell a per-group emission
  // from a fixed pair; a third group makes the difference observable.
  // Intervals ON: the witness used to pin `errors: false`, and the pin was
  // the only reason the 22-op shape was invisible - the interval figure is
  // the one that reaches MAXOPS, so a witness that cannot carry intervals
  // cannot see the bound.
  pure def threeGroupFig(): FigSpec = {
    w: W, h: H, panel: PANEL, grid: true, groups: ["primary", "secondary", "tertiary"],
    offs: [100000, 300000, 500000], markY: 310000,
    errors: true, hasAxisTitles: true, hasTitle: true,
    ticksX: [160000, 760000], ticksY: [100000, 520000],
    maxAdvY: 40000,
  }

  run witnessP6empty = {
    val e = emit(emptyFig, 0)
    assert(0.to(e.ops.length() - 1).forall(j => not(or(e.ops[j].chan == "fill", e.ops[j].chan == "stroke", e.ops[j].chan == "error"))))
    .then(assert(e.ops.length() > 0))
  }

  run witnessP6degenerate = {
    val e = emit(degenerateFig, 0)
    assert(0.to(e.ops.length() - 1).exists(j => e.ops[j].chan == "fill" and e.ops[j].group == "primary"))
    .then(assert(listP1P2(e)))
  }

  run witnessP5 = {
    val e = emit(twoGroupFig, 0)
    assert(0.to(e.ops.length() - 1).exists(j => e.ops[j].group == "primary" and e.ops[j].chan == "fill"))
    .then(assert(0.to(e.ops.length() - 1).exists(j => e.ops[j].group == "secondary" and e.ops[j].chan == "fill"))
    .then(assert(e.header.panel == PANEL)))
  }

  run witnessP4mutantRefuted = {
    val a = emit(twoGroupFig, 0)
    val b = emit(twoGroupFig, 1)
    assert(a.ops.length() > 0)
    .then(assert(not(eqv(a, b))))
  }

  run witnessP4stable = {
    val a = emit(twoGroupFig, 0)
    val b = emit(twoGroupFig, 0)
    assert(eqv(a, b))
  }

  run witnessP3order = {
    val e = emit(twoGroupFig, 0)
    assert(0.to(e.ops.length() - 2).forall(i => key(e.ops[i]) <= key(e.ops[i + 1])))
  }

  // three groups emit three mark blocks, each under its OWN group name
  // (primary, secondary, tertiary), in :group-order, and each carries its
  // interval op - the fourth limb: the figure has intervals, so a witness
  // that stops at fill+stroke does not cover the emission it claims to
  // witness.
  // Fails when: a block is missing or truncated (a capped concat), a group's
  // name is wrong (a hardcoded pair), or the interval op is dropped.
  run witnessThreeGroup = {
    val e = emit(threeGroupFig, 0)
    assert(0.to(e.ops.length() - 1).exists(j => e.ops[j].group == "primary" and e.ops[j].chan == "fill"))
    .then(assert(0.to(e.ops.length() - 1).exists(j => e.ops[j].group == "secondary" and e.ops[j].chan == "fill")))
    .then(assert(0.to(e.ops.length() - 1).exists(j => e.ops[j].group == "tertiary" and e.ops[j].chan == "fill")))
    .then(assert(0.to(e.ops.length() - 1).exists(j => e.ops[j].group == "tertiary" and e.ops[j].chan == "stroke")))
    .then(assert(0.to(e.ops.length() - 1).exists(j => e.ops[j].group == "tertiary" and e.ops[j].chan == "error")))
  }

  // ---- concat and witness cells (recR1-R6, permanent) ---------------------
  // These cells were written against the failing behaviour: the three-group
  // figure could not carry intervals and the concat dropped the last block.
  // Each cell states its own failure mode.

  // recR1: the three-group figure WITH intervals is 19 ops on the model's
  // drawing list: 1 grid + 9 marks (3 groups x fill, stroke, error) + 9
  // furniture (two tick ops, four tick labels, two axis titles, the figure
  // title). The header is `header`, not an op; the legend rank is reserved
  // and not drawn. MAXOPS 22 is a FITTED bound 3 above that shape - the +3
  // is not decomposed.
  // Fails when: a concat drops a block, the bound moves without the
  // arithmetic following it, or the emitter gains/loses an op.
  run recR1ThreeGroupErrors = {
    val e = emit(threeGroupFig, 0)
    assert(e.ops.length() == 19)
    .then(assert(MAXOPS == 22))
    .then(assert(MAXOPS == e.ops.length() + 3))
    // the composition the constant's comment states, as arithmetic: 1 grid +
    // 9 marks + 9 furniture. MAXOPS is not derived from it (it is 3 higher) -
    // the cell pins both numbers so the prose cannot drift from them again.
    .then(assert(e.ops.length() == 1 + 9 + 9))
  }

  // recR2: every group's interval op survives, the tertiary included, and
  // no interval op names a group outside the three. Fails when: the last
  // group's block is truncated - this is the op the six-arm ladder used to
  // drop.
  run recR2ErrPerGroup = {
    val e = emit(threeGroupFig, 0)
    val ok = 0.to(MAXOPS - 1).forall(j => implies(j < e.ops.length() and e.ops[j].chan == "error", e.ops[j].group == "primary" or e.ops[j].group == "secondary" or e.ops[j].group == "tertiary"))
    assert(0.to(MAXOPS - 1).exists(j => implies(j < e.ops.length(), e.ops[j].chan == "error" and e.ops[j].group == "tertiary")))
    .then(assert(ok))
  }

  // recR3: the witness's limbs, held against the interval figure. Fails
  // when: the witness's own figure cannot carry intervals (the pinned shape),
  // i.e. exactly the defect the pin hid.
  run recR3WitnessWithErr = {
    val e = emit(threeGroupFig, 0)
    assert(threeGroupFig.groups.length() == 3 and threeGroupFig.errors)
    .then(assert(0.to(e.ops.length() - 1).exists(j => e.ops[j].group == "tertiary" and e.ops[j].chan == "fill")))
    .then(assert(0.to(e.ops.length() - 1).exists(j => e.ops[j].group == "tertiary" and e.ops[j].chan == "stroke")))
    .then(assert(0.to(e.ops.length() - 1).exists(j => e.ops[j].group == "tertiary" and e.ops[j].chan == "error")))
  }

  // recR4: the vacuous-limb shape, stated alone so the defect is visible.
  // `exists` over an EMPTY list is false, and `implies` inside it makes
  // every index true - the old p5's shape passes on an empty op list.
  // The cell states the defect BOTH ways: the vacuous form is vacuously
  // true, and the non-vacuous form (an op must exist) is false on the same
  // empty list. Fails when: someone "fixes" this by deleting the guard, which
  // makes the meaningful reading indistinguishable from the vacuous one.
  run recR4EmptyExists = {
    val vacuous = 0.to(MAXOPS - 1).exists(j => implies(j < 0, j == 99))
    assert(not(0.to(0).exists(j => j == 99)))
    .then(assert(vacuous == 0.to(MAXOPS - 1).exists(j => implies(j < 0, j == 99))))
    .then(assert(vacuous))
  }

  // recR5: a pair limb passes on any figure whose emitter emits
  // primary+secondary unconditionally. The cell holds the good reading against
  // the bad one on the figure where they DIVERGE: a ONE-group figure, whose
  // emitter draws a mark block for its own group only. A secondary limb is
  // false there, so a limb hardcoded to the pair would be caught. Both limbs
  // are asked over the real index range, guarded by the list bound.
  // Fails when: the emitter emits a secondary block on a one-group figure.
  run recR5PairLimbsGuarded = {
    val e = emit(oneGroupFig, 0)
    val hasPrimary = 0.to(e.ops.length() - 1).exists(j => e.ops[j].group == "primary" and e.ops[j].chan == "fill")
    val hasSecondary = 0.to(e.ops.length() - 1).exists(j => e.ops[j].group == "secondary" and e.ops[j].chan == "fill")
    assert(hasPrimary)
    .then(assert(not(hasSecondary)))
    .then(assert(emit(twoGroupFig, 0).ops.length() > 10))
  }

  // the pair-limb CONTROL, held against the empty figure: with no ops the
  // guarded secondary limb is false while the `implies(j < 0, ...)` form is
  // vacuously TRUE. This is the limb shape `p5` used, and it is why p5 is
  // restated above on a non-empty list.
  // Fails when: someone restates a limb as `exists(implies(...))` and expects
  // it to constrain anything.
  run recR5bPairLimbVacuousForm = {
    val e = emit(emptyFig, 0)
    // `emptyFig` still carries the four tick labels and the axis titles, so
    // "empty" here means "no group, hence no MARK op" - the list is non-empty
    // and carries no fill.
    val noMarks = 0.to(MAXOPS - 1).forall(j => implies(j < e.ops.length(), e.ops[j].chan != "fill"))
    val guardedFill = e.ops.length() > 0 and 0.to(e.ops.length() - 1).exists(j => e.ops[j].chan == "fill")
    val vacuousFill = 0.to(e.ops.length() - 1).exists(j => false)
    assert(noMarks)
    .then(assert(not(guardedFill)))
    .then(assert(not(vacuousFill)))
    .then(assert(0.to(MAXOPS - 1).exists(j => implies(j < 0, j == 99))))
  }

  // recR6: three groups must carry three DISTINCT ordering keys. The
  // fill op is the group-carrying op (a stroke op's group is a mark group too,
  // but the fill is the one a legend reads), and the three sit at 1, 4, 7 in
  // the pinned grid-then-marks order. Fails when: gIdx maps tertiary onto the
  // secondary's index (a swap of groups 2 and 3 then passes P3 undetected).
  run recR6ThirdGroupKey = {
    val e = emit(threeGroupFig, 0)
    val k1 = key(e.ops[1])
    val k2 = key(e.ops[4])
    val k3 = key(e.ops[7])
    assert(e.ops[1].chan == "fill" and e.ops[1].group == "primary")
    .then(assert(e.ops[4].chan == "fill" and e.ops[4].group == "secondary"))
    .then(assert(e.ops[7].chan == "fill" and e.ops[7].group == "tertiary"))
    .then(assert(Set(k1, k2, k3).size() == 3 and k1 < k2 and k2 < k3))
  }

  // ---- bound and alphabet cells (recR7-R9) --------------------------------
  // All three fail on the earlier behaviour: P1's domain capped at a
  // constant, the open group alphabet, and the missing length limb.

  // padding helper: a legal emission plus four copies of its first op
  // (19 -> 23, one past MAXOPS). Test-only, used by recR7 and recR9.
  pure def padPastBound(l: OpList): OpList =
    { header: l.header, ops: catOps(l.ops, [l.ops[0], l.ops[0], l.ops[0], l.ops[0]]) }

  // recR7: P1's domain covers the list's TRUE length, so a malformed op
  // appended past the bound is seen.
  // Fails when: the limb's domain is capped at a constant again.
  run recR7P1TailCovered = {
    val e = emit(threeGroupFig, 0)
    val long = padPastBound(e)
    val bad = { kind: "text", chan: "ticklabel", group: "", xy: [0, 0],
                colour: 0, width: 0, size: 0, text: "", rot: 0 }
    val longTail = { header: long.header, ops: long.ops.append(bad) }
    val len = longTail.ops.length()
    val last = longTail.ops[len - 1]
    val p1TrueLength = 0.to(len - 1).forall(j => p1op(longTail.ops[j]))
    val isBad = exists(0.to(len - 1), j => not(p1op(longTail.ops[j])))
    assert(e.ops.length() == 19 and len == 24)
    .then(assert(len > MAXOPS))
    .then(assert(not(p1op(last))))
    .then(assert(isBad))
    .then(assert(not(p1TrueLength)))
  }

  run recR8UnknownGroup = {
    val groupKeys = Set(key(op("fill-circles", "fill", "primary", [0, 0], 0, 0, 0, "", 0)),
                        key(op("fill-circles", "fill", "secondary", [0, 0], 0, 0, 0, "", 0)),
                        key(op("fill-circles", "fill", "tertiary", [0, 0], 0, 0, 0, "", 0)))
    assert(groupKeys.size() == 3)
    .then(assert(gAlphabet.contains("primary") and gAlphabet.contains("secondary") and gAlphabet.contains("tertiary")))
    .then(assert(not(gAlphabet.contains("mystery"))))
    .then(assert(gIdx("mystery") == -1 and gIdx("") == -1))
    .then(assert(key(op("fill-circles", "fill", "mystery", [0, 0], 0, 0, 0, "", 0)) < 100))
  }

  // recR9: the length limb. The legal 19-op emission is inside
  // the bound; the 23-op list is past it. `maxOps` is a standalone limb
  // because the P1 domain, restated over the true length, no longer implies
  // anything about the length itself.
  // Fails when: the limb is dropped from `irInv`, or MAXOPS shrinks below
  // the emitter's measured shape.
  run recR9LengthBounded = {
    val e = emit(threeGroupFig, 0)
    val long = padPastBound(e)
    val maxOps = long.ops.length() <= MAXOPS
    // `maxOps` is the `irInv` limb read on a list one step past the bound:
    // true for the emitter's own 19-op figure, false for the 23-op list. The
    // cell binds it as a `val` so the limb CAN fail here - the guard against
    // the vacuous-run hazard that makes a green run prove nothing.
    assert(e.ops.length() <= MAXOPS)
    .then(assert(long.ops.length() > MAXOPS))
    .then(assert(not(maxOps)))
    .then(assert(maxOps == implies(long.ops.length() > 0, long.ops.length() <= MAXOPS)))
  }

  // recR9b (control): the xy limb is the one P1 limb reachable in
  // the model. Op construction always yields a two-coordinate xy, so the
  // other four limbs are held by the type and can never fail here; the
  // suite must not read a green P1 as proof of the pair/kind/colour limbs.
  // The modelled emitters keep even xy; an odd one is rejected.

  run recR9OddXy = {
    val e = emit(oneGroupFig, 0)
    val odd = { kind: "text", chan: "ticklabel", group: "", xy: [0, 0, 0],
                colour: 0, width: 0, size: 0, text: "x", rot: 0 }
    assert(0.to(e.ops.length() - 1).forall(j => (e.ops[j].xy.length() % 2 == 0)))
    .then(assert(not(odd.xy.length() % 2 == 0)))
  }

  run witnessP1P2 = {
    val e = emit(degenerateFig, 0)
    assert(listP1P2(e))
  }

  // combined invariant for the bounded verify (P1, P2, P3, P5,
  // P6-empty over every emission the state machine can produce)
  val irInv = and(p1, maxOps, p2, p3, p5, p6empty)
}
