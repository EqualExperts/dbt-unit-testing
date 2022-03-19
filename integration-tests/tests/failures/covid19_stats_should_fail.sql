{{
    config(
        tags=['unit-test']
    )
}}

{% call test_should_fail ('covid19_stats', 'more rows on expectations') %}
  {% call dbt_unit_testing.mock_ref ('covid19_cases_per_day', {"input_format": "csv"}) %}

    day::Date, cases, country_id
    '2021-05-05', 10, 'uk' 

  {% endcall %}

  {% call dbt_unit_testing.mock_source('dbt_unit_testing', 'covid19_country_stg', {"input_format": "csv"}) %}

    country_id, country_name
    'uk', 'United Kingdom'
    
  {% endcall %}

  {% call dbt_unit_testing.expect({"input_format": "csv"}) %}

    day::Date, cases, country_name
    '2021-05-05', 10, 'United Kingdom'
    '2021-05-05', 10, 'United Kingdom'

  {% endcall %}
{% endcall %}

UNION ALL

{% call test_should_fail ('covid19_stats', 'less rows on expectations') %}
  {% call dbt_unit_testing.mock_ref ('covid19_cases_per_day', {"input_format": "csv"}) %}

    day::Date, cases, country_id
    '2021-05-05', 10, 'uk' 
    '2021-05-05', 10, 'uk' 

  {% endcall %}

  {% call dbt_unit_testing.mock_source('dbt_unit_testing', 'covid19_country_stg', {"input_format": "csv"}) %}

    country_id, country_name
    'uk', 'United Kingdom'
    
  {% endcall %}

  {% call dbt_unit_testing.expect({"input_format": "csv"}) %}

    day::Date, cases, country_name
    '2021-05-05', 10, 'United Kingdom'

  {% endcall %}
{% endcall %}