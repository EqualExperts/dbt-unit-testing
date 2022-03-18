{{
    config(
        tags=['unit-test']
    )
}}

{% call dbt_unit_testing.test('binned', 'test complex query') %}
  {% call dbt_unit_testing.mock_ref('base_package') %}
    select 'X1' as device_serial_number, timestamp('2022-01-01 00:17:00') as timestamp, 1.0 as energy
  {% endcall %}

  {% call dbt_unit_testing.mock_ref('stg_device_minutes') %}
    select 'X1' as device_serial_number, timestamp('2022-01-01 00:17:00') as minute_at, timestamp('2022-01-01 00:15:00') as bin_15m_start_at
  {% endcall %}

  {% call dbt_unit_testing.expect() %}
    select 'X1' as device_serial_number, timestamp('2022-01-01 00:17:00') as bin_15m_start_at, 1.0 as energy
  {% endcall %}
{% endcall %}
