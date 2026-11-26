// invariant-basics.qnt - synthetic corpus entry.
// Licence: AGPL-3.0-or-later.
// min_quint: 0.34.0
//
// A queue service whose declared invariants exercise the 0.34 `invariant`
// kind in the two outcomes the audit distinguishes: a nullary invariant that
// holds at the initial state, and one that is violated there (the queue is
// seeded above capacity, a modelling bug the audit should name). A constant
// tautology is kept beside them so the non-triviality and constant-propagation
// checks both have a subject. The invariants are also referenced from a `Set`
// so the declarations are used as first-class values, not only as CLI names.

module InvariantBasics {
  pure val Capacity = 3
  pure val TargetRate = 2

  var queued: int
  var capacity: int
  var served: int

  action init = all {
    queued' = 5,
    capacity' = Capacity,
    served' = 0
  }

  action enqueue = all {
    queued' = queued + 1,
    capacity' = capacity,
    served' = served
  }

  action serve = all {
    queued' = if (queued > 0) queued - 1 else 0,
    capacity' = capacity,
    served' = served + 1
  }

  action rebalance = all {
    queued' = queued,
    capacity' = if (capacity < Capacity) Capacity else capacity,
    served' = served
  }

  action step = any { enqueue, serve, rebalance }

  // Holds at the initial state: capacity is seeded from the constant.
  invariant capacityNonNegative = capacity >= 0

  // Violated at the initial state: five queued against a capacity of three.
  invariant queueWithinCapacity = queued <= capacity

  // Holds and means nothing: the constant-propagation subject.
  invariant reviewedByHand = 1 == 1

  // Served work never exceeds capacity plus the served count itself.
  invariant servedBound = served <= queued + served

  val invariantsReviewed = Set(capacityNonNegative, queueWithinCapacity)

  pure def saturated(q: int, c: int): bool = q >= c

  observation queueSaturated = saturated(queued, capacity)
  observation targetRateReached = served >= TargetRate
}
