{% macro node_to_sql(database, schema, identifier) %}
  {{ return(dbt_unit_testing.quote_identifier(database) ~ '.' ~ dbt_unit_testing.quote_identifier(schema) ~ '.' ~ dbt_unit_testing.quote_identifier(identifier))}}
{% endmacro %}

{% macro build_model_complete_sql(model_node, mocked_models, options) %}
  {% if execute %}
    {% set include_all_dependencies = options.get("include_all_dependencies", false) %}

    {% set mocked_models_names = mocked_models.keys() | list %}
    {% set cte_dependencies = [] %}
    {% set dependencies_to_exclude = none if include_all_dependencies else mocked_models_names %}
    {% set model_dependencies = dbt_unit_testing.build_model_dependencies(model_node, dependencies_to_exclude) %}
    {% for node_id in model_dependencies %}
      {% set node = dbt_unit_testing.node_by_id(node_id) %}
      {% if node.resource_type == "source" %}
        {% set cte_name = node.source_name ~ "__" ~ node.name %}
      {% else %}
        {% set cte_name = node.name %}
      {% endif %}
      {% if cte_name in mocked_models_names %}
        {% set sql = mocked_models[cte_name] %}
      {% else %}
        {% set sql = dbt_unit_testing.build_node_sql(node, options) %}
      {% endif %}
      {% set cte = dbt_unit_testing.quote_identifier(cte_name) ~ " as (" ~ sql ~ "\n)" %}
      {% set cte_dependencies = cte_dependencies.append(cte) %}
    {%- endfor -%}

    {%- set final_sql -%}
      {% if cte_dependencies %}
        with
        {{ cte_dependencies | join(",\n") }}
      {%- endif -%}
      select * from ({{ render(model_node.raw_sql) }}
      ) as t
    {%- endset -%}

    {{ return (final_sql) }}

  {%- endif -%}
{% endmacro %}

{% macro build_model_dependencies(node, models_names_to_exclude) %}
  {% set model_dependencies = [] %}
  {% for node_id in node.depends_on.nodes %}
    {% set node = dbt_unit_testing.node_by_id(node_id) %}
    {% if node.resource_type in ('model','snapshot') and (models_names_to_exclude is none or node.name not in models_names_to_exclude) %}
      {% set child_model_dependencies = dbt_unit_testing.build_model_dependencies(node) %}
      {% for dependency_node_id in child_model_dependencies %}
        {{ model_dependencies.append(dependency_node_id) }}
      {% endfor %}
    {% endif %}
    {{ model_dependencies.append(node_id) }}
  {% endfor %}

  {{ return (model_dependencies | unique | list) }}
{% endmacro %}

{% macro build_node_sql (node, options) %}
  {%- if execute -%}
    {% set fetch_mode = options.get("fetch_mode") %}
    {%- if node.resource_type in ('model','snapshot') -%}
      {%- if fetch_mode | upper == 'FULL' -%}
        {{ dbt_unit_testing.build_model_complete_sql(node, {}, {"fetch_mode": 'RAW'}) }}
      {%- elif fetch_mode | upper == 'RAW' -%}
        {{ render(node.raw_sql) }}
      {%- elif fetch_mode | upper == 'DATABASE' -%}
        {{ dbt_unit_testing.fake_model_sql(node) }}
      {%- else -%}
        {{ exceptions.raise_compiler_error("Invalid fetch_mode: " ~ fetch_mode) }}
     {%- endif -%}
    {%- elif node.resource_type == 'seed' -%}
      {{ dbt_unit_testing.fake_seed_sql(node) }}
    {%- else -%}
      {{ dbt_unit_testing.fake_source_sql(node) }}
    {%- endif -%}
  {%- endif -%}
{% endmacro %}

{%- macro fake_model_sql(node) -%}
  {{ dbt_unit_testing.get_columns_sql(node, node.name, node.columns, "Model " ~ node.name ~ " columns must be declared in schema.yml, or it must exist in database") }}
{% endmacro %}

{%- macro fake_source_sql(node) -%}
  {{ dbt_unit_testing.get_columns_sql(node, node.identifier, node.columns, "Source " ~ node.name ~ " columns must be declared in sources.yml, or it must exist in database") }}
{% endmacro %}

{% macro fake_seed_sql(node) %}
  {% set columns = {} %}
  {% if node.config and node.config.column_types %}
    {% for c in node.config.column_types.keys() %}
    {% do columns.update({c: {"name" : c, "data_type": node.config.column_types[c]} }) %}
    {% endfor %}
  {% endif %}
  {{ dbt_unit_testing.get_columns_sql(node, node.name, columns, "Seed " ~ node.name ~ " columns must be declared in properties.yml, or it must exist in database") }}
{% endmacro %}

{% macro get_columns_sql(node, identifier, config_columns, error_message) %}
  {% set columns = adapter.get_columns_in_relation(api.Relation.create(database=node.database, schema=node.schema, identifier=identifier, quote_policy=node.get('quoting', {}))) %}
  {%- if columns | length > 0 -%}
    select {{ dbt_unit_testing.quote_and_join_columns(columns | map(attribute='name') | list) }}
    from {{ dbt_unit_testing.node_to_sql(node.database, node.schema, identifier) }}
    where false
  {%- elif config_columns | length > 0 -%}
    {{ dbt_unit_testing.get_config_columns_sql(config_columns) }}
  {%- else -%}
    {{ exceptions.raise_compiler_error(error_message) }}
  {%- endif -%}
{% endmacro %}

{% macro get_config_columns_sql(config_columns) %}
  {% set columns = [] %}
  {% for c in config_columns.values() %}
    {% do columns.append("cast(null as " ~ (c.data_type if c.data_type is not none else dbt_utils.type_string()) ~ ") as " ~ dbt_unit_testing.quote_identifier(c.name)) %}
  {% endfor %}
  select {{ columns | join (",") }}
{% endmacro %}
