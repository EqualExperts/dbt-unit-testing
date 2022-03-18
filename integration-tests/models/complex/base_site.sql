select
  *
from
  {{ dbt_unit_testing.source('dbt_unit_testing', 'site') }}
where
  true
qualify
  -- Remove duplicated signals
  row_number() over (
    partition by device_serial_number, timestamp order by timestamp desc
  ) = 1
