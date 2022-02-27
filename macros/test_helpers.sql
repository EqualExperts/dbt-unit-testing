{% macro extract_columns_list(query) %}
  {% if execute %}
    {% set results = run_query(query) %}
    {{ return(results.columns | map(attribute='name') | list) }}
  {% else %}
    {{ return([]) }}
  {% endif %}
{% endmacro %}

{% macro extract_columns_difference(cl1, cl2) %}
  {% set columns = cl1 | list | reject('in', cl2) | list %}
  {{ return(columns) }}
{% endmacro %}

{% macro sql_encode(s) %}
  {{ return (s.replace('"', '$$$$$$$$$$').replace('\n', '##########')) }}
{% endmacro %}

{% macro sql_decode(s) %}
  {{ return (s.replace('$$$$$$$$$$', '"').replace('##########', '\n')) -}}
{% endmacro %}

{% macro debug(value) %}
  {% do log (value, info=true) %}
{% endmacro %}

{% macro map(items, f) %}
  {% set mapped_items=[] %}
  {% for item in items %}
    {% do mapped_items.append(f(item)) %}
  {% endfor %}
  {{ return (mapped_items) }}
{% endmacro %}

{% macro node_by_id (node_id) %}
  {{ return (graph.nodes[node_id] if node_id.startswith('model') else graph.sources[node_id]) }}
{% endmacro %}

{% macro model_node (model_name) %}
  {{ return (graph.nodes["model." ~ project_name ~ "." ~ model_name]) }}
{% endmacro %}

{% macro source_node (source_name, model_name) %}
  {{ return (graph.sources["source." ~ project_name ~ "." ~ source_name ~ "." ~ model_name]) }}
{% endmacro %}

{% macro fake_source_sql(node) %}
  {% if node.columns %}
    {% set columns = [] %}
    {% for c in node.columns.values() %}
      {% do columns.append("cast(null as " ~ (c.data_type if c.data_type is not none else dbt_utils.type_string()) ~ ") as " ~ c.name) %}
    {% endfor %}
    select {{ columns | join (",") }}
  {% else %}
    {%- set source_sql -%}
      select * from {{ node.schema }}.{{ node.name }} where false
    {%- endset -%}
    select {{ dbt_unit_testing.extract_columns_list(source_sql) | join (",") }}
    from {{ node.schema }}.{{ node.name }}
    where false
  {% endif %}
{% endmacro %}