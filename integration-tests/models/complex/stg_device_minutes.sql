with devices as (
  select * from {{ dbt_unit_testing.ref('stg_devices') }}
),

base_minutes as (
  select * from {{ dbt_unit_testing.ref('base_minutes') }}
),

final as (
  select
    devices.site_id,
    devices.device_serial_number,
    base_minutes.minute_at,
    base_minutes.bin_15m_start_at,
    base_minutes.bin_15m_end_at
  from
    devices
  cross join
    base_minutes
  where
    base_minutes.minute_at >= date_trunc(devices.min_timestamp_at, minute)
    and
    base_minutes.minute_at < date_trunc(devices.max_timestamp_at, minute)
)

select * from final
