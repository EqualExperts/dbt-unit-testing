{% macro mock_ref(project_or_package, model_name, options={}) %}
  {% if model_name is mapping %}
    {% set options = model_name %}
    {% set model_name = project_or_package %}
    {% set project_or_package = model.package_name %}
    {{ dbt_unit_testing.print_warning("Use keyword 'options' when passing options to mock_ref" ~ " (in " ~ model_name ~ ")") }}
  {% else %}
    {% set project_or_package, model_name = dbt_unit_testing.setup_project_and_model_name(project_or_package, model_name) %}
  {% endif %}
  {% if model_name is undefined %}
    {{ dbt_unit_testing.raise_error('model_name must be provided for mock_ref') }}
  {% endif %}
  {% set node_version = kwargs["version"] | default(kwargs["v"]) | default(none) %}
  {% set mock = {
     "type": 'mock',
     "resource_type": 'model',
     "name": model_name,
     "package_name": project_or_package,
     "version": node_version,
     "options": options,
     "input_values": caller(),
    }
  %} 
  {{ return (dbt_unit_testing.append_json(mock)) }}
{% endmacro %}

{% macro mock_source(source_name, table_name, options={}) %}
  {% if source_name is undefined %}
    {{ dbt_unit_testing.raise_error('source_name must be provided for mock_source') }}
  {% endif %}
  {% if table_name is undefined %}
    {{ dbt_unit_testing.raise_error('table_name must be provided for mock_source') }}
  {% endif %}
  {% set mock = {
     "type": 'mock',
     "resource_type": 'source',
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

{% macro expect_no_rows(options={}) %}
  {% set dummy = caller() %}
  {% set expectations = {
      "type": "expectations",
      "options": options,
      "input_values": "select * from (select 1) as t where 1 = 0",
      "no_rows": true,
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

{% macro enrich_mock_sql_with_missing_columns(mock, options) %}
  {% set model_node = dbt_unit_testing.node_by_id(mock.unique_id) %}
  {% set model_name = model_node.name %}
  {% set input_values_sql = mock.input_values %}

  {% set model_columns = dbt_unit_testing.get_from_cache("COLUMNS", model_node.name) %}
  {% if not model_columns %}
    {% set model_sql = dbt_unit_testing.build_node_sql(model_node, options.use_database_models, complete=true) %}
    {% set model_columns = dbt_unit_testing.extract_columns_list(model_sql) %}
    {{ dbt_unit_testing.cache("COLUMNS", model_node.name, model_columns)}}
  {% else %}
    {{ dbt_unit_testing.verbose("CACHE HIT for " ~ model_node.name ~ " COLUMNS") }}
  {% endif %}
  
  {% set input_columns = dbt_unit_testing.extract_columns_list(input_values_sql) %}
  {% set missing_columns = dbt_unit_testing.extract_columns_difference(model_columns, input_columns) %}

  {%- if missing_columns -%}
    {% set input_values_sql %}
      {% set node_sql = dbt_unit_testing.build_node_sql(model_node, options.use_database_models) %}
        select * from ({{ input_values_sql }}) as m1
        left join (select {{ dbt_unit_testing.quote_and_join_columns(missing_columns)}}
                  from ({{ node_sql }}) as m2) as m3 on false
    {%- endset -%}
  {%- endif -%}
  {% do mock.update({"input_values": input_values_sql}) %}
{% endmacro %}
