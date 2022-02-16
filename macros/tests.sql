{% macro test(model_name, test_description) %}
    {% set test_description = test_description | default('(no description)') %}
    {% set test_info = caller() | trim %}
    {% set test_info_last_comma_removed = test_info[:-1] %}
    {% set test_info_json = fromjson('{' + test_info_last_comma_removed + '}') %}

    {% for k, v in test_info_json.items() %}
      {% set dummy = test_info_json.update({k: dbt_unit_testing.sql_decode(v)}) %}
    {% endfor %}
    
    {% set expectations = test_info_json['__EXPECTATIONS__'] %}
    {% set dummy = test_info_json.pop('__EXPECTATIONS__') %}

    {{ dbt_unit_testing.run_test(model_name, test_description, test_info_json, expectations)}}
{% endmacro %}

{% macro ref(name) %}
{%- if 'unit-test' in config.get('tags') -%}
    {{name}}
{%- else -%}
    {{builtins.ref(name)}}
{%- endif -%}
{% endmacro %}

{% macro source(source, table) %}
{%- if 'unit-test' in config.get('tags') -%}
    {{table}}
{%- else -%}
    {{builtins.source(source, table)}}
{%- endif -%}
{% endmacro %}

{% macro mock_ref(model_name) %}
    {{ dbt_unit_testing.mock_input(model_name, '', caller()) }}
{% endmacro %}

{% macro mock_source(source_name, model_name) %}
    {{ dbt_unit_testing.mock_input(model_name, source_name, caller()) }}
{% endmacro %}

{% macro mock_input(model_name, source_name, input_values_sql) %}
    {%- set model -%}
      {%- if source_name %}
        {{ builtins.source(source_name, model_name | string) }}
      {%- else -%}
        {{ builtins.ref(model_name) | string}}
      {%- endif -%}
    {%- endset -%}

    {% set model_sql %}
      {%- set extra_columns = dbt_unit_testing.extract_columns_difference('select * from ' + model + ' where false', input_values_sql) -%}
        select * from ({{ input_values_sql }}) as {{model_name}}_tmp_1 {{ ' ' }}
      {%- if extra_columns -%}
        left join (select {{ extra_columns }}
        from {{ model }}) as {{model_name}}_tmp_2 on false
      {%- endif -%}      
    {%- endset -%}
    
    {%- set input_as_json = '"' + model_name + '": "' + dbt_unit_testing.sql_encode(model_sql) + '",' -%}
    {% do return (input_as_json) %}

{% endmacro %}

{% macro expect() %}
    {%- set model_sql = caller() -%}
    {%- set input_as_json = '"__EXPECTATIONS__": "' + dbt_unit_testing.sql_encode(model_sql) + '",' -%}
    {% do return (input_as_json) %}
{% endmacro %}

{% macro run_test(model_name, test_description, test_inputs, expectations) %}
  {% set columns = dbt_unit_testing.extract_columns(expectations) %}

  {%- set test_sql -%}
    {% for m, m_sql in test_inputs.items() %}
      {%- if loop.first -%} {{ 'with ' }} {%- endif -%}
      {{ m }} as ({{ dbt_unit_testing.sql_decode(m_sql) }}),
    {% endfor %}
  
    expectations as ({{ expectations }}),

    {% set test_inputs_models = test_inputs.keys() | list %}

    expectations_with_count as (select {{columns}}, count(*) as count from expectations group by {{columns}}),

    actual as (select {{columns}}, count(*) as count from ( {{ dbt_unit_testing.build_model_complete_sql(model_name, test_inputs_models) }} ) as s group by {{columns}}),

    extra_entries as (
    select '+' as diff, count, {{columns}} from actual 
    except
    select '+' as diff, count, {{columns}} from expectations_with_count),

    missing_entries as (
    select '-' as diff, count, {{columns}} from expectations_with_count
    except
    select '-' as diff, count, {{columns}} from actual)
    
    select * from extra_entries
    UNION ALL 
    select * from missing_entries
  {% endset %}

  {% if execute %}
    {% set results = run_query(test_sql) %}
    {% set results_length = results.rows|length %}
    {% if results_length > 0 %}
      {%- do log('\x1b[31m' + 'MODEL: ' + model_name + '\x1b[0m', info=true) -%}
      {%- do log('\x1b[31m' + 'TEST:  ' + test_description + '\x1b[0m', info=true) -%}
      {% do results.print_table(max_columns=None, max_column_width=30) %}
    {% endif %}
    select 1 from (select 1) as t where {{ results_length }} != 0    
  {% endif %}
{% endmacro %}
