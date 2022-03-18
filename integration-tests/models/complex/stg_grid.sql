select 'crd' as record_origin, device_serial_number, timestamp, sig from {{ dbt_unit_testing.ref('base_crd') }}
union all
select 'site' as record_origin, device_serial_number, timestamp, sig from {{ dbt_unit_testing.ref('base_site') }}
