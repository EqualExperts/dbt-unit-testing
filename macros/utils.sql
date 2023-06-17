{% macro run_query(query) %}
  {% set start_time = modules.datetime.datetime.now() %}
  {{ dbt_unit_testing.verbose('Running query => ' ~ dbt_unit_testing.sanitize(query)) }}
  {% set results = run_query(query) %}
  {% set end_time = modules.datetime.datetime.now() - start_time %}
  {{ dbt_unit_testing.verbose('Execution time => ' ~ end_time) }}
  {{ dbt_unit_testing.verbose('==============================================================') }}
  {{ return (results) }}
{% endmacro %}

{% macro sanitize(s) %}
  {{ return (" ".join(s.split())) }}
{% endmacro %}

{% macro render_node(node) %}
  {% set model_sql = node.raw_sql if node.raw_sql is defined else node.raw_code %}
  {{ return (render(model_sql)) }}
{% endmacro %}
     
{% macro render_node_for_model_being_tested(node) %}
  {% set model_sql = node.raw_sql if node.raw_sql is defined else node.raw_code %}
  {% set model_name = node.name %}
  {% set this_name = this | string %}
  -- If the model contains a 'this' property, we will replace its result with the name of the model being tested
  -- but first we mask previous occurrences that could be there before the render (very unlikely to happen)
  -- This way we 'ensure' that we only replace stuff produced after the render 
  {% set replace_mask = '######################' %}
  {% set model_sql = model_sql.replace(this_name, replace_mask) %}
  {{ dbt_unit_testing.set_test_context("model_being_rendered", model_name) }}
  {% set rendered_sql = render(model_sql) %}
  {{ dbt_unit_testing.set_test_context("model_being_rendered", "") }}
  {% set rendered_sql = rendered_sql.replace(this_name, model_name) %}
  {% set rendered_sql = rendered_sql.replace(replace_mask, this_name) %}
  {{ return (rendered_sql) }}
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
  {{ dbt_unit_testing.log_info (s, only_on_execute=true) }}
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

{% macro node_by_id (node_id) %}]
  {{ return (graph.nodes[node_id] if node_id in graph.nodes else graph.sources[node_id]) }}
{% endmacro %}

{% macro graph_node_by_prefix (prefix, name) %}
  {{ return (graph.nodes[prefix ~ "." ~ model.package_name ~ "." ~ name])}}
{% endmacro %}

{% macro model_node (model_name) %}
  {% set node = nil
      | default(dbt_unit_testing.graph_node_by_prefix("model", model_name))
      | default(dbt_unit_testing.graph_node_by_prefix("snapshot", model_name)) 
      | default(dbt_unit_testing.graph_node_by_prefix("seed", model_name)) %}
  {% if not node %}
    {{ dbt_unit_testing.raise_error("Node " ~ model.package_name ~ "." ~ model_name ~ " not found.") }}
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

