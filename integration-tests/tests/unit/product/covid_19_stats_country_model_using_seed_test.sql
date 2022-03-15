{{
    config(
        tags=['unit-test']
    )
}}

{% call dbt_unit_testing.test ('covid19_stats_using_model_using_seed') %}
  {% call dbt_unit_testing.mock_ref('covid19_stats_using_seed') %}
     select cast('2021-05-05' as Date) as day, 10 as cases, 1 as value
  {% endcall %}

  {% call dbt_unit_testing.expect() %}
    select  cast('2021-05-05' as Date) as day, 10 as cases, 1 as value
  {% endcall %}

{% endcall %}
