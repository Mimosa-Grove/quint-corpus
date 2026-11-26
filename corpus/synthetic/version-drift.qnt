// version-drift.qnt - synthetic corpus entry.
// Licence: AGPL-3.0-or-later (quint-audit).
//
// GAP CLOSED: the IR shapes the checks lean on, in one small fixture, so a
// Quint upgrade produces a diff report rather than silence. Covers
// conditionals inside actions, nested record updates, nondet bindings,
// map/filter (the source-level form of set comprehension) and nested
// conditionals.
//
// NOT COVERED, by language limit at the pin: `let` bindings and set
// comprehensions do not exist in Quint 0.33.1 source (the reference states
// "no let bindings in any context"; `{ x | x in S }` is a parse error). The
// nearest IR shapes are nondet bindings and map/filter, used below.
// Recorded in docs/corpus.md (uncovered gaps).

module versionDrift {

  type Phase = Idle | Busy | Done
  type Item = { id: int, weight: int, meta: { lane: str, depth: int } }

  var phase: Phase
  var items: Set[Item]
  var total: int
  var lastWeight: int

  def weights(lo: int): Set[int] =
    items.filter(i => i.weight >= lo).map(i => i.weight)

  def totalWeight(lo: int): int =
    weights(lo).fold(0, (acc, w) => acc + w)

  // Nested conditional chain: the IR shape conditionals-inside-definitions
  // produces for a three-way branch.
  pure def classify(w: int): Phase =
    if (w > 10) { Done }
    else { if (w > 0) { Busy } else { Idle } }

  action init = all {
    phase' = Idle,
    items' = Set({ id: 0, weight: 0, meta: { lane: "seed", depth: 0 } }),
    total' = 0,
    lastWeight' = 0
  }

  // Conditional inside an action: every conjunct branches on the same guard.
  action add = {
    nondet w = 1.to(12).oneOf()
    all {
      phase' = if (size(items) < 4) classify(w) else Done,
      items' =
        if (size(items) < 4)
          items.union(Set({
            id: size(items),
            weight: w,
            meta: { lane: "add", depth: size(items) }
          }))
        else items,
      total' = if (size(items) < 4) total + w else total,
      lastWeight' = if (size(items) < 4) w else lastWeight
    }
  }

  // Nested record update through two levels.
  action deepen = all {
    items' = items.map(i => i.with("meta", i.meta.with("depth", i.meta.depth + 1))),
    phase' = Busy,
    total' = total,
    lastWeight' = lastWeight
  }

  action step = any { add, deepen }

  val inv = and {
    total == totalWeight(0),
    total <= 4 * 12,
    size(items) <= 4,
    phase != Idle or total == 0,
    lastWeight >= 0
  }
}
