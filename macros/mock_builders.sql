{% macro mock_ref(model_name, options={}) %}
    {{ dbt_unit_testing.mock_input(model_name, '', caller(), options) }}
{% endmacro %}

{% macro mock_source(source_name, model_name, options={}) %}
    {{ dbt_unit_testing.mock_input(model_name, source_name, caller(), options) }}
{% endmacro %}

{% macro mock_input(model_name, source_name, input_values, options) %}
  {% if execute %}
    {% set mocking_strategy = dbt_unit_testing.get_mocking_strategy(options) %}
    {% set input_values_sql = dbt_unit_testing.build_input_values_sql(input_values, options) %}
    {% set mock_sql %}
      {%- if mocking_strategy.pure -%}
        {{input_values_sql}}
      {%- else -%}  
        {{ dbt_unit_testing.enrich_mock_sql_with_extra_columns(model_name, source_name, input_values_sql, options, mocking_strategy)}} 
      {%- endif -%}
    {%- endset -%}

    {%- if source_name == '' -%}
      {%- set model_key = model_name -%}
    {%- else -%}
      {%- set model_key = [source_name, model_name]|join('__') -%}
    {%- endif -%}

    {% set input_as_json = '"' ~ model_key  ~ '": "' ~ dbt_unit_testing.sql_encode(mock_sql) ~ '",' %}
    {{ return (input_as_json) }}
  {% endif %}
{% endmacro %}

{% macro enrich_mock_sql_with_extra_columns(model_name, source_name, input_values_sql, options, mocking_strategy) %}

  {% set model_node = dbt_unit_testing.graph_node(source_name, model_name) %}

  {% set options = {"fetch_mode": 'DATABASE' if mocking_strategy.database else 'FULL' } %}
  {% set full_node_sql = dbt_unit_testing.build_node_sql(model_node, options) %}

  {% set model_columns = dbt_unit_testing.extract_columns_list(full_node_sql) %}
  {% set input_columns = dbt_unit_testing.extract_columns_list(input_values_sql) %}
  {% set extra_columns = dbt_unit_testing.extract_columns_difference(model_columns, input_columns) %}

  select * from (
    {{input_values_sql}}
  ) as {{ dbt_unit_testing.quote_identifier(model_name ~ '_tmp_1')}}
  {%- if extra_columns -%}
    {%- if mocking_strategy.simplified -%}
      {% set null_extra_columns = [] %}
      {% for c in extra_columns %}
        {% set null_extra_columns = null_extra_columns.append("null as " ~ c) %}
      {% endfor %}
      left join (select {{ null_extra_columns | join (",")}}) as {{ dbt_unit_testing.quote_identifier(model_name ~ '_tmp_3') }} on false
    {%- else -%}
      {% set simple_node_sql = dbt_unit_testing.build_node_sql(model_node, {"fetch_mode": 'DATABASE' if mocking_strategy.database else 'RAW' }) %}
        left join (select {{ extra_columns | join (",")}}
                  from ({{ simple_node_sql }}) as {{ dbt_unit_testing.quote_identifier(model_name ~ '_tmp_2') }}) as {{ dbt_unit_testing.quote_identifier(model_name ~ '_tmp_3') }} on false
    {%- endif -%}
  {%- endif -%}
{% endmacro %}
