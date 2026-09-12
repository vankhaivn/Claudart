<!--
Author notes: Adapt this for contributors who need to set up, run, check, and change the project safely. Update it when repository tooling or the contributor workflow changes; replace or retire it when maintained repository instructions already own these details. Remove this comment after adaptation and omit irrelevant sections.
-->

# Developing {{project_name}}

## Prerequisites

- {{required_runtime_version_or_platform}}.
- {{required_local_service_tool_or_access_level}}.
- {{configuration_template_or_documented_secret_management_destination}}.

## Setup

1. {{obtain_the_source_using_the_project_workflow}}.
2. {{install_dependencies_or_bootstrap_the_environment}}.
3. {{configure_non_secret_local_requirements}}.

## Run and check

| Goal                                 | Command or procedure | Expected result                    |
| ------------------------------------ | -------------------- | ---------------------------------- |
| Start locally                        | `{{start_command}}`  | {{local_endpoint_or_ready_signal}} |
| Run focused tests                    | `{{test_command}}`   | {{expected_test_scope}}            |
| Validate formatting or static checks | `{{check_command}}`  | {{expected_quality_gate}}          |
| Build or package                     | `{{build_command}}`  | {{artifact_or_completion_signal}}  |

## Testing strategy

- {{where_unit_integration_end_to_end_or_contract_tests_belong}}.
- {{test_data_fixture_or_external_dependency_guidance}}.
- {{what_must_be_verified_for_a_change_in_this_project}}.

## Repository tooling and workflow

- **Code conventions:** {{authoritative_style_or_lint_reference}}.
- **Change workflow:** {{branch_review_task_or_spec_reference}}.
- **Documentation ownership:** {{router_or_maintenance_reference_for_current_claims}}.
- **Troubleshooting local setup:** {{existing_support_or_operations_destination}}.
