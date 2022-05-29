{% macro mock_ref(model_name, options={}) %}
  {% set mock = {
     "type": 'mock',
     "mock_type": 'model',
     "cte_name": dbt_unit_testing.ref_cte_name(model_name),
     "name": model_name,
     "options": options,
     "input_values": caller(),
    }
  %} 
  {{ return (dbt_unit_testing.append_json(mock)) }}
{% endmacro %}

{% macro mock_source(source_name, table_name, options={}) %}
  {% set mock = {
     "type": 'mock',
     "mock_type": 'source',
     "cte_name": dbt_unit_testing.source_cte_name(source_name, table_name),
     "name": table_name,
     "source_name": source_name,
     "options": options,
     "input_values": caller(),
    }
  %} 
  {{ return (dbt_unit_testing.append_json(mock)) }}
{% endmacro %}

{% macro expect(options={}) %}
  {% set expectations = {
      "type": "expectations",
      "options": options,
      "input_values": caller(),
    }
  %} 
  {{ return (dbt_unit_testing.append_json(expectations)) }}
{% endmacro %}

{% macro append_json(json) %}
  {{ return (json | tojson() ~ '####_JSON_LINE_DELIMITER_####') }}
{% endmacro %}

{% macro split_json_str(json_str) %}
  {% set lines = json_str.split('####_JSON_LINE_DELIMITER_####') | map('trim') | reject('==', '') | list %}
  {{ return (dbt_unit_testing.map(lines, fromjson)) }}
{% endmacro %}

{% macro enrich_mock_sql_with_extra_columns(mock) %}
  {% set model_node = dbt_unit_testing.node_by_id(mock.unique_id) %}
  {% set model_name = model_node.name %}
  {% set input_values_sql = mock.input_values %}

  {% set model_sql = dbt_unit_testing.build_node_sql(model_node, complete=true) %}
  {% set model_columns = dbt_unit_testing.extract_columns_list(model_sql) %}
  {% set input_columns = dbt_unit_testing.extract_columns_list(input_values_sql) %}
  {% set extra_columns = dbt_unit_testing.extract_columns_difference(model_columns, input_columns) %}

  {%- if extra_columns -%}
    {% set input_values_sql %}
      {% set node_sql = dbt_unit_testing.build_node_sql(model_node) %}
        select * from ({{ input_values_sql }}) as m1
        left join (select {{ extra_columns | join (",")}}
                  from ({{ node_sql }}) as m2) as m3 on false
    {%- endset -%}
  {%- endif -%}
  {% do mock.update({"input_values": input_values_sql}) %}
{% endmacro %}
