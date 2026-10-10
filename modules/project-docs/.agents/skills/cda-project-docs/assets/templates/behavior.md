<!--
Author notes: Adapt one copy per meaningful capability, for readers implementing, testing, using, or reviewing its agreed behavior. Update when approved rules or evidenced behavior change; replace or retire it when a maintained contract, API reference, or domain source is the better owner. Current behavior may describe a checked main commit or actual local use. Add distinct delivery/support scopes only where useful; keep real team commitments. Remove author comments and irrelevant sections after adaptation.
-->

# {{capability_name}}

## Purpose and scope

{{Explain_the_user_or_system_outcome_and_the_boundary_of_this_capability.}}

**Applies to:** {{actors_versions_tenants_or_conditions}}.

**Does not cover:** {{explicit_neighboring_behavior_or_non_goal}}.

## Agreed behavior

{{State_the_approved_behavior_in_clear_terms.}}

### Main flow

1. {{actor_or_system_starts_with_a_valid_trigger}}.
2. {{system_validates_or_decides_using_the_relevant_rule}}.
3. {{system_completes_the_outcome_and_exposes_the_result}}.

### Business rules

| Rule             | Expected result       | Authority                               |
| ---------------- | --------------------- | --------------------------------------- |
| {{rule_name}}    | {{required_behavior}} | {{approved_product_or_contract_source}} |
| {{another_rule}} | {{result}}            | {{source}}                              |

## Errors and edge cases

| Situation                                                  | Expected response         | User or operator guidance          |
| ---------------------------------------------------------- | ------------------------- | ---------------------------------- |
| {{invalid_input_missing_permission_or_dependency_failure}} | {{safe_visible_behavior}} | {{message_recovery_or_escalation}} |
| {{boundary_or_concurrent_case}}                            | {{expected_behavior}}     | {{guidance}}                       |

## Quality expectations

- {{verifiable_reliability_security_privacy_accessibility_or_performance_expectation}}.
- {{observable_acceptance_condition_or_testable_invariant}}.

## Current behavior

{{Describe_actual_behavior_in_this_scope_and_any_gap_against_the_agreed_behavior.}}

**Evidence and scope:** {{branch_commit_checkout_or_environment_with_source_checks_or_observation_and_what_they_establish}}.

<!-- Omit this section when current behavior already covers the only relevant scope. -->

## Other delivery or support scopes

| Scope                             | Actual behavior and limits           | Delivery or support evidence                           |
| --------------------------------- | ------------------------------------ | ------------------------------------------------------ |
| {{version_environment_or_cohort}} | {{evidenced_behavior_in_this_scope}} | {{deployment_release_or_support_evidence_destination}} |

## Approved change not yet delivered

{{Briefly_describe_the_reader_relevant_gap_and_link_the_owning_task_or_spec.}}

## Verification and remaining limits

{{Link_tests_or_other_checks_for_the_agreed_rules_and_quality_expectations_and_state_any_unverified_claim.}}
