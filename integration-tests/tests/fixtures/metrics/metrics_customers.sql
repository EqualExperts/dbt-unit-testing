select * 
from {{ metrics.calculate(
    metric_list=[metric('average_order_amount'), metric('total_order_amount'), metric('generic_sum')],
    grain='all_time',
    dimensions=[],
) }}
