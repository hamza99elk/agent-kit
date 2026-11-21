# AuditorRunDetailSchema — Field Reference

Source: `packages/contracts/src/projections/auditor-run-detail.ts`

## Family 1: Run identity (~18 fields)

Fields: `id`, `run_id`, `audit_type`, `audit_scope`, `target_type`, `target_ref`,
`entity`, `entity_type`, `entity_id`, `entity_label`, `status`, `severity_summary`,
`timestamp`, `created_at`, `updated_at`, `started_at`, `completed_at`,
`summary_json`, `artifact_refs_json`

Corresponds to the base `AuditorRunSchema` in `concepts/auditor-run.ts`.

## Family 2: Detail/result output (~30 fields)

Fields: `findings`, `total_entities_audited`, `missing_sections`, `total_issues`,
`pages_affected`, `audit_summary`, `issue_class_summaries`, `computed`,
`progress`, `run_step_events`, `site_profile_snapshot`, `capture_metadata`,
`coming_soon`, `execution_timeline`, `timeline_moments`, `issue_groups`,
`causal_chains`, `evidence_summary`, `evidence_summary_by_page`, `run_outcome`,
`failure_stage`, `failure_message`, `status_source`, `product_summary`,
`overall_status`, `decision_block`

This is the audit output — produced by the assemble task from collected
evidence and classified findings.

## Family 3: Infrastructure/retry trace (~20 fields)

Fields: `execution_origin`, `block_diagnostics`, `status_reason`,
`execution_mode`, `submit_failure_reason`, `compliance_status`, `cmp_detection`,
`coverage`, `consent_flow`, `attempt_id`, `attempt_seq`, `root_run_id`,
`rerun_of_run_id`, `idempotency_reused`, `evaluation_summary`,
`evaluation_results_preview`, `egress_policy_mode`, `egress_gate`,
`execution_resolution`, `execution_fallback_applied`, `execution_fallback_message`,
`initial_mode`, `retry_mode`, `retry_country`, `lineage_matches`

This is the infra trace — populated by the audit-engine during execution,
not by the pipeline tasks.

## Task-level substructures (projections/auditor-browser-stage.ts)

When adding new fields, consider whether they belong in a task-level
substructure first:

- `SessionLaunchResultSchema` — browserId, pageUrl, proxyCountry, startedAt
- `CollectedEvidenceSchema` — cookies[], networkReqs[], consentSignals[], dom
- `FindingSetSchema` — items[], severitySummary