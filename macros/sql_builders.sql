{% macro build_model_complete_sql(model_node, mocks=[], options={}) %}
  {% set models_to_exclude = mocks | rejectattr("options.include_extra_columns", "==", true) | map(attribute="unique_id") | list %}
  {% set model_dependencies = dbt_unit_testing.build_model_dependencies(model_node, models_to_exclude) %}

  {% set cte_dependencies = [] %}
  {% for node_id in model_dependencies %}
    {% set node = dbt_unit_testing.node_by_id(node_id) %}
    {% set mock = mocks | selectattr("unique_id", "==", node_id) | first %}
    {% set cte_name = mock.cte_name if mock else node.name %}
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
    select * from ({{ render(model_node.raw_sql) }}) as t
  {%- endset -%}

  {% do return(model_complete_sql) %}
{% endmacro %}

{% macro ref_cte_name(model_name) %}
  {{ return (dbt_unit_testing.quote_identifier(model_name)) }}
{% endmacro %}

{% macro source_cte_name(_source, table_name) %}
  {{ return (dbt_unit_testing.quote_identifier(table_name)) }}
{% endmacro %}

{% macro build_model_dependencies(node, models_to_exclude) %}
  {% set model_dependencies = [] %}
  {% for node_id in node.depends_on.nodes %}
    {% set node = dbt_unit_testing.node_by_id(node_id) %}
    {% if node.unique_id not in models_to_exclude %}
      {% if node.resource_type in ('model','snapshot') %}
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
    {% set name = node.identifier if node.resource_type == "source" else node.name %}
    select * from {{ dbt_unit_testing.quote_identifier(node.database) ~ '.' ~ dbt_unit_testing.quote_identifier(node.schema) ~ '.' ~ dbt_unit_testing.quote_identifier(name) }} where false
  {%- else -%}
    {% if complete %}
      {{ dbt_unit_testing.build_model_complete_sql(node) }}
    {%- else -%}
      {{ render(node.raw_sql) }}
    {%- endif -%}
  {%- endif -%}
{% endmacro %}
