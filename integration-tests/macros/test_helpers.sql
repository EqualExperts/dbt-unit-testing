{% macro test_should_fail (model_name, test_description) %}
  {% set test_info = caller() %}
  {{ dbt_unit_testing.ref_tested_model(model_name) }}
  {% if execute %}
    {% set query = dbt_unit_testing._test(model_name, test_description, test_info, {"hide_errors": true}) %}
    {% set r1 = run_query(query) %}
    {% set r1_count = r1.rows | length %}

    {% set failed = r1_count > 0 %}

    {% if not failed %}
        {%- do log('\x1b[31m' ~ 'Test: "' ~ test_description ~ '" should have FAILED' ~ '\x1b[0m', info=true) -%}
    {% endif %}
    select 1 from (select 1) as t where {{ not failed }}
  {% endif %}
{% endmacro %}
