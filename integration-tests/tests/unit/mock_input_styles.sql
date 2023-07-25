{{
    config(
        tags=['unit-test', 'bigquery', 'snowflake', 'postgres']
    )
}}

{% call dbt_unit_testing.test('model_b_references_a', 'csv input') %}
  {% call dbt_unit_testing.mock_ref ('model_a', options={"input_format": "CSV"}) %}
    a,b
    0,'a'
    1,'b'
  {% endcall %}
  {% call dbt_unit_testing.expect({"input_format": "csv"}) %}
     a,b
    1,'b'
  {% endcall %}
{% endcall %}

UNION ALL
 
{% call dbt_unit_testing.test('model_b_references_a', 'csv input with type cast on columns') %}
  {% call dbt_unit_testing.mock_ref ('model_a', options={"input_format": "csv"}) %}
    a::numeric,b
    0,'a'
    1,'b'
  {% endcall %}
  {% call dbt_unit_testing.expect({"input_format": "csv"}) %}
     a,b
    1,'b'
  {% endcall %}
{% endcall %}

UNION ALL

{% call dbt_unit_testing.test('model_b_references_a', 'csv input with different separator') %}
  {% call dbt_unit_testing.mock_ref ('model_a', options={"input_format": "csv","column_separator": "|"}) %}
    a | b
    0 | 'a'
    1 | 'b'
  {% endcall %}
  {% call dbt_unit_testing.expect({"input_format": "csv","column_separator": "|"}) %}
    a | b
    1 | 'b'
  {% endcall %}
{% endcall %}