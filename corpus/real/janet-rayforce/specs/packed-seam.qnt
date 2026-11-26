// janet-rayforce packed seam - Quint specification
// Models the `table-from-packed` seam contract, not the C code.
//
// States: the handle is live or closed; a call is idle, pending,
// refused, or has built its column. Transitions: validate -> ingest ->
// return. The call is synchronous: the handle may close or finalise
// (the same event for the column's bytes) before or after the call,
// never inside it.
//
// Invariants:
//   I1 copy-on-ingest: a built column's bytes are the bytes ingested
//      at call time, unaffected by any later handle transition.
//   I2 ingest happens only from a live handle with a valid f64 layout;
//      every other call is refused (the error class made total).
//   I3 a successful call returns exactly one column; a refusal returns
//      no column and leaves the handle unchanged.
//   I4 the documented value mapping: NaN in -> NaN out; numbers pass
//      through unchanged (identity over the f64 payload).
//
// Mutation coverage (stated here, checked by the second module):
//   packedSeamAliasMutant sets copy-on-ingest OFF. ingest then reads
//   the handle's bytes instead of its own copy; closing the handle
//   after the build makes I1 fail. `quint verify ... --main=
//   packedSeamAliasMutant --invariant=I1` MUST report a violation
//   (counterexample: validate, ingest, finish, close). The copy module
//   must verify clean. This is the model-level instrument; the
//   implementation's T-I1 cells are the second instrument when the code
//   lands. A mutant that dies in neither instrument is not covered.
//
// Scope note: one seam call per handle is modelled (the claim is
// per-build). Multiple columns are abstracted to one value payload:
// the copy/alias decision is per column and identical across columns,
// so one payload cell exercises the ownership predicate.

module packedSeamModel {
  // Copy-on-ingest is the contracted behaviour: true = copy-on-ingest.
  // The mutant instance below sets it false.
  const COPY_ON_INGEST: bool

  // A packed f64 payload cell. `Freed` is the state of the handle's
  // bytes after close/finalise - reading them is the hazard I1 forbids.
  type Val = | Num(int) | Nan | Freed

  pure val HANDLE_VALUES = Set(Num(0), Num(1), Nan)

  var handle: str          // "live" | "closed"
  var phase: str           // "idle" | "pending" | "refused" | "built"
  var outcome: str         // "none" | "refused" | "built" (last return)
  var callValid: bool      // the validate verdict for this call
  var copyMode: bool       // COPY_ON_INGEST (mutant flips it in init)
  var handleBytes: Val     // the packed handle's bytes now
  var callBytes: Val       // the handle's bytes at validate time
  var snapshot: Val        // the column's own bytes (the copy)
  var columnExists: bool   // a build happened in this trace
  var builtColumn: bool    // this call produced its column
  var returned: bool       // this call returned the column

  // The documented mapping: identity over f64 payloads. NaN is a
  // value, never silently rewritten (I4).
  pure def mapValue(v: Val): Val = v

  // What the built column reads. With copy-on-ingest it reads its own
  // snapshot; with the alias defect it reads the handle's bytes, which
  // close/finalise frees.
  def columnRead: Val = if (copyMode) snapshot else handleBytes

  action init =
    nondet h = Set("live", "closed").oneOf()
    nondet v = HANDLE_VALUES.oneOf()
    all {
    handle' = h,
    handleBytes' = v,
    phase' = "idle",
    outcome' = "none",
    callValid' = false,
    copyMode' = COPY_ON_INGEST,
    callBytes' = v,
    snapshot' = Num(0),
    columnExists' = false,
    builtColumn' = false,
    returned' = false,
  }

  // validate is TOTAL over an idle, not-yet-built call: the live+valid
  // pair opens the pending path, every other combination is a refusal.
  // `layoutOk` abstracts the implementation's whole f64 shape/byte-count
  // guard (positive integral dimensions, the `:n`/`:bytes` accounting and
  // the buffer length bound); the model does not enumerate those
  // predicates, so any false one is the same refusal here. The
  // integral-dimension cell (T-I2e) is therefore test-side only.
  action validate =
    nondet layoutOk = oneOf(Set(true, false))
    all {
      phase == "idle",
      not(columnExists),
      callBytes' = handleBytes,
      callValid' = (handle == "live" and layoutOk),
      phase' = if (handle == "live" and layoutOk) "pending" else "refused",
      builtColumn' = false,
      returned' = false,
      handle' = handle,
      handleBytes' = handleBytes,
      outcome' = outcome,
      copyMode' = copyMode,
      snapshot' = snapshot,
      columnExists' = columnExists,
    }

  // ingest builds exactly one column from the call-time bytes. The
  // snapshot is the documented mapping of those bytes; the mutation
  // changes only WHICH bytes the column reads (columnRead).
  action ingest = all {
    phase == "pending",
    callValid,
    snapshot' = mapValue(callBytes),
    phase' = "built",
    builtColumn' = true,
    columnExists' = true,
    handle' = handle,
    handleBytes' = handleBytes,
    outcome' = outcome,
    callValid' = callValid,
    copyMode' = copyMode,
    callBytes' = callBytes,
    returned' = returned,
  }

  action finishBuilt = all {
    phase == "built",
    builtColumn,
    returned' = true,
    phase' = "idle",
    outcome' = "built",
    handle' = handle,
    handleBytes' = handleBytes,
    callValid' = callValid,
    copyMode' = copyMode,
    callBytes' = callBytes,
    snapshot' = snapshot,
    columnExists' = columnExists,
    builtColumn' = builtColumn,
  }

  action finishRefused = all {
    phase == "refused",
    returned' = false,
    phase' = "idle",
    outcome' = "refused",
    handle' = handle,
    handleBytes' = handleBytes,
    callValid' = callValid,
    copyMode' = copyMode,
    callBytes' = callBytes,
    snapshot' = snapshot,
    columnExists' = columnExists,
    builtColumn' = builtColumn,
  }

  // Close or finalise: the handle's bytes are gone. A copied column is
  // untouched; an aliased column now reads Freed.
  action closeHandle = all {
    handle == "live",
    phase == "idle",
    handle' = "closed",
    handleBytes' = Freed,
    phase' = phase,
    outcome' = outcome,
    callValid' = callValid,
    copyMode' = copyMode,
    callBytes' = callBytes,
    snapshot' = snapshot,
    columnExists' = columnExists,
    builtColumn' = builtColumn,
    returned' = returned,
  }

  // Terminal stutter: a closed handle with its column built has no
  // further transitions except staying put.
  action doneIdle = all {
    phase == "idle",
    columnExists,
    handle == "closed",
    handle' = handle,
    handleBytes' = handleBytes,
    phase' = phase,
    outcome' = outcome,
    callValid' = callValid,
    copyMode' = copyMode,
    callBytes' = callBytes,
    snapshot' = snapshot,
    columnExists' = columnExists,
    builtColumn' = builtColumn,
    returned' = returned,
  }

  action step = any {
    validate,
    ingest,
    finishBuilt,
    finishRefused,
    closeHandle,
    doneIdle,
  }

  // I1: the built column owns the bytes ingested at call time,
  // whatever the handle does afterwards.
  def I1_copyOnIngest: bool =
    columnExists implies (columnRead == mapValue(callBytes))

  // I2: only a live handle with a valid f64 layout reaches ingest.
  def I2_ingestOnlyFromValid: bool =
    (phase == "pending" or phase == "built") implies callValid

  // I2b: the refusal path is the complement - no pending call is
  // invalid, and every invalid call lands in refused.
  def I2_refusalIsRefusal: bool =
    (phase == "refused") implies not(callValid)

  // I3a: a successful call returns exactly one column.
  def I3_builtReturnsOne: bool =
    (phase == "built") implies (builtColumn and not(returned))

  def I3_returnIsTheColumn: bool =
    returned implies builtColumn

  // I3b: a refusal returns no column and leaves the handle unchanged
  // at the point of return (later closes are later transitions).
  def I3_refusalReturnsNone: bool =
    (phase == "refused") implies
      (not(returned) and not(builtColumn) and handleBytes == callBytes)

  // I4: NaN in -> NaN out; the numeric payload is unchanged. No silent
  // rewrite of missingness.
  def I4_nullMapping: bool =
    (phase == "built" or outcome == "built") implies all {
      (callBytes == Nan) implies (snapshot == Nan),
      (callBytes != Nan and callBytes != Freed) implies (snapshot == callBytes),
    }
}

module packedSeam {
  import packedSeamModel(COPY_ON_INGEST = true) as M
  action init = M::init
  action step = M::step
  val I1_copyOnIngest = M::I1_copyOnIngest
  val I2_ingestOnlyFromValid = M::I2_ingestOnlyFromValid
  val I2_refusalIsRefusal = M::I2_refusalIsRefusal
  val I3_builtReturnsOne = M::I3_builtReturnsOne
  val I3_returnIsTheColumn = M::I3_returnIsTheColumn
  val I3_refusalReturnsNone = M::I3_refusalReturnsNone
  val I4_nullMapping = M::I4_nullMapping
}

module packedSeamAliasMutant {
  import packedSeamModel(COPY_ON_INGEST = false) as M
  action init = M::init
  action step = M::step
  val I1_copyOnIngest = M::I1_copyOnIngest
  val I2_ingestOnlyFromValid = M::I2_ingestOnlyFromValid
  val I2_refusalIsRefusal = M::I2_refusalIsRefusal
  val I3_builtReturnsOne = M::I3_builtReturnsOne
  val I3_returnIsTheColumn = M::I3_returnIsTheColumn
  val I3_refusalReturnsNone = M::I3_refusalReturnsNone
  val I4_nullMapping = M::I4_nullMapping
}
