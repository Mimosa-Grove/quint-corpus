// temporal-kinds.qnt - synthetic corpus entry.
// Licence: AGPL-3.0-or-later.
// min_quint: 0.34.0
//
// A temporal property beside an `invariant` and an `observation` in one
// module. The corpus holds three temporal declarations, all of them in one
// third-party protocol model; this member puts the temporal kind next to the
// two kinds 0.34 added, which is the adjacent shape a sweeping tool sees when
// a model mixes safety, reachability and liveness in a single unit.

module TemporalKinds {
  pure val StepsToDone = 3

  var phase: int
  var finished: bool

  action init = all {
    phase' = 0,
    finished' = false
  }

  action advance = all {
    phase' = if (finished) phase else phase + 1,
    finished' = finished
  }

  action finish = all {
    phase' = phase,
    finished' = true
  }

  action restart = all {
    phase' = 0,
    finished' = false
  }

  // Pausing leaves both variables untouched; it exists so the sampled traces
  // contain steps that satisfy the safety invariant without reaching liveness.
  action pause = all {
    phase' = phase,
    finished' = finished
  }

  action step = any { advance, finish, restart, pause }

  // Safety: in ordinary state, not temporal.
  invariant phaseNonNegative = phase >= 0
  invariant phaseBounded = phase <= StepsToDone

  // Reachability reported by name.
  observation started = phase > 0
  observation complete = finished

  // Liveness and an always-property in the temporal kind.
  temporal eventuallyFinished = eventually(finished)
  temporal neverNegative = always(phase >= 0)
  temporal neverPastGoal = always(phase <= StepsToDone)

  pure def atStep(phaseNow: int, target: int): bool = phaseNow == target
  observation atStepTwo = atStep(phase, 2)

  pure def belowGoal(phaseNow: int): bool = phaseNow < StepsToDone
  observation midFlight = belowGoal(phase) and phase > 0

  invariant finishedImpliesPhase = finished implies phase >= 0
}
