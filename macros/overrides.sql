{% macro ref(project_or_package, model_name) %}
  {% if dbt_unit_testing.running_unit_test() %}
    {% set project_or_package, model_name = dbt_unit_testing.setup_project_and_model_name(project_or_package, model_name) %}
    {% set node_version = kwargs["version"] | default (kwargs["v"]) %}
    {% set node = {"package_name": project_or_package, "name": model_name, "version": node_version} %}
    {{ return (dbt_unit_testing.ref_cte_name(node)) }}
  {% else %}
    {% if model_name is undefined %}
      {{ return (builtins.ref(project_or_package, **kwargs)) }}
    {% else %}
      {{ return (builtins.ref(project_or_package, model_name, **kwargs)) }}
    {% endif %}
  {% endif %}
{% endmacro %}

{% macro source(source, table_name) %}
  {% if dbt_unit_testing.running_unit_test() %}
      {{ return (dbt_unit_testing.source_cte_name({"source_name": source, "name": table_name})) }}
  {% else %}
      {{ return (builtins.source(source, table_name)) }}
  {% endif %}
{% endmacro %}

{% macro is_incremental() %}
  {% if dbt_unit_testing.running_unit_test() %}
      {% set options = dbt_unit_testing.get_test_context("options", {}) %}
      {% set is_incremental_should_be_true_for_this_model = dbt_unit_testing.get_test_context("is_incremental_should_be_true_for_this_model", "") %}
      {% set model_being_rendered = dbt_unit_testing.get_test_context("model_being_rendered", "") %}
      {{ return (options.get("run_as_incremental", False) and model_being_rendered == is_incremental_should_be_true_for_this_model and model_being_rendered != "") }}
  {% else %}
      {{ return (dbt.is_incremental())}}
  {% endif %}
{% endmacro %}

{% macro running_unit_test() %}
  {{ return ('unit-test' in config.get('tags', {})) }}
{% endmacro %}

{% macro setup_project_and_model_name(project_or_package, model_name) %}
  {% set updated_project_or_package = project_or_package if model_name is defined else model.package_name %}
  {% set updated_model_name = model_name if model_name is defined else project_or_package %}
  {{ return((updated_project_or_package, updated_model_name)) }}
{% endmacro %}



