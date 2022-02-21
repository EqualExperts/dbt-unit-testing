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

{% macro build_input_values_sql(input_values, options) %}
    {% set unit_tests_config = var("unit_tests_config", {}) %}
    {% set input_format = options.get("input_format", unit_tests_config.get("input_format", "sql")) %}

    {% set input_values_sql = input_values %}

    {% if input_format == "csv" %}
      {% set input_values_sql = dbt_unit_testing.sql_from_csv_input(input_values, options) %}
    {%- endif -%}

    {% do return (input_values_sql) %}
{% endmacro %}

{% macro mock_ref(model_name, options={}) %}
    {{dbt_unit_testing. mock_input(model_name, '', caller(), options) }}
{% endmacro %}

{% macro mock_source(source_name, model_name, options={}) %}
    {{ dbt_unit_testing.mock_input(model_name, source_name, caller(), options) }}
{% endmacro %}

{% macro mock_input(model_name, source_name, input_values, options) %}

  {% if execute %}
    {% set input_values_sql = dbt_unit_testing.build_input_values_sql(input_values, options) %}

    {% set model_sql %}
      {% set node = graph.sources["source." + project_name + "." + source_name + "." + model_name] if source_name else  graph.nodes["model." + project_name + "." + model_name]  %}
      {% set model_columns = node.columns.keys() %}
      {% set extra_columns = dbt_unit_testing.extract_columns_difference_as_nulls(model_columns | list, input_values_sql).lstrip() %}

      {% if extra_columns %}
        {% set extra_columns = extra_columns[:-1] + " " %}
      {% endif%}
        select * {{ ' ' }} 
        {%- if extra_columns -%}
        , {{extra_columns}} 
        {%- endif -%}
        from ({{ input_values_sql }}) as {{model_name}}_tmp_1 {{ ' ' }} 
    {%- endset -%}
    {%- set input_as_json = '"' + model_name + '": "' + dbt_unit_testing.sql_encode(model_sql) + '",' -%}
    {% do return (input_as_json) %}
  {% endif %}
{% endmacro %}

{% macro expect(options={}) %}
    {%- set model_sql = dbt_unit_testing.build_input_values_sql(caller(), options) -%}
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
    {{dbt_unit_testing.sql_except()}}
    select '+' as diff, count, {{columns}} from expectations_with_count),

    missing_entries as (
    select '-' as diff, count, {{columns}} from expectations_with_count
    {{dbt_unit_testing.sql_except()}}
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
