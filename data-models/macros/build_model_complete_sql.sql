{% macro build_model_complete_sql(model_name, test_inputs) %}
  {% if execute %}
    {% set node = graph.nodes["model." + project_name + "." + model_name] %}

    {% set depends_on = build_depends_on(node) %}
    {% set depends_on_filtered = [] %}
    {%- for d in depends_on -%}
      {% set model_name = d.split('.')[2] %}
      {%- if model_name not in test_inputs -%}
        {% do depends_on_filtered.append(d) %}
      {%- endif -%}
    {%- endfor %}

    {%- set sql_with_dependencies -%}
      {%- for d in depends_on_filtered -%}
        {%- if loop.first -%}
          {{ 'with ' }}
        {%- endif -%}
        {% set model_name = d.split('.')[2] %}
          {{ model_name }} as (
            {{ render(graph.nodes[d].raw_sql) }}
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

    {{ full_sql }}

  {%- endif -%}

{% endmacro %}

{% macro build_depends_on(node, depends_list) %}
  {% set depends_list = [] %}
  {%- for d in node.depends_on.nodes -%}
    {% if d.startswith('model') %}
      {% set new_depends_list = build_depends_on(graph.nodes[d]) %}
      {%- for dd in new_depends_list -%}
        {%- do depends_list.append(dd) -%}
      {%- endfor -%}
      {%- do depends_list.append(d) -%}
    {% endif %}
  {%- endfor -%}

  {% do return (depends_list | unique | list) %}

{% endmacro %}
