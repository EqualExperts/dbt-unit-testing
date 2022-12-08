{% macro build_model_complete_sql(model_node, mocks=[], options={}) %}
  {% set models_to_exclude = mocks | rejectattr("options.include_missing_columns", "==", true) | map(attribute="unique_id") | list %}

  {# when using the database models, there is no need to build full lineage #}
  {% set build_full_lineage = not options.use_database_models %}

  {% set model_dependencies = dbt_unit_testing.build_model_dependencies(model_node, models_to_exclude, build_full_lineage) %}

  {% set cte_dependencies = [] %}
  {% for node_id in model_dependencies %}
    {% set node = dbt_unit_testing.node_by_id(node_id) %}
    {% set mock = mocks | selectattr("unique_id", "==", node_id) | first %}
    {% set cte_name = dbt_unit_testing.cte_name(mock if mock else node) %}
    {% set cte_sql = mock.input_values if mock else dbt_unit_testing.build_node_sql(node, use_database_models=options.use_database_models) %}
    {% set cte = dbt_unit_testing.quote_identifier(cte_name) ~ " as (" ~ cte_sql ~ ")" %}
    {% set cte_dependencies = cte_dependencies.append(cte) %}
  {%- endfor -%}

  {%- set model_complete_sql -%}
    {% if cte_dependencies %}
      with
      {{ cte_dependencies | join(",\n") }}
    {%- endif -%}
    {{ "\n" }}
    select * from ({{ dbt_unit_testing.render_node(model_node) }} {{ "\n" }} ) as t
  {%- endset -%}

  {% do return(model_complete_sql) %}
{% endmacro %}

{% macro cte_name(node) %}
  {% if node.resource_type in ('source') %}
    {{ return (dbt_unit_testing.source_cte_name(node.source_name, node.name)) }}
  {% else %}
    {{ return (dbt_unit_testing.ref_cte_name(node.name)) }}
  {% endif %}
{% endmacro %}

{% macro ref_cte_name(model_name) %}
  {{ return (dbt_unit_testing.quote_identifier(model_name)) }}
{% endmacro %}

{% macro source_cte_name(source, table_name) %}
  {%- set cte_name -%}
    {%- if dbt_unit_testing.config_is_true("use_qualified_sources") -%}
      {%- set source_node = dbt_unit_testing.source_node(source, table_name) -%}
      {{ [source, table_name] | join("__") }}
    {%- else -%}
      {{ table_name }}
    {%- endif -%}
  {%- endset -%}
  {{ return (dbt_unit_testing.quote_identifier(cte_name)) }}
{% endmacro %}

{% macro build_model_dependencies(node, models_to_exclude, build_full_lineage=True) %}

  {% set model_dependencies = [] %}
  {% for node_id in node.depends_on.nodes %}
    {% set node = dbt_unit_testing.node_by_id(node_id) %}
    {% if node.unique_id not in models_to_exclude %}
      {% if node.resource_type in ('model','snapshot') and build_full_lineage %}
        {% set child_model_dependencies = dbt_unit_testing.build_model_dependencies(node) %}
        {% for dependency_node_id in child_model_dependencies %}
          {{ model_dependencies.append(dependency_node_id) }}
        {% endfor %}
      {% endif %}
    {% endif %}
    {{ model_dependencies.append(node_id) }}
  {% endfor %}

  {{ return (model_dependencies | unique | list) }}
{% endmacro %}

{% macro build_node_sql(node, complete=false, use_database_models=false) %}
  {%- if use_database_models or node.resource_type in ('source', 'seed') -%}
    {%- if node.resource_type == "source" %}
      {% set name = node.identifier %}
    {%- elif node.resource_type == "snapshot" %}
      {%- if node.config.alias is not none %}
        {% set name = node.config.alias %}
      {%- else %}
        {% set name = node.name %}
      {%- endif %}
    {%- else %}
      {% set name = node.name %}
    {%- endif %}

    select * from {{ dbt_unit_testing.quote_identifier(node.database) ~ '.' ~ dbt_unit_testing.quote_identifier(node.schema) ~ '.' ~ dbt_unit_testing.quote_identifier(name) }} where false
  {%- else -%}
    {% if complete %}
      {{ dbt_unit_testing.build_model_complete_sql(node) }}
    {%- else -%}
      {{ dbt_unit_testing.render_node(node) ~ "\n"}}
    {%- endif -%}
  {%- endif -%}
{% endmacro %}
