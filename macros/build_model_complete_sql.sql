{% macro build_model_complete_sql(model_name, test_inputs, include_sources=false) %}
  {% if execute %}
    {% set node = dbt_unit_testing.model_node(model_name) %}

    {% set depends_on = dbt_unit_testing.build_model_dependencies(node, include_sources) %}
    {% set depends_on_without_inputs = [] %}
    {%- for d in depends_on -%}
      {% set node = dbt_unit_testing.node_by_id(d) %}
      {%- if node.name not in test_inputs -%}
        {{ depends_on_without_inputs.append(d) }}
      {%- endif -%}
    {%- endfor %}

    {%- set sql_with_dependencies -%}
      {%- for d in depends_on_without_inputs -%}
        {%- if loop.first -%}
          {{ 'with ' }}
        {%- endif -%}
        {% set node = dbt_unit_testing.node_by_id(d) %}
          {{ node.name }} as (
        {%- if node.resource_type == 'model' -%}
            {{ render(node.raw_sql) }}
        {%- else -%}
          {% if include_sources %}
            {{ dbt_unit_testing.fake_source_sql(node) }}
          {%- endif -%}
        {%- endif -%}
          )
        {%- if not loop.last -%}
          ,
        {%- endif -%}
      {%- endfor %}
    {%- endset -%}

    {%- set full_sql -%}
      {{ sql_with_dependencies }}
      select * from ({{ render(node.raw_sql) }}) as tmp
    {%- endset -%}

    {{ return (full_sql) }}

  {%- endif -%}

{% endmacro %}

{% macro build_model_dependencies(node, include_sources) %}
  {% set model_dependencies = [] %}
  {% for d in node.depends_on.nodes %}
    {% set node = dbt_unit_testing.node_by_id(d) %}
    {% if node.resource_type == 'model' %}
      {% set child_model_dependencies = dbt_unit_testing.build_model_dependencies(node, include_sources) %}
      {% for cmd in child_model_dependencies %}
        {{ model_dependencies.append(cmd) }}
      {% endfor %}
      {{ model_dependencies.append(d) }}
    {% else %}
      {% if include_sources %}
        {{ model_dependencies.append(d) }}
      {% endif %}
    {% endif %}
  {% endfor %}

  {{ return (model_dependencies | unique | list) }}

{% endmacro %}
