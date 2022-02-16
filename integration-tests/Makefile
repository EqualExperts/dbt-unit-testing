TARGETS = bigquery
.PHONY : test

test: export TARGET = $(target)
test:
	docker-compose -f ../docker-compose.yml up --abort-on-container-exit