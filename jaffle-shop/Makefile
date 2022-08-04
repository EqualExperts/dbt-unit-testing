.PHONY : test

test: export TARGET = "postgres"
test: export RUN_SCRIPT = /repo/run-all-jaffle-shop-tests.sh
test:
	docker-compose -f ../docker-compose.yml up --abort-on-container-exit  --force-recreate