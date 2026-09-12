<!--
Author notes: Adapt this for operators, maintainers, and support readers who run or recover the service. Update it after release, support, rollback, or troubleshooting procedures change; replace or retire it when an existing operational runbook is the maintained owner. Remove this comment after adaptation and omit irrelevant sections.
-->

# Operating {{project_name}}

## Service and support scope

{{State_which_service_environment_or_deployment_this_guidance_covers.}}

**Supported versions or environments:** {{supported_versions_environments_and_evidence_owner}}.

**Service owner and escalation path:** {{team_role_or_existing_incident_destination}}.

## Release procedure

1. {{confirm_approved_scope_version_and_release_evidence_requirements}}.
2. {{run_preflight_checks_and_record_their_results}}.
3. {{deploy_or_release_using_the_authoritative_delivery_procedure}}.
4. {{record_the_release_where_support_and_users_can_find_it}}.

## Preflight and post-release verification

| Stage        | Check                                               | Success signal | If it fails                     |
| ------------ | --------------------------------------------------- | -------------- | ------------------------------- |
| Preflight    | {{migration_dependency_capacity_or_approval_check}} | {{signal}}     | {{stop_or_escalation_action}}   |
| Post-release | {{health_user_journey_or_monitoring_check}}         | {{signal}}     | {{rollback_or_incident_action}} |

## Rollback

{{State_when_rollback_is_appropriate_and_the_safe_authoritative_procedure_or_destination.}}

**Data or compatibility considerations:** {{migration_state_backward_compatibility_or_recovery_constraint}}.

## Troubleshooting

| Symptom                         | First checks                                       | Resolution or escalation |
| ------------------------------- | -------------------------------------------------- | ------------------------ |
| {{observable_failure_or_alert}} | {{logs_metrics_dependency_or_configuration_check}} | {{safe_fix_or_owner}}    |
| {{another_symptom}}             | {{checks}}                                         | {{resolution}}           |
