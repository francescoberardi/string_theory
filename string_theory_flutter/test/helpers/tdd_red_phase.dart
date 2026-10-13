/// Helper for TDD Red Phase acceptance test scaffolds.
///
/// Acceptance tests start with `skip: tddRedPhaseReason` so that `main` and CI
/// remain green while tests are committed in the red phase.
const String? tddRedPhaseReason = null;

const bool tddRedPhase = false;

/// Red-phase skip toggle for Story 6.4 (Dedicated Sessions History Screen & Domain Model Extraction).
const String tddRedPhase64Reason =
    'TDD Red Phase: Acceptance test scaffold for Story 6.4 pending implementation';
const bool tddRedPhase64 = true;
