WITH spine AS (
  {{
    dbt_utils.date_spine(
      datepart="minute",
      start_date="datetime '2020-01-01 00:00:00'",
      end_date="current_datetime() + interval 1 week"
     )
  }}
),

final as (
  select
    timestamp(date_minute, 'UTC') as minute_at,
    -- The first minute of an interval is associated with the previous bin
    -- because signals are typically recorded on the 15 minute mark and correspond to the previous 15 min
    {% set bin_15m_start = "timestamp(date_minute, 'UTC') - interval 1 minute - interval mod(extract(minute from date_minute - interval 1 minute), 15) minute" %}
    {{ bin_15m_start }} as bin_15m_start_at,
    {{ bin_15m_start }} + interval 15 minute as bin_15m_end_at
  from
    spine
  order by
    date_minute
)

select * from final
