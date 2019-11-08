# service info
SERVICENAME ?= database
VERSION ?= 1.0

# connection
USER ?= admin
PASSWORD ?= qwe123
HOST ?= $(shell docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${SERVICENAME})
PORT ?= 5432
DATABASE ?= database

# folder struct
TABLESDIR = sql/tables
FIXTURESDIR = sql/tables/fixtures

# psql aliases
psql_admin := PGPASSWORD=${PASSWORD} psql -h ${HOST}:${PORT} -U postgres -a \
				-v username=${USER}	\
				-v dbname=${DATABASE} \
				-v userpassword="'${PASSWORD}'"

psql_user := PGPASSWORD=${PASSWORD} psql -h ${HOST}:${PORT} -U ${USER} -d ${DATABASE} 

connect:
	$(psql_user)

add-table:
	$(eval NAME=$(strip ${NAME}))
ifeq (${NAME},)
	@echo table name is not defined
	@exit 1
endif
	$(eval NAME=$(shell echo ${NAME} | tr A-Z a-z))
	$(eval files=$(shell find ${TABLESDIR} -maxdepth 1 -type f | wc -l))
	$(eval prefix=$(shell if [ $(files) -lt 10 ]; then echo 0; fi))
	printf 'CREATE TABLE ${NAME} (\n);\n' > ${TABLESDIR}/$(prefix)$(files)'_'${NAME}.sql 

create: init create-tables create-fixtures

init:
	$(psql_admin) -f sql/init.sql

create-tables:
	@echo creating tables...
	$(foreach file, $(shell find ${TABLESDIR} -maxdepth 1 -type f | sort), $(psql_user) -a -f $(file);))	
	@echo done

create-fixtures:
	@echo creating fixtures...
	$(foreach file, $(shell find ${FIXTURESDIR} -maxdepth 1 -type f | sort), $(psql_user) -a -f $(file);))	
	@echo done

recreate: drop create

drop:
	$(psql_admin) -f sql/drop.sql

build:
	docker pull postgres:12.0
	docker tag postgres:12.0 ${SERVICENAME}:${VERSION}

up:	
	docker run \
		--name ${SERVICENAME} \
		--expose ${PORT} \
		-e POSTGRES_PASSWORD=${PASSWORD} \
		-d \
		-v "$(CURDIR)":/database \
		${SERVICENAME}:${VERSION} \
		postgres -p ${PORT}

rm:
	-@docker container rm ${SERVICENAME}

kill:
	-@docker kill ${SERVICENAME}

clean: kill rm
