select 
    lower,
    UPPER,
    MiXeD,
    "lower quoted",
    "UPPER QUOTED",
    "MiXeD Quoted"
from {{ dbt_unit_testing.ref('model_with_quoted_columns_1') }}
where
    (lower = 1 or lower is null)
and (UPPER = 2 or UPPER is null)
and (MiXeD = 3 or MiXeD is null)
and ("lower quoted" = 4 or "lower quoted" is null)
and ("UPPER QUOTED" = 5 or "UPPER QUOTED" is null)
and ("MiXeD Quoted" = 6 or "MiXeD Quoted" is null)


