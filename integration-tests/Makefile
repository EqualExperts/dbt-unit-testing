TARGETS = bigquery
.PHONY : test install-deps create-mock-staging-tables dbt-run run-unit-tests

test: export TARGET = $(target)
test:
	docker-compose -f ../docker-compose.yml up dbt