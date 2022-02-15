TARGETS = bigquery
.PHONY : test $(TARGETS)

test: export TARGET = $(target)
test:
	docker-compose -f ../docker-compose.yml up --abort-on-container-exit

$(TARGETS):
	$(MAKE) test target=$@