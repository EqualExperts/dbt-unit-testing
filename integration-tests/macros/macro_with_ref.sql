{% macro macro_with_ref() %}
  {% set dummy = dbt_unit_testing.ref('model_a') %}
{% endmacro %}
