TARGETS = bigquery
.PHONY : test

test: export TARGET = $(target)
test: export RUN_SCRIPT = /repo/run_test.sh
test:
	docker-compose -f ../docker-compose.yml up --abort-on-container-exit
