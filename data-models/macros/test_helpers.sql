{% macro extract_columns_cast(query) %}

{% set results = run_query(query) %}

{% if execute %}
  {%- for column in results.columns -%}
  CAST({{column.name}} AS STRING) as {{column.name}}
  {%- if not loop.last -%}
  ,
  {%- endif -%}
  {% endfor %}
{%- endif -%}

{% endmacro %}

{% macro extract_columns(query) %}

{% set results = run_query(query) %}

{% if execute %}
  {%- for column in results.columns -%}
  {{column.name}}
  {%- if not loop.last -%}
  ,
  {%- endif -%}
  {% endfor %}
{%- endif -%}

{% endmacro %}

{% macro extract_sql_from_model(relation_name) %}
  {% if execute %}
    {% set node = graph.nodes["model." + project_name + "." + relation_name] %}
    {% set final_sql = render(node.raw_sql) %}
    {{ final_sql }}
  {%- endif -%}  
{% endmacro %}

{% macro ref(name) %}
{% if 'unit-test' in config.get('tags') %}
    {{name}}
{% else %}
    {{builtins.ref(name)}}
{% endif %}
{% endmacro %}

{% macro source(dataset,name) %}
{% if 'unit-test' in config.get('tags') %}
    {{name}}
{% else %}
    {{builtins.source(dataset,name)}}
{% endif %}
{% endmacro %}


{% macro unit_test(inputs, expectations) %}
{% set table_name = config.get('model_under_test') %}
{% set columns = extract_columns(expectations) %}
{% set test_sql %}
with 
{% if inputs %}
{{ inputs }},
{% endif %}
expectations as ({{ expectations }}),
expectations_with_count as (select {{columns}}, count(*) as count from expectations group by {{columns}}),

actual as (select {{columns}}, count(*) as count from ({{ extract_sql_from_model(table_name) }}) as s group by {{columns}}),

extra_entries as (
select '+' as diff, count, {{columns}} from actual 
except distinct
select '+' as diff, count, {{columns}} from expectations_with_count),

missing_entries as (
select '-' as diff, count, {{columns}} from expectations_with_count
except distinct
select '-' as diff, count, {{columns}} from actual)
 
select * from extra_entries
union all 
select * from missing_entries
{% endset %}

{% if execute %}
  {% set results = run_query(test_sql) %}
  {% set results_length = results.rows|length %}
  {% if results_length > 0 %}
    {% do results.print_table(max_columns=None, max_column_width=30) %}
  {% endif %}
  select {{results_length}}
  except distinct
  select 0
{% endif %}
{% endmacro %}
