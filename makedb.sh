#!/bin/sh

if [ -f testtable.db ]; then
	rm testtable.db
else
	echo "Args"
fi

sqlite3 testtable.db "CREATE TABLE Person(Firstname varchar, Lastname varchar, Company varchar, Address varchar, County varchar, City varchar, State varchar, Zip integer, PhoneWork varchar, PhonePrivat varchar, Mail varchar, Www varchar, PRIMARY KEY(Firstname, Lastname, Company, Address));"
