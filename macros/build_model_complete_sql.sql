{% macro build_model_complete_sql(model_name, test_inputs, include_sources=false) %}
  {% if execute %}
    {% set node = dbt_unit_testing.model_node(model_name) %}
    {{ return (dbt_unit_testing.build_complete_sql_for_node(node, test_inputs, iinclude_sources)) }}
  {% endif %}
{% endmacro %}

{% macro build_complete_sql_for_node(node, test_inputs, include_sources) %}

    {% set dependencies = [] %}
    {% if node.depends_on and node.depends_on.nodes %}
      {% set dependencies = node.depends_on.nodes | unique %}
    {% endif %}
    {% set dependencies_without_inputs = [] %}
    {%- for d in dependencies -%}
      {% set node = dbt_unit_testing.node_by_id(d) %}
      {%- if node.name not in test_inputs -%}
        {{ dependencies_without_inputs.append(d) }}
      {%- endif -%}
    {%- endfor %}

    {%- set node_complete_sql -%}
      {%- for d in dependencies_without_inputs -%}
        {%- if loop.first -%}
          {{ 'with ' }}
        {%- endif -%}
        {% set dependency_node = dbt_unit_testing.node_by_id(d) %}
          {{ dependency_node.name }} as (
            {{ dbt_unit_testing.build_complete_sql_for_node(dependency_node, test_inputs, include_sources) }}
          )
        {%- if not loop.last -%}
          ,
        {%- endif -%}
      {%- endfor %}

      select * from (
      {%- if node.resource_type == 'model' -%}
          {{ render(node.raw_sql) }}
      {%- else -%}
          {{ dbt_unit_testing.fake_source_sql(node) }}
      {%- endif -%}
      ) as model_tmp

    {%- endset -%}

    {{ return (node_complete_sql) }}

{% endmacro %}

