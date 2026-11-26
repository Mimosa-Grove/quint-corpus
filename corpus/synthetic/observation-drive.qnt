// observation-drive.qnt - synthetic corpus entry.
// Licence: AGPL-3.0-or-later.
// min_quint: 0.34.0
//
// Observations in the three reachability classes the run-driving audit asks
// about: one true in the initial state, one reached by sampled traces, and
// one that needs more increments than any sampled trace reaches. The last is
// the red case: an observation reached in zero traces is reported, not
// assumed dead. Every action assigns every variable, so the sampled traces
// are the only source of reachability.

module ObservationDrive {
  pure val WarmUpSteps = 2
  pure val UnreachableDepth = 100

  var ticks: int
  var quiet: int

  action init = all {
    ticks' = 0,
    quiet' = 0
  }

  action tick = all {
    ticks' = ticks + 1,
    quiet' = quiet
  }

  action rest = all {
    ticks' = ticks,
    quiet' = quiet + 1
  }

  // A burst moves two ticks in one step, which makes the warm-up observation
  // reachable in fewer sampled steps than a single-tick trace needs.
  action burst = all {
    ticks' = ticks + WarmUpSteps,
    quiet' = quiet
  }

  action reset = all {
    ticks' = 0,
    quiet' = 0
  }

  action step = any { tick, rest, burst, reset }

  // True in the initial state and false after the first tick.
  observation noTicksYet = ticks == 0

  // Reached whenever two ticks happen in one sampled trace.
  observation warmedUp = ticks >= WarmUpSteps

  // Reached only after the rest branch runs twice.
  observation restedTwice = quiet >= 2

  // Reached by a single burst step.
  observation burstSeen = ticks >= WarmUpSteps and ticks <= WarmUpSteps * 2

  // Unreachable under any sampled step bound below one hundred ticks.
  observation deeplyTicked = ticks >= UnreachableDepth

  invariant ticksNonNegative = ticks >= 0
  invariant quietNonNegative = quiet >= 0
  invariant ticksBounded = ticks <= UnreachableDepth

  invariant quietBounded = quiet <= UnreachableDepth

  pure def idle(ticksNow: int, quietNow: int): bool = ticksNow == 0 and quietNow == 0
  observation idleAfterReset = idle(ticks, quiet)

  pure def stalled(ticksNow: int, quietNow: int): bool =
    ticksNow == 0 and quietNow > 0
  observation restingAfterReset = stalled(ticks, quiet)
}
