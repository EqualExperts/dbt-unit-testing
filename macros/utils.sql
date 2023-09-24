{% macro run_query(query) %}
  {% set start_time = modules.datetime.datetime.now() %}
  {{ dbt_unit_testing.verbose('Running query => ' ~ dbt_unit_testing.sanitize(query)) }}
  {% set results = dbt.run_query(query) %}
  {% set end_time = modules.datetime.datetime.now() - start_time %}
  {{ dbt_unit_testing.verbose('Execution time => ' ~ end_time) }}
  {{ dbt_unit_testing.verbose('==============================================================') }}
  {{ return (results) }}
{% endmacro %}

{% macro sanitize(s) %}
  {{ return (" ".join(s.split())) }}
{% endmacro %}

{% macro extract_columns_list(query) %}
  {% set results = dbt_unit_testing.run_query(query) %}
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
  {% endif %}
{% endmacro %}

{% macro debug(s) %}
  {% if var('debug', dbt_unit_testing.config_is_true('debug')) %}
    {{ dbt_unit_testing.log_info (s, only_on_execute=true) }}
  {% endif %}
{% endmacro %}

{% macro verbose(s) %}
  {% if var('verbose', dbt_unit_testing.config_is_true('verbose')) %}
    {{ dbt_unit_testing.log_info (s, only_on_execute=true) }}
  {% endif %}
{% endmacro %}

{% macro map(items, f) %}
  {% set mapped_items=[] %}
  {% for item in items %}
    {% do mapped_items.append(f(item)) %}
  {% endfor %}
  {{ return (mapped_items) }}
{% endmacro %}

{% macro node_by_id (node_id) %}
  {{ return (graph.nodes[node_id] if node_id in graph.nodes else graph.sources[node_id]) }}
{% endmacro %}

{% macro has_value(v) %}
  {{ return (v is defined and v is not none) }}
{% endmacro %}

{% macro model_node (node) %}
  {% set graph_nodes = graph.nodes.values() | 
    selectattr('resource_type', 'in', ['model', 'snapshot', 'seed']) | 
    selectattr('package_name', 'equalto', node.package_name) | 
    selectattr('name', 'equalto', node.name) | 
    list %}
  {% if graph_nodes | length > 0 %}
    {% if dbt_unit_testing.has_value(node.version) %}
      {% set graph_nodes = graph_nodes | selectattr('version', 'equalto', node.version) | list %}
    {% else %}
      {% set latest_version = graph_nodes[0].latest_version %}
      {% if dbt_unit_testing.has_value(latest_version) %}
        {% set graph_nodes = graph_nodes | selectattr('version', 'equalto', latest_version) | list %}
      {% endif %}
    {% endif %}
  {% endif %}
  {% if graph_nodes | length == 0 %}
    {% set node_version = '_v' ~ node.version if dbt_unit_testing.has_value(node.version) else '' %}
    {{ dbt_unit_testing.raise_error("Node " ~ node.package_name ~ "." ~ node.name ~ node_version ~ " not found.") }}
  {% endif %}
  {% set graph_node = graph_nodes[0] %}
  {{ return (graph_node) }}
{% endmacro %}

{% macro source_node(node) %}
  {{ return (graph.sources["source." ~ model.package_name ~ "." ~ node.source_name ~ "." ~ node.name]) }}
{% endmacro %}

{% macro graph_node(node) %}
  {% if node.resource_type in ('source') %}
    {{ return (dbt_unit_testing.source_node(node)) }}
  {% else %}
    {{ return (dbt_unit_testing.model_node(node)) }}
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

{% macro config_is_true(config_name) %}
  {{ return (dbt_unit_testing.get_config(config_name, default_value=false))}}
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

{% macro spark__quote_identifier(identifier) %}
    {% if identifier.startswith('`') %}
      {{ return(identifier) }}
    {% else %}
      {{ return('`' ~ identifier ~ '`') }}
    {% endif %}
{% endmacro %}

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

{% macro cache(scope_key, key, value) %}
  {% if dbt_unit_testing.config_is_true('disable_cache') %}
    {{ return (nil) }}
  {% else %}
    {% set cache = context.get("__DUT_CACHE__", {}) %}
    {% set scope = cache.get(scope_key, {}) %}
    {% do scope.update({key: value}) %}
    {% do cache.update({scope_key: scope}) %}
    {% do context.update({"__DUT_CACHE__": cache}) %}
  {% endif %}
{% endmacro %}

{% macro get_from_cache(scope, key) %}
  {% set cache = context.get("__DUT_CACHE__", {}).get(scope, {}) %}
  {{ return (cache[key]) }}
{% endmacro %}

{% macro raise_error(error_message) %}
  {{ exceptions.raise_compiler_error('\x1b[31m' ~ error_message ~ '\x1b[0m') }}
{% endmacro %}

{% macro set_test_context(key, value) %}
  {% set test_context = context.get("__DUT_TEST_CONTEXT__", {}) %}
  {% set test_key = this.name %}
  {% set test_scope = test_context.get(test_key, {}) %}
  {% do test_scope.update({key: value | default("")}) %}
  {% do test_context.update({test_key: test_scope}) %}
  {% do context.update({"__DUT_TEST_CONTEXT__": test_context}) %}
{% endmacro %}

{% macro get_test_context(key, default_value) %}
  {% set test_context = context.get("__DUT_TEST_CONTEXT__", {}) %}
  {% set test_key = this.name %}
  {% set test_scope = test_context.get(test_key, {}) %}
  {{ return (test_scope.get(key, default_value)) }}
{% endmacro %}

{% macro clear_test_context(key, default_value) %}
  {% set test_context = context.get("__DUT_TEST_CONTEXT__", {}) %}
  {% set test_key = this.name %}
  {% do context.update({test_key: {}}) %}
{% endmacro %}

{% macro split_and_pad_and_join(s, pad) %}
  {% set parts = s.split('.') %}
  {% set parts_2 = [] %}
  {% for p in parts %}
    {% do parts_2.append(dbt_unit_testing.pad(parts[loop.index-1], pad, pad_right=true)) %}
  {% endfor %}
  {{ return (parts_2 | join('.')) }}
{% endmacro %}

{% macro version_bigger_or_equal_to(v) %}
  {{ return (dbt_unit_testing.split_and_pad_and_join(dbt_version, 5) >= dbt_unit_testing.split_and_pad_and_join(v, 5)) }}
{% endmacro %}

