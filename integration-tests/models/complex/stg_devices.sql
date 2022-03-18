with all_signal_sources as (
  select device_serial_number, timestamp from {{ dbt_unit_testing.ref('base_cyc_a') }}
  union all
  select device_serial_number, timestamp from {{ dbt_unit_testing.ref('base_cyc_b') }}
  union all
  select device_serial_number, timestamp from {{ dbt_unit_testing.ref('stg_grid') }}
  union all
  select device_serial_number, timestamp from {{ dbt_unit_testing.ref('base_package') }}
),

package_locations as (
  select * from {{ dbt_unit_testing.ref('seed_device_site') }}
),

all_devices as (
  select
    device_serial_number,
    min(timestamp) as min_timestamp_at,
    max(timestamp) as max_timestamp_at
  from
    all_signal_sources
  group by
    1
),

final as (
  select
    coalesce(package_locations.site_id, all_devices.device_serial_number) as site_id,
    all_devices.device_serial_number,
    all_devices.min_timestamp_at,
    all_devices.max_timestamp_at
  from
    all_devices
  left join
    package_locations
  on
    all_devices.device_serial_number = package_locations.device_serial_number
)

select * from final
