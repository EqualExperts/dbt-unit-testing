select day,
country_name,
cases
from {{ ref('covid19_cases_per_day') }} JOIN {{ source('covid19_stg','covid19_country_stg') }} USING (country_id)