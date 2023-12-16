{% set columns = ["a", "b", "c"] %}
{% set columns_to_json = ["a", "c"] %}
{% set selected_columns = dbt_unit_testing.quote_and_join_columns(columns, columns_to_json) %}

with act as (
    select
        "{{ columns }}" as columns,
        "{{ columns_to_json }}" as columns_to_json,
        "to_json_string(`a`) AS `a`, `b`, to_json_string(`c`) AS `c`" as expected,
        "{{ selected_columns }}" as actual
)
select * from act where expected != actual
