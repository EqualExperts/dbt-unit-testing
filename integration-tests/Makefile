TARGETS = bigquery
.PHONY : test $(TARGETS)

test: export TARGET = $(target)
test:
	docker-compose -f ../docker-compose.yml up

$(TARGETS):
	$(MAKE) test target=$@