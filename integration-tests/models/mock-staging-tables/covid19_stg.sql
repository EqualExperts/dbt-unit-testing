{{ config(materialized='table',dataset='staging')}}
with values as (
select cast('2020-01-01' as Date) as day,
'' as country_id,
'{}' as payload
)
select * from values where country_id = 'test'