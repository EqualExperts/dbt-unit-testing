{% macro extract_columns_list(query) %}
  {% if execute %}
    {% set results = run_query(query) %}
    {% set columns = results.columns | map(attribute='name') | list %}
    {{ return (columns) }}
  {% else %}
    {{ return([]) }}
  {% endif %}
{% endmacro %}

{% macro extract_columns_difference(cl1, cl2) %}
  {% set columns = cl1 | list | reject('in', cl2) | list %}
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

{% macro log_info(s) %}
  {% do log (s, info=true) %}
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
  {% if execute %}
    {{ return (graph.nodes[node_id] if node_id in graph.nodes else graph.sources[node_id]) }}
  {% endif %}
{% endmacro %}

{% macro model_node (model_name) %}
  {% set package_name = model.package_name %}
  {% if execute %}
    {% set node = graph.nodes["model." ~ package_name ~ "." ~ model_name] %}
    {% if not node %}
      {% set node = graph.nodes["snapshot." ~ package_name ~ "." ~ model_name] %}
      {% if not node %}
        {% set node = graph.nodes["seed." ~ package_name ~ "." ~ model_name] %}
         {% if not node %}
           {{ exceptions.raise_compiler_error("Node "  ~ package_name ~ "." ~ model_name ~ " not found.") }}
         {% endif %}
      {% endif %}
    {% endif %}
    {{ return (node) }}
  {% endif %}
{% endmacro %}

{% macro source_node (source_name, model_name) %}
  {% if execute %}
    {{ return (graph.sources["source." ~ model.package_name ~ "." ~ source_name ~ "." ~ model_name]) }}
  {% endif %}
{% endmacro %}

{% macro graph_node (source_name, model_name) %}
  {% if source_name %}
    {{ return (dbt_unit_testing.source_node(source_name, model_name)) }}
  {% else %}
    {{ return (dbt_unit_testing.model_node(model_name)) }}
  {% endif  %}
{% endmacro %}

{% macro get_config(config_name, default_value) %}
  {% set unit_tests_config = var("unit_tests_config", {}) %}
  {% set unit_tests_config = {} if unit_tests_config is none else unit_tests_config %}
  {{ return (unit_tests_config.get(config_name, default_value))}}
{% endmacro %}

{% macro get_mocking_strategy(options) %}
  {% set mocking_strategy = options.get("mocking_strategy", dbt_unit_testing.get_config("mocking_strategy", 'FULL')) %}
  {% if mocking_strategy | upper not in ['FULL', 'SIMPLIFIED', 'DATABASE']%}
    {{ exceptions.raise_compiler_error("Invalid mocking strategy: " ~ mocking_strategy) }}
  {% endif%}
  {% set full = mocking_strategy | upper == 'FULL' %}
  {% set simplified = mocking_strategy | upper == 'SIMPLIFIED' %}
  {% set database = mocking_strategy | upper == 'DATABASE' %}
  {{ return ({"full": full, "simplified": simplified, "database": database}) }}
{% endmacro %}