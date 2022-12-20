.PHONY : start_dev_postgres

start_dev_postgres:
	@docker run --name postgresql -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres
