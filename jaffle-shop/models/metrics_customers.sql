select * 
from {{ metrics.calculate(
    metric_list=[metric('average_order_amount'), metric('total_order_amount')],
    grain='all_time',
    dimensions=[],
) }}
