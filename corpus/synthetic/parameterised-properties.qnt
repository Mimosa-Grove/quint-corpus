// parameterised-properties.qnt - synthetic corpus entry.
// Licence: AGPL-3.0-or-later.
// min_quint: 0.34.0
//
// The parameterised property shapes. Quint 0.34 parses an `invariant` or
// `observation` that takes parameters and rejects it at typecheck (QNT200:
// the kinds may not have parameters), so this file is valid at the parse gate
// only and exists for tools that read the parse IR. The audit's non-triviality
// check keeps parameterised properties as subjects and discloses them as
// coverage rows; the nullary pair beside them shows the admitted shape.

module ParameterisedProperties {
  pure val DepthGoal = 4

  var depth: int
  var guard: int

  action init = all {
    depth' = 0,
    guard' = 2
  }

  action dive = all {
    depth' = depth + 1,
    guard' = guard
  }

  action surface = all {
    depth' = if (depth > 0) depth - 1 else 0,
    guard' = guard
  }

  action tighten = all {
    depth' = depth,
    guard' = if (guard > 1) guard - 1 else 1
  }

  action step = any { dive, surface, tighten }

  // The parameterised pair: parse-valid, typecheck-refused upstream.
  invariant depthBounded(limit: int): bool = depth <= limit
  observation passedDepth(stage: int): bool = depth >= stage

  // A second parameterised pair through a pure helper, same admission.
  pure def scaled(limit: int): int = limit * 2
  invariant depthBudget(limit: int): bool = depth <= scaled(limit)
  observation budgetSpent(limit: int): bool = scaled(limit) < depth

  // The nullary pair: fully typechecked and checkable.
  invariant guardPositive = guard >= 1
  observation belowGoal = depth < DepthGoal

  // A third parameterised pair over the guard lane, same admission.
  invariant guardWithin(limit: int): bool = guard <= limit
  observation guardSpent(budget: int): bool = guard >= budget

  pure def atSurface(depthNow: int): bool = depthNow == 0
  observation resting = atSurface(depth)

  pure def margin(current: int, target: int): int = target - current
  observation atGoal = margin(depth, DepthGoal) == 0

  pure def exceeded(depthNow: int, limit: int): bool = depthNow > limit
  observation pastLimit = exceeded(depth, DepthGoal)
}

