{% macro extract_columns_list(query) %}
  {% set results = run_query(query) %}
  {% set columns = results.columns | map(attribute='name') | list %}
  {{ return (columns) }}
{% endmacro %}

{% macro extract_columns_difference(cl1, cl2) %}
  {% set columns = cl1 | map('lower') | list | reject('in', cl2 | map('lower') | list) | list %}
  {{ return(columns) }}
{% endmacro %}

{% macro quote_and_join_columns(columns) %}
  {% set columns = dbt_unit_testing.map(columns, dbt_unit_testing.quote_identifier) | join(",") %}
  {{ return (columns) }}
{% endmacro %}

{% macro sql_encode(s) %}
  {{ return (s.replace('"', '####_quote_####').replace('\n', '####_cr_####').replace('\t', '####_tab_####')) }}
{% endmacro %}

{% macro sql_decode(s) %}
  {{ return (s.replace('####_quote_####', '"').replace('####_cr_####', '\n').replace('####_tab_####', '\t')) -}}
{% endmacro %}

{% macro log_info(s, only_on_execute=false) %}
  {% if not only_on_execute or execute %}
    {% do log (s, info=true) %}
  {% endif  %}
{% endmacro %}

{% macro debug(s) %}
  {% if var('debug', false) or dbt_unit_testing.get_config('debug', false) %}
    {{ dbt_unit_testing.log_info (s) }}
  {% endif %}
{% endmacro %}

{% macro map(items, f) %}
  {% set mapped_items=[] %}
  {% for item in items %}
    {% do mapped_items.append(f(item)) %}
  {% endfor %}
  {{ return (mapped_items) }}
{% endmacro %}

{% macro node_by_id (node_id) %}]
  {{ return (graph.nodes[node_id] if node_id in graph.nodes else graph.sources[node_id]) }}
{% endmacro %}

{% macro graph_node_by_prefix (prefix, name) %}
  {{ return (graph.nodes[prefix ~ "." ~ model.package_name ~ "." ~ name])}}
{% endmacro %}

{% macro model_node (model_name) %}
  {{ return (nil | default(dbt_unit_testing.graph_node_by_prefix("model", model_name))
                 | default(dbt_unit_testing.graph_node_by_prefix("snapshot", model_name)) 
                 | default(dbt_unit_testing.graph_node_by_prefix("seed", model_name)))}}
  {% if not node %}
    {{ exceptions.raise_compiler_error("Node "  ~ package_name ~ "." ~ model_name ~ " not found.") }}
  {% endif %}
  {{ return (node) }}
{% endmacro %}

{% macro source_node(source_name, model_name) %}
  {{ return (graph.sources["source." ~ model.package_name ~ "." ~ source_name ~ "." ~ model_name]) }}
{% endmacro %}

{% macro graph_node(source_name, model_name) %}
  {% if source_name %}
    {{ return (dbt_unit_testing.source_node(source_name, model_name)) }}
  {% else %}
    {{ return (dbt_unit_testing.model_node(model_name)) }}
  {% endif  %}
{% endmacro %}

{% macro merge_jsons(jsons) %}
  {% set json = {} %}
  {% for j in jsons %}
    {% for k,v in j.items() %}
      {% do json.update({k: v}) %}
    {% endfor %}
  {% endfor %}
  {{ return (json) }}
{% endmacro %}

{% macro get_config(config_name, default_value) %}
  {% set unit_tests_config = var("unit_tests_config", {}) %}
  {% set unit_tests_config = {} if unit_tests_config is none else unit_tests_config %}
  {{ return (unit_tests_config.get(config_name, default_value))}}
{% endmacro %}

{% macro merge_configs(configs) %}
  {% set unit_tests_config = var("unit_tests_config", {}) %}
  {% set unit_tests_config = {} if unit_tests_config is none else unit_tests_config %}
  {{ return (dbt_unit_testing.merge_jsons([unit_tests_config] + configs)) }}
{% endmacro %}

{% macro quote_identifier(identifier) %}
    {{ return(adapter.dispatch('quote_identifier','dbt_unit_testing')(identifier)) }}
{% endmacro %}

{% macro default__quote_identifier(identifier) -%}
    {% if identifier.startswith('"') %}
      {{ return(identifier) }}
    {% else %}
      {{ return('"' ~ identifier ~ '"') }}
    {% endif %}
{%- endmacro %}

{% macro bigquery__quote_identifier(identifier) %}
    {% if identifier.startswith('`') %}
      {{ return(identifier) }}
    {% else %}
      {{ return('`' ~ identifier ~ '`') }}
    {% endif %}
{% endmacro %}

{% macro snowflake__quote_identifier(identifier) %}
    {% if identifier.startswith('"') %}
      {{ return(identifier) }}
    {% else %}
      {{ return('"' ~ identifier | upper ~ '"') }}
    {% endif %}
{% endmacro %}
