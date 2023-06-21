{% macro ref(model_name) %}
  {% if dbt_unit_testing.running_unit_test() %}
      {{ return (dbt_unit_testing.ref_cte_name(model_name)) }}
  {% else %}
      {{ return (builtins.ref(model_name)) }}
  {% endif %}
{% endmacro %}

{% macro source(source, table_name) %}
  {% if dbt_unit_testing.running_unit_test() %}
      {{ return (dbt_unit_testing.source_cte_name(source, table_name)) }}
  {% else %}
      {{ return (builtins.source(source, table_name)) }}
  {% endif %}
{% endmacro %}

{% macro is_incremental() %}
  {% if dbt_unit_testing.running_unit_test() %}
      {% set options = dbt_unit_testing.get_test_context("options", {}) %}
      {% set model_being_tested = dbt_unit_testing.get_test_context("model_being_tested", "") %}
      {% set model_being_rendered = dbt_unit_testing.get_test_context("model_being_rendered", "") %}
      {{ return (options.get("run_as_incremental", False) and model_being_rendered == model_being_tested and model_being_rendered != "") }}
  {% else %}
      {{ return (dbt.is_incremental())}}
  {% endif %}
{% endmacro %}
