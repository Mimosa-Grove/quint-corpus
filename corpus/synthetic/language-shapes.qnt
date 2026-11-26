// language-shapes.qnt - synthetic corpus entry.
// Licence: AGPL-3.0-or-later (quint-audit).
//
// GAP CLOSED: higher-order operators in a model, records nested three deep,
// and a large enumeration. No first-party or third-party corpus spec passes
// an operator as a parameter, nests records past two levels, or declares an
// enumeration of this width, so decoder and check coverage for those IR
// shapes had no real input.
//
// Multi-module instantiation is NOT repeated here: njuggle's icon-machine
// and tab-visibility instantiate one parameterised module across four
// mutation values and Paxos instantiates Voting, which covers that shape.

module languageShapes {

  // A 24-constructor enumeration: wide enough that set membership, equality
  // and oneOf over the type exercise more than a handful of tags.
  type Kind =
    K00 | K01 | K02 | K03 | K04 | K05 | K06 | K07 |
    K08 | K09 | K10 | K11 | K12 | K13 | K14 | K15 |
    K16 | K17 | K18 | K19 | K20 | K21 | K22 | K23

  // Three levels: Outer -> Middle -> Leaf.
  type Leaf = { key: str, value: int }
  type Middle = { leaf: Leaf, weight: int }
  type Outer = { name: str, middle: Middle, tags: Set[str] }

  var outer: Outer
  var seen: Set[Kind]
  var total: int

  // Higher-order: operators passed as parameters, then applied.
  pure def applyInt(f: (int) => int, x: int): int = f(x)
  pure def twice(f: (int) => int, x: int): int = applyInt(f, applyInt(f, x))
  pure def compose(f: (int) => int, g: (int) => int, x: int): int = f(g(x))
  pure def sumBy(f: (int) => int, xs: Set[int]): int =
    xs.fold(0, (acc, x) => acc + f(x))

  pure def bumped(o: Outer): Outer =
    o.with("middle", o.middle.with("leaf",
      o.middle.leaf.with("value", o.middle.leaf.value + 1)))

  pure def tagged(o: Outer, tag: str): Outer =
    o.with("tags", o.tags.union(Set(tag)))

  action init = all {
    outer' = {
      name: "root",
      middle: { leaf: { key: "k0", value: 0 }, weight: 1 },
      tags: Set("init")
    },
    seen' = Set(K00),
    total' = 0
  }

  action deepen = all {
    outer' = bumped(outer),
    seen' = seen.union(Set(K01)),
    total' = total + sumBy(x => x * 2, Set(outer.middle.leaf.value, outer.middle.weight))
  }

  action tag = all {
    outer' = tagged(outer, "t"),
    seen' = seen.union(Set(K23)),
    total' = total + twice(x => x + 3, 1)
  }

  action step = any { deepen, tag }

  val inv = and {
    outer.middle.leaf.value >= 0,
    outer.middle.weight == 1,
    size(seen) <= 24,
    total >= 0,
    compose(x => x * 2, x => x + 1, 2) == 6
  }
}
