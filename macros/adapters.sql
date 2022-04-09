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
