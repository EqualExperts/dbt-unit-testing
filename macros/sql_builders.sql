{% macro node_to_sql(database, schema, identifier) %}
  {{ return(dbt_unit_testing.quote_identifier(database) ~ '.' ~ dbt_unit_testing.quote_identifier(schema) ~ '.' ~ dbt_unit_testing.quote_identifier(identifier))}}
{% endmacro %}

{% macro source_node_to_sql(node) %}
  {{ return(dbt_unit_testing.node_to_sql(node.database, node.schema, node.identifier))}}
{% endmacro %}

{% macro model_node_to_sql(node) %}
  {{ return(dbt_unit_testing.node_to_sql(node.database, node.schema, node.name))}}
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
      {% if node.name in mocked_models_names %}
        {% set sql = mocked_models[node.name] %}
      {% else %}
        {% set sql = dbt_unit_testing.build_node_sql(node, options) %}
      {% endif %}
      {% set cte = dbt_unit_testing.quote_identifier(node.name) ~ " as (" ~ sql ~ ")" %}
      {% set cte_dependencies = cte_dependencies.append(cte) %}
    {%- endfor -%}

    {%- set final_sql -%}
      {% if cte_dependencies %}
        with
        {{ cte_dependencies | join(",\n") }}
      {%- endif -%}
      {% set sql_without_end_semicolon = modules.re.sub(';[\s\r\n]*$', '', render(model_node.raw_sql), 0, modules.re.M) %}
      select * from ({{ sql_without_end_semicolon }}) as t
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
  {% if execute %}
    {% set fetch_mode = options.get("fetch_mode") %}
    {% if node.resource_type in ('model','snapshot') %}
      {% if fetch_mode | upper == 'FULL' %}
        {{ dbt_unit_testing.build_model_complete_sql(node, {}, {"fetch_mode": 'RAW'}) }}
      {% elif fetch_mode | upper == 'RAW' %}
        {% set sql_without_end_semicolon = modules.re.sub(';[\s\r\n]*$', '', render(node.raw_sql), 0, modules.re.M) %}
        {{ sql_without_end_semicolon }}
      {% elif fetch_mode | upper == 'DATABASE' %}
        {{ dbt_unit_testing.fake_model_sql(node) }}
      {% else %}
        {{ exceptions.raise_compiler_error("Invalid fetch_mode: " ~ fetch_mode) }}
     {% endif %}
    {% elif node.resource_type == 'seed'  %}
      {{ dbt_unit_testing.fake_seed_sql(node) }}
    {% else %}
      {{ dbt_unit_testing.fake_source_sql(node) }}
    {% endif %}
  {% endif %}
{% endmacro %}

{% macro fake_model_sql(node) %}
  {% set source_relation = dbt_utils.get_relations_by_pattern(
      database=node.database,
      schema_pattern=node.schema,
      table_pattern=node.name
  ) %}
  {% if source_relation | length > 0 %}
    {%- set source_sql -%}
      select * from {{ dbt_unit_testing.model_node_to_sql(node) }} where false
    {%- endset -%}
    select {{ dbt_unit_testing.quote_and_join_columns(dbt_unit_testing.extract_columns_list(source_sql)) }}
    from {{ dbt_unit_testing.model_node_to_sql(node) }}
    where false
  {% else %}
    {% if node.columns %}
      {% set columns = [] %}
      {% for c in node.columns.values() %}
        {% do columns.append("cast(null as " ~ (c.data_type if c.data_type is not none else dbt_utils.type_string()) ~ ") as " ~ dbt_unit_testing.quote_identifier(c.name)) %}
      {% endfor %}
      select {{ columns | join (",") }}
    {% else %}
      {{ exceptions.raise_compiler_error("Model " ~ node.name ~ " columns must be declared in schema.yml, or it must exist in database") }}
    {% endif %}
  {% endif %}
{% endmacro %}

{% macro fake_source_sql(node) %}
  {% set source_relation = dbt_utils.get_relations_by_pattern(
      database=node.database,
      schema_pattern=node.schema,
      table_pattern=node.identifier
  ) %}
  {% if source_relation | length > 0 %}
    {%- set source_sql -%}
      select * from {{ dbt_unit_testing.source_node_to_sql(node) }} where false
    {%- endset -%}
    select {{ dbt_unit_testing.quote_and_join_columns(dbt_unit_testing.extract_columns_list(source_sql)) }}
    from {{ dbt_unit_testing.source_node_to_sql(node) }}
    where false
  {% else %}
    {% if node.columns %}
      {% set columns = [] %}
      {% for c in node.columns.values() %}
        {% do columns.append("cast(null as " ~ (c.data_type if c.data_type is not none else dbt_utils.type_string()) ~ ") as " ~ dbt_unit_testing.quote_identifier(c.name)) %}
      {% endfor %}
      select {{ columns | join (",") }}
    {% else %}
      {{ exceptions.raise_compiler_error("Source " ~ node.name ~ " columns must be declared in sources.yml, or it must exist in database") }}
    {% endif %}
  {% endif %}
{% endmacro %}

{% macro fake_seed_sql(node) %}
  {% set source_relation = dbt_utils.get_relations_by_pattern(
      database=node.database,
      schema_pattern=node.schema,
      table_pattern=node.name
  ) %}
  {% if source_relation | length > 0 %}
    {%- set source_sql -%}
      select * from {{ dbt_unit_testing.model_node_to_sql(node) }} where false
    {%- endset -%}
    select {{ dbt_unit_testing.quote_and_join_columns(dbt_unit_testing.extract_columns_list(source_sql)) }}
    from {{ dbt_unit_testing.model_node_to_sql(node) }}
    where false
  {% else %}
    {% if node.config and node.config.column_types %}
      {% set columns = [] %}
      {% for c in node.config.column_types.keys() %}
        {% do columns.append("cast(null as " ~ (node.config.column_types[c] if node.config.column_types[c] is not none else dbt_utils.type_string()) ~ ") as " ~ dbt_unit_testing.quote_identifier(c)) %}
      {% endfor %}
      select {{ columns | join (",") }}
    {% else %}
      {{ exceptions.raise_compiler_error("Seed " ~ node.name ~ " columns must be declared in properties.yml, or it must exist in database") }}
    {% endif %}
  {% endif %}
{% endmacro %}
