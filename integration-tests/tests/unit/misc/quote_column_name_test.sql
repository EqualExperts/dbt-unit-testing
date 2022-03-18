{{
    config(
        tags=['unit-test']
    )
}}

-- This test causes a database error in BigQuery if implementation
-- does not add back-tick quotes to column names.
{% if target.type == 'bigquery' %}
    {% call dbt_unit_testing.test ('mock_pass_through', 'bigquery keywords are quoted') %}
        {% call dbt_unit_testing.mock_ref ('mock') %}
            SELECT 1 as `end`
        {% endcall %}

        {% call dbt_unit_testing.expect() %}
            SELECT 1 as `end`
        {% endcall %}
    {% endcall %}
{% endif %}