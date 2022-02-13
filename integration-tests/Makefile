TARGETS = bigquery
.PHONY : test install-deps create-mock-staging-tables dbt-run run-unit-tests

test: export TARGET = $(target)
test:
	docker-compose -f ../docker-compose.yml up dbt

install-deps:
	dbt deps --profiles-dir ci --target bigquery

create-mock-staging-tables:
	dbt run --profiles-dir ci --target bigquery --models mock-staging-tables

dbt-run:
	dbt run --profiles-dir ci --target bigquery --models transform staging product

run-unit-tests:
	dbt test  --profiles-dir ci --models tag:unit-test  --target bigquery

