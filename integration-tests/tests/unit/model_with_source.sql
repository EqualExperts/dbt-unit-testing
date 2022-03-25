{{
    config(
        tags=['unit-test']
    )
}}

{% call dbt_unit_testing.test('model_with_source', 'sample test') %}
  {% call dbt_unit_testing.mock_source ('dbt_unit_testing','sample_source') %}
    select 0 as source_a, 'a' as source_b
    UNION
    select 1 as source_a, 'b' as source_b
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as source_a, 'b' as source_b
  {% endcall %}
{% endcall %}
 