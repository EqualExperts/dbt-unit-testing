{% macro n_days_ago(days=0) %}
  {{ return (modules.datetime.datetime.utcnow() - modules.datetime.timedelta(days)) }}
{% endmacro %}

{% macro to_epoch(dt) %}
  {{ return ((dt - modules.datetime.datetime.utcfromtimestamp(0)).total_seconds() * 1000) }}
{% endmacro %}

{% macro to_iso(dt, sep=' ', timespec='milliseconds') %}
  {{ return (dt.isoformat(sep, timespec)) }}
{% endmacro %}

{% macro generate_n_days_ago_variables() %}
  {% set result = {} %}
  {% for ind in [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 39, 30, 50, 100, 200, 300, 500, 1000] %}
    {% do result.update({'-' ~ ind ~ 'd_dt': dbt_unit_testing.n_days_ago(ind)}) %}
    {% do result.update({'-' ~ ind ~ 'd_epoch': dbt_unit_testing.to_epoch(result['-' ~ ind ~ 'd_dt'])}) %}
  {% endfor %}
  {{ return ( result ) }}
{% endmacro %}