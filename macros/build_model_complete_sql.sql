{% macro build_model_complete_sql(model_name, test_inputs) %}
  {% if execute %}
    {% set node = dbt_unit_testing.model_node(model_name) %}

    {% set model_dependencies = dbt_unit_testing.build_model_dependencies(node) %}
    {% set model_dependencies_not_in_mocked_inputs = [] %}
    {%- for d in model_dependencies -%}
      {% set node = dbt_unit_testing.node_by_id(d) %}
      {%- if node.name not in test_inputs -%}
        {{ model_dependencies_not_in_mocked_inputs.append(d) }}
      {%- endif -%}
    {%- endfor %}

    {%- set cte_with_dependencies -%}
      {%- for d in model_dependencies_not_in_mocked_inputs -%}
        {%- if loop.first -%}
          {{ 'with ' }}
        {%- endif -%}
        {% set node = dbt_unit_testing.node_by_id(d) %}
          {{ node.name }} as (
        {%- if node.resource_type == 'model' -%}
            {{ render(node.raw_sql) }}
        {%- elif node.resource_type == 'seed' -%}
            {{ dbt_unit_testing.fake_seed_sql(node) }}
        {%- else -%}
            {{ dbt_unit_testing.fake_source_sql(node) }}
        {%- endif -%}
          )
        {%- if not loop.last -%}
          ,
        {%- endif -%}
      {%- endfor %}
    {%- endset -%}

    {%- set full_sql -%}
      {{ cte_with_dependencies }}
      select * from ({{ render(node.raw_sql) }}) as tmp
    {%- endset -%}

    {{ return (full_sql) }}

  {%- endif -%}

{% endmacro %}

{% macro build_model_dependencies(node) %}
  {% set model_dependencies = [] %}
  {% for d in node.depends_on.nodes %}
    {% set node = dbt_unit_testing.node_by_id(d) %}
    {% if node.resource_type == 'model' %}
      {% set child_model_dependencies = dbt_unit_testing.build_model_dependencies(node) %}
      {% for cmd in child_model_dependencies %}
        {{ model_dependencies.append(cmd) }}
      {% endfor %}
    {% endif %}
    {{ model_dependencies.append(d) }}
  {% endfor %}

  {{ return (model_dependencies | unique | list) }}

{% endmacro %}
