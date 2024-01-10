{% macro build_input_values_sql(input_values, options) %}
    {% set input_values_sql = input_values %}

    {% if options.input_format | lower == "csv" %}
      {% set input_values_sql = dbt_unit_testing.sql_from_csv_input(input_values, options) %}
    {%- endif -%}

    {{ return (input_values_sql) }}
{% endmacro %}

{% macro sql_from_csv(options={}) %}
  {{ return (sql_from_csv_input(caller(), options)) }}
{% endmacro %}

{% macro sql_from_csv_input(csv_table, options) %}
  {% set column_separator = options.column_separator | default(",") %}
  {% set line_separator = options.line_separator | default("\n") %}
  {% set type_separator = options.type_separator | default("::") %}
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
