{% macro build_model_complete_sql(model_node, mocks=[], options={}) %}
  {% set mock_ids = mocks | rejectattr("options.include_missing_columns", "==", true) | map(attribute="unique_id") | list %}
  {% set only_direct_dependencies = options.use_database_models %}
  {% set model_dependencies = dbt_unit_testing.build_model_dependencies(model_node, mock_ids, only_direct_dependencies) %}
  -- {# add mocks that are not in model dependencies (to allow for mocking the model itself, when testing incremental models) #}
  {% set model_dependencies = model_dependencies + mocks | map(attribute="unique_id") | reject('in', model_dependencies) | list %}

  {% set cte_dependencies = [] %}
  {% for node_id in model_dependencies %}
    {% set node = dbt_unit_testing.node_by_id(node_id) %}
    {% set existing_mock = mocks | selectattr("unique_id", "==", node_id) | first %}
    {% set cte_sql = existing_mock.input_values if existing_mock else dbt_unit_testing.build_node_sql(node, options.use_database_models) %}
    {% set cte_name = dbt_unit_testing.cte_name(existing_mock if existing_mock else node) %}
    {% set cte = dbt_unit_testing.quote_identifier(cte_name) ~ " as (" ~ cte_sql ~ ")" %}
    {% set cte_dependencies = cte_dependencies.append(cte) %}
  {%- endfor -%}

  {% set rendered_node = dbt_unit_testing.render_node_for_model_being_tested(model_node) %}
  {%- set model_complete_sql -%}
    {% if cte_dependencies %}
      with
      {{ cte_dependencies | join(",\n") }}
    {%- endif -%}
    {{ "\n" }}
    select * from ({{ rendered_node }} {{ "\n" }} ) as t
  {%- endset -%}

  {{ return(model_complete_sql) }}
{% endmacro %}

{% macro cte_name(node) %}
  {% if node.resource_type in ('source') %}
    {{ return (dbt_unit_testing.source_cte_name(node)) }}
  {% else %}
    {{ return (dbt_unit_testing.ref_cte_name(node)) }}
  {% endif %}
{% endmacro %}

{% macro ref_cte_name(node) %}
  {% set node = dbt_unit_testing.model_node(node) %}
  {% set parts = ["DBT_CTE", node.name] %}
  {% if node.package_name != model.package_name %}
    {% set parts = [node.package_name] + parts %}
  {% endif %}
  {% if dbt_unit_testing.has_value(node.version)%}
    {% set parts = parts + [node.version] %}
  {% endif %}
  {{ return (dbt_unit_testing.quote_identifier(parts | join("__"))) }}
{% endmacro %}

{% macro source_cte_name(node) %}
  {%- set cte_name -%}
    {%- if dbt_unit_testing.config_is_true("use_qualified_sources") -%}
      {%- set source_node = dbt_unit_testing.source_node(node) -%}
      {{ [source_node.source_name, source_node.name] | join("__") }}
    {%- else -%}
      {{ node.name }}
    {%- endif -%}
  {%- endset -%}
  {{ return (dbt_unit_testing.quote_identifier(cte_name)) }}
{% endmacro %}

{% macro build_model_dependencies(node, stop_recursion_at_these_dependencies, only_direct_dependencies=False) %}
  {% set model_dependencies = [] %}
  {% for node_id in node.depends_on.nodes %}
    {% set node = dbt_unit_testing.node_by_id(node_id) %}
    {% if node.resource_type in ('model','snapshot') and node.unique_id not in stop_recursion_at_these_dependencies and not only_direct_dependencies%}
      {% set child_model_dependencies = dbt_unit_testing.build_model_dependencies(node, stop_recursion_at_these_dependencies, only_direct_dependencies) %}
      {% for dependency_node_id in child_model_dependencies %}
        {{ model_dependencies.append(dependency_node_id) }}
      {% endfor %}
    {% endif %}
    {{ model_dependencies.append(node_id) }}
  {% endfor %}

  {{ return (model_dependencies | unique | list) }}
{% endmacro %}

{% macro build_node_sql(node, use_database_models=false, complete=false) %}
  {%- if use_database_models or node.resource_type in ('source', 'seed') -%}
    {%- if node.resource_type == "source" %}
      {% set name = node.identifier %}
    {%- elif node.resource_type == "snapshot" %}
      {%- if dbt_unit_testing.has_value(node.config.alias) %}
        {% set name = node.config.alias %}
      {%- else %}
        {% set name = node.name %}
      {%- endif %}
    {%- else %}
      {% set name = node.name %}
    {%- endif %}

    {% set name_parts = dbt_unit_testing.map([node.database, node.schema, name], dbt_unit_testing.quote_identifier) %}
    select * from {{ name_parts | join('.') }} where 1 = 0
  {%- else -%}
    {% if complete %}
      {{ dbt_unit_testing.build_model_complete_sql(node) }}
    {%- else -%}
      {{ dbt_unit_testing.render_node(node) ~ "\n"}}
    {%- endif -%}
  {%- endif -%}
{% endmacro %}

{% macro render_node(node) %}
  {% set model_sql = node.raw_sql if node.raw_sql is defined else node.raw_code %}
  {{ return (render(model_sql)) }}
{% endmacro %}
     
{% macro render_node_for_model_being_tested(node) %}
  {% set model_sql = node.raw_sql if node.raw_sql is defined else node.raw_code %}
  {% set model_name = dbt_unit_testing.cte_name(node) %}
  {% set this_name = this | string %}
  -- {# If the model contains a 'this' property, we will replace its result with the name of the model being tested #}
  -- {# but first we mask previous occurrences that could be there before the render (very unlikely to happen) #}
  -- {# This way we 'ensure' that we only replace stuff produced after the render #}
  {% set replace_mask = '######################' %}
  {% set model_sql = model_sql.replace(this_name, replace_mask) %}
  {{ dbt_unit_testing.set_test_context("model_being_rendered", model_name) }}
  {% set rendered_sql = render(model_sql) %}
  {{ dbt_unit_testing.set_test_context("model_being_rendered", "") }}
  {% set rendered_sql = rendered_sql.replace(this_name, model_name) %}
  {% set rendered_sql = rendered_sql.replace(replace_mask, this_name) %}
  {{ return (rendered_sql) }}
{% endmacro %}

