#!/bin/bash -eu
DOMAIN_NAME=
DB_USER=
DB_PW=
DB_NAME=

date "+tar -czpf ./%Y%m%d_%H%M_${DOMAIN_NAME}_file.tar.gz ../${DOMAIN_NAME}/ >> %Y%m%d_%H%M_${DOMAIN_NAME}_file.log" | /bin/bash
date "+mysqldump -u ${DB_USER} -p${DB_PW} ${DB_NAME} --log-error=%Y%m%d_%H%M_${DB_NAME}_db.log > ./%Y%m%d_%H%M_${DB_NAME}_db.sql" | /bin/bash
