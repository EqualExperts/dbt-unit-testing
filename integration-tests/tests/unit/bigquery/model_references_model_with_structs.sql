{{
    config(
        tags=['unit-test', 'bigquery']
    )
}}

{% set column_transformations = {
  "b": "to_json_string(b)"
  }
%}

{% call dbt_unit_testing.test('model_references_model_with_structs', options={"column_transformations": column_transformations}) %}
  {% call dbt_unit_testing.mock_ref ('model_with_structs') %}
    select [1, 2, 3] as a, struct(1 as f1, "f2" as f2) as b, 3 as c, "value" as d
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select [1, 2, 3] as a, struct(1 as f1, "f2" as f2) as b, 3 as c, "value" as d
  {% endcall %}
{% endcall %}
 