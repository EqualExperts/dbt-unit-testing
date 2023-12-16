{{
    config(
        tags=['unit-test', 'bigquery']
    )
}}

{% call dbt_unit_testing.test(
            'model_bq_array',
            'when table contains struct then compares actual to expected successfully',
            options={"columns_to_json": ["my_array"]}
        )
%}

  {% call dbt_unit_testing.mock_ref ('model_bq_array_stub') %}
    select True as my_bool, [1,2,3] as my_array
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select True as my_bool, [1,2,3] as my_array
  {% endcall %}
{% endcall %}
