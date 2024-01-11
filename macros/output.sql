{% macro print_table(agate_table, options={}) %}
  {% set columns_start_index = 2 %}
  {% set columns_info = [] %}
  {% for col_name in agate_table.column_names %}
    {% set col_index = loop.index0 %}
    {% set column_info = {"max_length": col_name | length, "is_string": false, "has_differences": false} %}
    {% for row in agate_table.rows %}
      {% set cell_value = row[col_name] %}
      {% set l = cell_value | string | length %}
      {% if l > column_info.max_length %}
        {% do column_info.update({"max_length": l}) %}
      {% endif %}
      {% do column_info.update({"is_string": column_info.is_string or cell_value is string}) %}

      {% if col_index >= columns_start_index %}
        {% if column_info.previous_value is defined and column_info.previous_value != cell_value %}
          {% do column_info.update({"has_differences": true}) %}
        {% endif %}
        {% do column_info.update({"previous_value": cell_value}) %}
      {% endif %}

    {% endfor %}  
    {% set columns_info = columns_info.append(column_info) %}
  {% endfor %}

  {% set cells = [] %}
  {% for col_name in agate_table.column_names %}
    {% set col_index = loop.index0 %}
    {% set padded = dbt_unit_testing.pad(col_name, columns_info[col_index].max_length, pad_right=columns_info[col_index].is_string) %}
    {% if columns_info[col_index].has_differences %}
      {% do cells.append("{RED}" ~ padded ~ "{RESET}") %}
    {% else %}
      {% do cells.append(padded) %}
    {% endif %}
  {% endfor %}
  {{ dbt_unit_testing.println("| " ~ cells | join(" | ") ~ " |")}}

  {% set cells = [] %}
  {% for col_name in agate_table.column_names %}
    {% set col_index = loop.index0 %}
    {% set line = dbt_unit_testing.pad("", columns_info[col_index].max_length, c="-") %}
    {% if columns_info[col_index].has_differences %}
      {% do cells.append("{RED}" ~ line ~ "{RESET}") %}
    {% else %}
      {% do cells.append(line) %}
    {% endif %}
  {% endfor %}
  {{ dbt_unit_testing.println("| " ~ cells | join(" | ") ~ " |")}}

  {% set last_spaces_replace_char = options.last_spaces_replace_char | default(" ") %}
  {% for row in agate_table.rows %}
    {% set cells = [] %}
    {% for cell_value in row %}
      {% set col_index = loop.index0 %}
      {% if cell_value is string %}
        {% set cell_value = dbt_unit_testing.replace_last_spaces_with(last_spaces_replace_char, cell_value) %}
      {% endif %}
      {% set padded = dbt_unit_testing.pad(cell_value, columns_info[col_index].max_length, pad_right=cell_value is string) %}
      {% if columns_info[col_index].has_differences %}
        {% do cells.append("{RED}" ~ padded ~ "{RESET}") %}
      {% else %}
        {% do cells.append(padded) %}
      {% endif %}
    {% endfor %}
    {{ dbt_unit_testing.println("| " ~ cells | join(" | ") ~ " |")}}
  {% endfor %}
{% endmacro %}

{% macro replace_last_spaces_with(replacement, s) %}
  {% set rs = s | reverse %}
  {% set replaced = namespace(value="", stop=false) %}
  {% for i in range(0, rs | length) %}
    {% if rs[i] == ' ' and not replaced.stop %}
      {% set replaced.value = replaced.value ~ replacement %}
    {% else %}
      {% set replaced.value = replaced.value ~ rs[i] %}
      {% set replaced.stop = true %}
    {% endif %}
  {% endfor %}
  {{ return(replaced.value | reverse) }}
{% endmacro %}

{% macro pad(v, pad, pad_right=false, c=" ") %}
  {% set padding = c * (pad - v | string | length) %}
  {% if pad_right %}
    {{ return (v ~ padding) }}
  {% else %}
    {{ return (padding ~ v) }}
  {% endif %}
{% endmacro %}

{% macro parse_colors(s) %}
  {{ return (s
      .replace("{RED}", "\x1b[0m\x1b[31m")
      .replace("{GREEN}", "\x1b[0m\x1b[32m")
      .replace("{YELLOW}", "\x1b[0m\x1b[33m")
      .replace("{BG_YELLOW}", "\x1b[0m\x1b[43m")
      .replace("{RESET}", "\x1b[0m")) }}
{% endmacro %}

{% macro println(s) %}
  {% do log(dbt_unit_testing.parse_colors(s ~ "{RESET}"), info=true) %}
{% endmacro %}

{% macro print_warning(s) %}
  {% do log(dbt_unit_testing.parse_colors("{YELLOW}" ~ s ~ "{RESET}"), info=true) %}
{% endmacro %}
