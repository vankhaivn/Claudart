<!--
Author notes: Adapt this for engineers and operators who need a current system-level synthesis. Update it when boundaries, components, integrations, or material risks change; replace or retire it when a maintained architecture source already covers this purpose. Remove this comment after adaptation and omit irrelevant sections.
-->

# {{project_name}} architecture

**Applies to:** {{system_revision_deployment_or_other_relevant_scope_and_evidence}}.

## System context

{{Describe_the_systems_primary_responsibility_and_its_place_in_the_larger_environment.}}

| Boundary                   | Responsibility     | Outside the boundary             |
| -------------------------- | ------------------ | -------------------------------- |
| {{system_or_service_name}} | {{owned_outcome}}  | {{external_owner_or_dependency}} |
| {{another_boundary}}       | {{responsibility}} | {{outside_scope}}                |

## Components

| Component             | Responsibility     | Interfaces or dependencies        | Source of truth              |
| --------------------- | ------------------ | --------------------------------- | ---------------------------- |
| {{component_name}}    | {{responsibility}} | {{api_queue_database_or_library}} | {{code_schema_or_reference}} |
| {{another_component}} | {{responsibility}} | {{dependency}}                    | {{owner}}                    |

## Key runtime flows

### {{flow_name}}

1. {{entrypoint_or_trigger}}.
2. {{component_interaction_and_important_decision}}.
3. {{persistent_or_external_effect_and_result}}.

### {{another_flow_or_remove_when_not_needed}}

{{Describe_the_relevant_flow_or_reference_its_canonical_runtime_documentation.}}

## Data and integrations

- **{{data_store_or_domain_data}}:** {{ownership_retention_or_consistency_boundary}}.
- **{{integration_name}}:** {{purpose_protocol_failure_or_authentication_boundary}}.
- **{{schema_or_contract_owner}}:** {{canonical_reference_destination}}.

## Current constraints and risks

- {{known_constraint_tradeoff_or_operational_limit_with_impact}}.
- {{material_risk_and_the_evidence_monitor_or_mitigation_owner}}.
- {{unknown_that_should_not_be_presented_as_architectural_fact}}.

## Approved design not yet implemented

{{Brief_gap_from_the_current_system_and_pointer_to_its_design_or_work_owner_or_remove_when_none}}.
