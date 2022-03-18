with binned_signals as (
  with signals as (
    select
      device_serial_number,
      timestamp as signal_at,
      date_trunc(timestamp, minute) as signal_minute_at,
      energy
    from
      {{ dbt_unit_testing.ref('base_package') }}
  ),

  device_minutes as (
    select * from {{ dbt_unit_testing.ref('stg_device_minutes') }}
  ),

  assign_bins as (
    select
      device_minutes.site_id,
      device_minutes.device_serial_number,
      device_minutes.bin_15m_start_at,
      device_minutes.bin_15m_end_at,
      signals.energy,
      coalesce(signals.signal_at, device_minutes.minute_at) as signal_at
    from
      device_minutes
    left join
      signals
    on
      device_minutes.device_serial_number = signals.device_serial_number
      and
      device_minutes.minute_at = signals.signal_minute_at

  ),

  -- Yes, these are completely useless, but having them produces the error
  just_another_query as (
    select t1.*, 1 as d_energy
    from assign_bins as t1
    inner join assign_bins as t2
    on
      t1.device_serial_number = t2.device_serial_number
      and
      t1.signal_at = t2.signal_at
  ),

  just_another_query_2 as (
    select t1.*, 1 as d_energy
    from just_another_query as t1
    inner join just_another_query as t2
    on
      t1.device_serial_number = t2.device_serial_number
      and
      t1.signal_at = t2.signal_at
  )


  select * from just_another_query_2
),

final as (
  select * from binned_signals
)

select * from final
