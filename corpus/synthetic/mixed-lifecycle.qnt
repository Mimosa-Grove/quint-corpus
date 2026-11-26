// mixed-lifecycle.qnt - synthetic corpus entry.
// Licence: AGPL-3.0-or-later.
// min_quint: 0.34.0
//
// A work-queue lifecycle of the size and shape a real specification reaches:
// a set of tasks moving through claim, complete and fail, with a retry bound,
// a capacity policy held in a record, and a clock that advances independently.
// It mixes the 0.33-era declaration kinds (pure defs, pure vals, actions, a
// temporal formula) with the 0.34 property kinds (invariants and
// observations) in one module, which is what a sweeping tool sees when a
// model written before 0.34 is extended with the new kinds.
//
// Every action assigns every variable, so action reachability in a sampled
// run is a property of the guards rather than of accidental stuttering.

module MixedLifecycle {
  //-------------------------------------------------------------------------
  // Types
  //-------------------------------------------------------------------------

  type Status =
    | Queued
    | Running
    | Finished
    | Abandoned

  type Config = {
    capacity: int,
    policy: str,
    retryBudget: int
  }

  type Ledger = int -> int

  //-------------------------------------------------------------------------
  // Constants
  //-------------------------------------------------------------------------

  pure val TaskCount = 6
  pure val MaxRetries = 2
  pure val DefaultCapacity = 2
  pure val DefaultPolicy = "fair"

  pure val TaskIds = Set(0, 1, 2, 3, 4, 5)

  //-------------------------------------------------------------------------
  // Pure helpers
  //-------------------------------------------------------------------------

  pure def emptyLedger = TaskIds.mapBy(_ => 0)

  pure def loadOf(active: Set[int]): int = size(active)

  pure def atCapacity(active: Set[int], config: Config): bool =
    loadOf(active) >= config.capacity

  pure def belowCapacity(active: Set[int], config: Config): bool =
    loadOf(active) < config.capacity

  pure def retryExhausted(attempts: Ledger, id: int): bool =
    attempts.get(id) >= MaxRetries

  pure def retriesLeft(attempts: Ledger, id: int): int =
    if (retryExhausted(attempts, id)) 0 else MaxRetries - attempts.get(id)

  pure def recorded(attempts: Ledger, id: int): Ledger =
    attempts.set(id, attempts.get(id) + 1)

  pure def settle(active: Set[int], id: int): Set[int] = active.exclude(Set(id))

  pure def admit(queue: Set[int], id: int): Set[int] = queue.exclude(Set(id))

  pure def released(queue: Set[int], id: int): Set[int] = queue.union(Set(id))

  pure def totalSettled(done: Set[int], failed: Set[int]): int =
    size(done) + size(failed)

  pure def allSettled(done: Set[int], failed: Set[int]): bool =
    totalSettled(done, failed) == TaskCount

  pure def nextPhase(phase: int, done: Set[int], failed: Set[int]): int =
    if (allSettled(done, failed)) 2 else phase

  pure def phaseName(phase: int): str =
    if (phase == 0) "idle" else if (phase == 1) "working" else "drained"

  pure def statusOf(id: int, queue: Set[int], active: Set[int],
                    done: Set[int], failed: Set[int]): Status =
    if (id.in(queue)) Queued
    else if (id.in(active)) Running
    else if (id.in(done)) Finished
    else if (id.in(failed)) Abandoned
    else Queued

  pure def describe(id: int, queue: Set[int], active: Set[int],
                    done: Set[int], failed: Set[int]): str =
    if (id.in(queue)) "queued"
    else if (id.in(active)) "running"
    else if (id.in(done)) "finished"
    else if (id.in(failed)) "abandoned"
    else "unknown"

  pure def uniqueStatuses(queue: Set[int], active: Set[int],
                          done: Set[int], failed: Set[int]): int =
    size(queue) + size(active) + size(done) + size(failed)

  pure def bounded(attempts: Ledger): bool =
    TaskIds.forall(id => attempts.get(id) <= MaxRetries)

  pure def everyPhaseKnown(phase: int): bool =
    phase >= 0 and phase <= 2

  pure def capacityHeld(active: Set[int], config: Config): bool =
    loadOf(active) <= config.capacity

  pure def policyKnown(config: Config): bool =
    config.policy == DefaultPolicy or config.policy == "strict"

  //-------------------------------------------------------------------------
  // Policy arithmetic and lane accounting
  //-------------------------------------------------------------------------

  pure def pendingSet(queue: Set[int], active: Set[int]): Set[int] =
    queue.union(active)

  pure def settledSet(done: Set[int], failed: Set[int]): Set[int] =
    done.union(failed)

  pure def laneCount(queue: Set[int], active: Set[int], done: Set[int],
                     failed: Set[int]): int =
    size(queue) + size(active) + size(done) + size(failed)

  pure def lanesExclusive(queue: Set[int], active: Set[int], done: Set[int],
                          failed: Set[int]): bool =
    size(queue.intersect(active)) == 0
      and size(queue.intersect(done)) == 0
      and size(queue.intersect(failed)) == 0
      and size(active.intersect(done)) == 0
      and size(active.intersect(failed)) == 0
      and size(done.intersect(failed)) == 0

  pure def capacityGap(active: Set[int], config: Config): int =
    if (loadOf(active) >= config.capacity) 0 else config.capacity - loadOf(active)

  pure def retryable(attempts: Ledger, id: int): bool =
    attempts.get(id) > 0 and attempts.get(id) < MaxRetries

  pure def finishedShare(done: Set[int], failed: Set[int]): bool =
    size(done) * 2 >= totalSettled(done, failed)

  pure def settlementImpliesPhase(phase: int, done: Set[int],
                                  failed: Set[int]): bool =
    if (allSettled(done, failed)) phase >= 1 else phase >= 0

  pure def capacityWithinPolicy(config: Config): bool =
    config.capacity >= 1 and config.capacity <= DefaultCapacity

  pure def ledgerWithinBudget(attempts: Ledger, config: Config): bool =
    TaskIds.forall(id => attempts.get(id) <= config.retryBudget)

  pure def anyRetryRecorded(attempts: Ledger): bool =
    size(TaskIds.filter(id => attempts.get(id) > 0)) > 0

  pure def knownStatuses(queue: Set[int], active: Set[int], done: Set[int],
                         failed: Set[int]): bool =
    TaskIds.forall(id =>
      describe(id, queue, active, done, failed) != "unknown")

  pure def claimable(queue: Set[int], active: Set[int], config: Config): bool =
    size(queue) > 0 and belowCapacity(active, config)

  pure def claimableCount(queue: Set[int], active: Set[int],
                          config: Config): int =
    if (claimable(queue, active, config)) size(queue) else 0

  pure def allLanesEmpty(queue: Set[int], active: Set[int]): bool =
    size(queue) == 0 and size(active) == 0

  //-------------------------------------------------------------------------
  // State
  //-------------------------------------------------------------------------

  var queue: Set[int]
  var active: Set[int]
  var done: Set[int]
  var failed: Set[int]
  var attempts: Ledger
  var clock: int
  var phase: int
  var config: Config

  //-------------------------------------------------------------------------
  // Actions
  //-------------------------------------------------------------------------

  action init = all {
    queue' = TaskIds,
    active' = Set(),
    done' = Set(),
    failed' = Set(),
    attempts' = emptyLedger,
    clock' = 0,
    phase' = 0,
    config' = {
      capacity: DefaultCapacity,
      policy: DefaultPolicy,
      retryBudget: MaxRetries
    }
  }

  // Move one queued task into the active set while capacity remains.
  action claim(id) = all {
    id.in(queue),
    belowCapacity(active, config),
    queue' = admit(queue, id),
    active' = active.union(Set(id)),
    done' = done,
    failed' = failed,
    attempts' = attempts,
    clock' = clock,
    phase' = 1,
    config' = config
  }

  // Finish one active task.
  action complete(id) = all {
    id.in(active),
    active' = settle(active, id),
    done' = done.union(Set(id)),
    queue' = queue,
    failed' = failed,
    attempts' = attempts,
    clock' = clock,
    phase' = nextPhase(phase, done.union(Set(id)), failed),
    config' = config
  }

  // Record a failed attempt: retry puts the task back in the queue, exhaustion
  // moves it to the failed set.
  action reject(id) = all {
    id.in(active),
    active' = settle(active, id),
    queue' = if (retryExhausted(attempts, id)) queue else released(queue, id),
    failed' = if (retryExhausted(attempts, id)) failed.union(Set(id)) else failed,
    done' = done,
    attempts' = recorded(attempts, id),
    clock' = clock,
    phase' = phase,
    config' = config
  }

  // Withdraw one queued task without running it.
  action cancel(id) = all {
    id.in(queue),
    queue' = admit(queue, id),
    failed' = failed.union(Set(id)),
    active' = active,
    done' = done,
    attempts' = attempts,
    clock' = clock,
    phase' = phase,
    config' = config
  }

  // Capacity can be lowered while idle and restored while drained.
  action tighten = all {
    phase == 0,
    config.capacity > 1,
    config' = config.with("capacity", config.capacity - 1),
    queue' = queue,
    active' = active,
    done' = done,
    failed' = failed,
    attempts' = attempts,
    clock' = clock,
    phase' = phase
  }

  action widen = all {
    config.capacity < DefaultCapacity,
    config' = config.with("capacity", config.capacity + 1),
    queue' = queue,
    active' = active,
    done' = done,
    failed' = failed,
    attempts' = attempts,
    clock' = clock,
    phase' = phase
  }

  action tick = all {
    clock' = clock + 1,
    phase' = phase,
    queue' = queue,
    active' = active,
    done' = done,
    failed' = failed,
    attempts' = attempts,
    config' = config
  }

  action step = any {
    nondet id = TaskIds.oneOf()
    claim(id),
    nondet id = TaskIds.oneOf()
    complete(id),
    nondet id = TaskIds.oneOf()
    reject(id),
    nondet id = TaskIds.oneOf()
    cancel(id),
    tighten,
    widen,
    tick
  }

  //-------------------------------------------------------------------------
  // Properties in the 0.34 kinds
  //-------------------------------------------------------------------------

  invariant phaseKnown = everyPhaseKnown(phase)

  invariant capacityHolds = capacityHeld(active, config)

  invariant retriesBounded = bounded(attempts)

  invariant disjointLanes =
    size(queue.intersect(active)) == 0
      and size(queue.intersect(done)) == 0
      and size(active.intersect(done)) == 0

  invariant settledBound = totalSettled(done, failed) <= TaskCount

  invariant attemptsLedgerComplete = size(attempts.keys()) == TaskCount

  observation workStarted = totalSettled(done, failed) > 0

  observation capacityReached = atCapacity(active, config)

  observation clockAdvanced = clock > 0

  observation atLeastOneFinished = size(done) > 0

  observation abandonedRecorded = size(failed) > 0

  observation policyHeld = policyKnown(config)

  invariant lanesAreExclusive = lanesExclusive(queue, active, done, failed)

  invariant capacityWithinPolicyBound = capacityWithinPolicy(config)

  invariant ledgerWithinBudgetBound = ledgerWithinBudget(attempts, config)

  invariant settlementPhaseHolds = settlementImpliesPhase(phase, done, failed)

  invariant statusesKnown = knownStatuses(queue, active, done, failed)

  observation queueEmptied = allLanesEmpty(queue, active)

  observation mostFinished = finishedShare(done, failed)

  observation retryRecorded = anyRetryRecorded(attempts)

  //-------------------------------------------------------------------------
  // A worked trace through the lifecycle
  //-------------------------------------------------------------------------

  run claimThenComplete = {
    init
      .then(claim(0))
      .then(complete(0))
      .expect(and {
        assert(size(done) == 1),
        assert(size(active) == 0),
        assert(size(queue) == TaskCount - 1),
        assert(clock == 0)
      })
  }

  run retryThenAbandon = {
    init
      .then(claim(1))
      .then(reject(1))
      .then(claim(1))
      .then(reject(1))
      .then(claim(1))
      .then(reject(1))
      .expect(and {
        assert(size(failed) == 1),
        assert(attempts.get(1) >= MaxRetries),
        assert(retryExhausted(attempts, 1))
      })
  }

  //-------------------------------------------------------------------------
  // Declarations kept as values and as a temporal formula
  //-------------------------------------------------------------------------

  val reviewed = Set(phaseKnown, capacityHolds, retriesBounded)

  val phaseLabels = Set(phaseName(0), phaseName(1), phaseName(2))

  def labelFor(id: int): str =
    describe(id, queue, active, done, failed)

  observation firstTaskLabelled = labelFor(0) != "unknown"

  temporal eventuallyTicked = eventually(clock > 0)

  temporal neverOverAdmitted = always(size(active) <= config.capacity)

  temporal drainedIsFinal = always(
    if (allSettled(done, failed)) phase >= 1 else phase >= 0)
}

/**
 * Corpus member notes.
 *
 * The model keeps the queue, active, done and failed sets disjoint by
 * construction in every action, so the disjointness invariant is reachable
 * state by state rather than assumed. Retries are bounded by the retry budget
 * stored in the configuration record, and the ledger is a total map over the
 * task identifier set, which keeps the ledger-completeness invariant cheap to
 * check on every state.
 *
 * The trailing doc comment is deliberate: quint 0.34 accepts a doc comment
 * after the module's closing brace, and this member is where a sweeping tool
 * meets that shape in a file large enough to matter.
 */
