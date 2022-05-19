{% macro build_input_values_sql(input_values, options) %}
    {% set input_format = options.get("input_format", dbt_unit_testing.get_config("input_format", "sql")) %}

    {% set input_values_sql = input_values %}

    {% if input_format == "csv" %}
      {% set input_values_sql = dbt_unit_testing.sql_from_csv_input(input_values, options) %}
    {%- endif -%}

    {{ return (input_values_sql) }}
{% endmacro %}

{% macro sql_from_csv(options={}) %}
  {{ return (sql_from_csv_input(caller(), options)) }}
{% endmacro %}

{% macro sql_from_csv_input(csv_table, options={}) %}
  {% set unit_tests_config = var("unit_tests_config", {}) %}
  {% set column_separator = options.get("column_separator", unit_tests_config.get("column_separator", ",")) %}
  {% set line_separator = options.get("line_separator", unit_tests_config.get("line_separator", "\n")) %}
  {% set type_separator = options.get("type_separator", unit_tests_config.get("type_separator", "::")) %}
  {% set ns = namespace(col_names=[], col_types = [], col_values = [], row_values=[]) %}

  {% set rows = csv_table.split(line_separator) | map('trim') | reject('==', '') | list %}
  {% set cols = rows[0].split(column_separator) | map('trim') %}
  {% for col in cols %}
    {% set c = col.split(type_separator) | list %}
    {% set col_name = c[0] %}
    {% set col_type = c[1] %}
    {% set ns.col_names = ns.col_names + [col_name] %}
    {% set ns.col_types = ns.col_types + [col_type] %}
  {% endfor %}

  {% for row in rows[1:] %}
    {% set cols = row.split(column_separator) | map('trim') | list %}
    {% set ns.col_values = [] %}
    {% for col in cols %}
      {% set col_value = col %}
      {% set col_type = ns.col_types[loop.index-1] %}
      {% if col_type is defined %}
        {% set col_value = "CAST(" ~ col_value ~ " as " ~ col_type ~ ")" %}
      {% endif %}
      {% set col_value = col_value ~ " as " ~ ns.col_names[loop.index-1] %}
      {% set ns.col_values = ns.col_values + [col_value] %}
    {% endfor %}

    {% set col_values = ns.col_values | join(",") %}
    {% set sql_row = "select " ~ col_values %}
    {% set ns.row_values = ns.row_values + [sql_row] %}
  {% endfor %}

  {% set sql = ns.row_values | join("\n union all\n") %}

  {{ return (sql) }}

 {% endmacro %}

