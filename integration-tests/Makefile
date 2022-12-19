TARGETS = bigquery
.PHONY : test

test: export TARGET = $(target)
test: export RUN_SCRIPT = /repo/run-all-integration-tests.sh
test:
	docker-compose -f ../docker-compose.yml up --abort-on-container-exit
