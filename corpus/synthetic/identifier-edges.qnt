// identifier-edges.qnt - synthetic corpus entry.
// Licence: AGPL-3.0-or-later.
// min_quint: 0.34.0
//
// The word-level edge the 0.34 release note calls out: `invariant` and
// `observation` stay usable as ordinary identifiers, so a model may keep a
// variable named `invariant` beside a declaration of the `invariant` kind.
// The file also declares one property of each kind, which is what makes it
// unparseable under 0.33 and pins the release boundary.

module IdentifierEdges {
  var invariant: int
  var observation: int

  action init = all {
    invariant' = 0,
    observation' = 0
  }

  action bump = all {
    invariant' = invariant + 1,
    observation' = observation
  }

  action note = all {
    invariant' = invariant,
    observation' = observation + 1
  }

  action step = any { bump, note }

  // The identifiers used as ordinary values.
  def invariantCount = invariant
  def observationCount = observation
  val observationFloor = observation >= 0

  pure def combined(invariantNow: int, observationNow: int): int =
    invariantNow + observationNow

  val totalCount = combined(invariant, observation)

  // One declaration of each kind, beside the identifiers of the same name.
  invariant countersNonNegative = invariant >= 0 and observation >= 0
  observation workBegan = combined(invariant, observation) > 0

  val reviewed = Set(countersNonNegative, workBegan)
}
