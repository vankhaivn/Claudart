<!--
Author notes: Use a separate page only when running, updating, or recovering the software needs an owner beyond existing development/README guidance. Adapt to actual local use, deployment, or formal release; retain the team's applicable approval, verification, recovery, and support requirements. Update when those procedures change; replace or retire this page if an existing runbook owns them. Remove this comment and inapplicable sections after adaptation; do not invent a production process.
-->

# Operating {{project_name}}

## Use and delivery scope

{{State_how_the_software_is_used_and_which_checkout_environment_or_release_this_guidance_covers.}}

**Procedure owner:** {{maintainer_team_or_existing_operating_reference}}.

## Update or delivery procedure

**Authoritative procedure:** {{existing_local_update_deployment_or_release_owner_or_short_procedure_below}}.

1. {{check_the_prerequisites_and_any_actual_project_required_approvals}}.
2. {{update_run_or_deliver_using_the_project_procedure}}.
3. {{verify_the_result_in_the_scope_being_described_and_record_required_evidence}}.

## Verification for this use

| When            | Relevant check                                      | Success signal | If it fails                     |
| --------------- | --------------------------------------------------- | -------------- | ------------------------------- |
| Before updating | {{applicable_dependency_data_or_delivery_check}}    | {{signal}}     | {{stop_or_recovery_action}}     |
| After updating  | {{applicable_run_behavior_or_service_health_check}} | {{signal}}     | {{recovery_or_incident_action}} |

## Recovery or rollback

{{State_when_and_how_to_recover_or_rollback_with_the_actual_constraints_or_procedure_owner.}}

**Data or compatibility considerations:** {{migration_state_backward_compatibility_or_recovery_constraint}}.

<!-- Keep this section only where distinct release/support commitments exist. -->

## Release and support commitments

**Supported scopes and evidence:** {{versions_environments_or_cohorts_and_actual_support_owner}}.

**Required release controls:** {{existing_approval_readiness_verification_and_rollback_requirements_or_their_owner}}.

**Escalation:** {{actual_support_or_incident_destination}}.

## Troubleshooting

| Symptom                         | First checks                                       | Resolution or escalation |
| ------------------------------- | -------------------------------------------------- | ------------------------ |
| {{observable_failure_or_alert}} | {{logs_metrics_dependency_or_configuration_check}} | {{safe_fix_or_owner}}    |
| {{another_symptom}}             | {{checks}}                                         | {{resolution}}           |
