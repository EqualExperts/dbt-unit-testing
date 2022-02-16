{{ config(materialized='table')}}
with val as (
select 
'' as country_id,
'' country_name
)
select * from val where country_name = 'test'