{{
    config(
        tags=['unit-test', 'bigquery']
    )
}}

{% call dbt_unit_testing.test(
            'model_bq_struct',
            'when table contains struct then compares actual to expected successfully',
            options={"columns_to_json": ["my_struct"]}
        ) %}
  {% call dbt_unit_testing.mock_ref ('model_bq_struct_stub') %}
    select 1 as a, struct('b' as b, true as c) as my_struct
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 1 as a, struct('b' as b, true as c) as my_struct
  {% endcall %}
{% endcall %}
