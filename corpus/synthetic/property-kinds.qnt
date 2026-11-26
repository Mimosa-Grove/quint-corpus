// property-kinds.qnt - synthetic corpus entry.
// Licence: AGPL-3.0-or-later.
// min_quint: 0.34.0
//
// Old-style and new-style declarations of the same property in one module: a
// plain `val`, an `invariant` and an `observation` restating one bound. The
// module also keeps the constant properties the audit folds (a literal false
// val, a literal true invariant, a literal false observation) so the
// constant-propagation and non-triviality checks share subjects, and one
// invariant that survives the initial state and breaks after actions, which
// is the after-action subject.

module PropertyKinds {
  pure val Ceiling = 3

  var counter: int
  var floor: int

  action init = all {
    counter' = 0,
    floor' = 0
  }

  action increment = all {
    counter' = counter + 2,
    floor' = floor
  }

  action raise = all {
    counter' = counter,
    floor' = floor + 2
  }

  action step = any { increment, raise }

  // The same property in three spellings.
  val counterNonNegativeVal = counter >= 0
  invariant counterNonNegative = counter >= 0
  observation counterAtStart = counter == 0

  // Holds at the initial state and breaks on every action: the after-action
  // subject, deterministic once the audit is asked to evaluate it by name.
  invariant workWithinBudget = counter + floor <= 1

  // Constant properties.
  val literalFalseVal = false
  invariant literalTrueInvariant = true
  observation literalFalseObservation = false

  pure def withinCeiling(c: int): bool = c <= Ceiling
  observation ceilingRespected = withinCeiling(counter)

  pure def totalWork(c: int, f: int): int = c + f
  val workTotal = totalWork(counter, floor)

  invariant floorNonNegative = floor >= 0
  invariant counterNonNegativeAgain = counter >= 0

  observation workRecorded = totalWork(counter, floor) > 0
  observation floorStarted = floor > 0
}
