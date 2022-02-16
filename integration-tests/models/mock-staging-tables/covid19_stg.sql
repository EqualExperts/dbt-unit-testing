{{ config(materialized='table')}}
with val as (
select cast('2020-01-01' as Date) as day,
'' as country_id,
'{}' as payload
)
select * from val where country_id = 'test'