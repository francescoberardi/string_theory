/// Skip reason for ATDD red-phase scaffolds: acceptance tests written before
/// the behavior they describe. Remove `skip: tddRedPhaseReason` from a test
/// when its criterion is implemented.
const tddRedPhaseReason =
    'ATDD RED PHASE: acceptance scaffold pending implementation';

/// `testWidgets` takes a bool `skip`; pair it with [tddRedPhaseReason].
const tddRedPhase = true;
