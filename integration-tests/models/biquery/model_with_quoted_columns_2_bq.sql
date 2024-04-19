select 
    lower,
    UPPER,
    MiXeD,
    `lower quoted`,
    `UPPER QUOTED`,
    `MiXeD Quoted`
from {{ dbt_unit_testing.ref('model_with_quoted_columns_1_bq') }}
where
    (lower = 10 or lower is null)
and (UPPER = 20 or UPPER is null)
and (MiXeD = 30 or MiXeD is null)
and (`lower quoted` = 40 or `lower quoted` is null)
and (`UPPER QUOTED` = 50 or `UPPER QUOTED` is null)
and (`MiXeD Quoted` = 60 or `MiXeD Quoted` is null)


