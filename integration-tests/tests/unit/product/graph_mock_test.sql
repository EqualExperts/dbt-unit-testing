{{
    config(
        tags=['unit-test']
    )
}}

{% call dbt_unit_testing.test ('graph_d') %}
  {% call dbt_unit_testing.mock_ref('graph_c') %}
    select 'x' as origin
    union all
    select 'y' as origin
  {% endcall %}

  {% call dbt_unit_testing.expect() %}
    select 'X' as origin
    union all
    select 'Y' as origin
  {% endcall %}
{% endcall %}
