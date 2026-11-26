// imported-invariants.qnt - synthetic corpus entry.
// Licence: AGPL-3.0-or-later.
// min_quint: 0.34.0
//
// Two modules in one file: a ledger invariants module and a ledger that
// imports it unqualified. The importing module seeds its state so that an
// imported invariant is false at the initial state, which is the shape the
// audit uses to attribute a violation to the declaring module rather than to
// the importing one. The importing module also references imported and local
// declarations in a collection, so both are used as first-class values.

module LedgerInvariants {
  var balanced: int
  var posted: int

  // Violated whenever the ledger overdraws in either direction.
  invariant balancedNonNegative = balanced >= 0

  // An imported observation: reported as reached or not, never auto-checked.
  observation postingStarted = posted > 0

  invariant postedAtLeastBalanced = posted >= balanced
}

module Ledger {
  import LedgerInvariants.*

  var batches: int

  // The negative seed is the violation: balancedNonNegative is imported, so
  // the audit has to name LedgerInvariants as the declaring module.
  action init = all {
    balanced' = -1,
    posted' = 0,
    batches' = 1
  }

  action commit = all {
    balanced' = balanced + 1,
    posted' = posted + 1,
    batches' = batches
  }

  action reject = all {
    balanced' = balanced,
    posted' = posted,
    batches' = if (batches > 0) batches - 1 else 0
  }

  action step = any { commit, reject }

  invariant batchesNonNegative = batches >= 0

  observation ledgerActive = balanced + posted > 0

  // Imported and local invariants used as values, not only as CLI names.
  val reviewed = Set(balancedNonNegative, batchesNonNegative)

  pure def drained(balance: int, count: int): bool = balance + count == 0

  observation drainedLedger = drained(balanced, posted)
}
