select day,
country_name,
cases
from {{ ref('covid19_cases_per_day') }} JOIN {{ source('covid19_raw','covid19_country_raw') }} USING (country_id)