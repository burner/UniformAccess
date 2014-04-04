#!/bin/sh

if [ -f testtable.db ]; then
	rm testtable.db
else
	echo "Args"
fi

sqlite3 testtable.db "CREATE TABLE Person(firstname varchar, lastname varchar, company varchar, road varchar, city varchar, state varchar, stateaka varchar, zip integer, telefon varchar, fax varchar, email varchar, web varchar, PRIMARY KEY(firstname, lastname, company, road));"
