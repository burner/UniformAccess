fiveud: uniformaccess.d fivek.d fivetodb.d Makefile
	rm -rf fivetodb.db
	dmd uniformaccess.d fivek.d fivetodb.d -offiveud -L-lsqlite3 -L-ldl -I. -release -O -inline --version=uniform

fiveudg: uniformaccess.d fivek.d fivetodb.d Makefile
	rm -rf fivetodbg.db
	gdc uniformaccess.d fivek.d fivetodb.d -o fiveudg -lsqlite3 -ldl -I. -Ofast --version=uniform
	./fiveudg

cpp: sweetqltest.cpp Makefile makedb.sh
	./makedb.sh
	g++ -Wall --std=c++11 -lsqlite3 -lboost_regex sweetqltest.cpp -o qltest \
	--std=c++11 -Ofast -march=native -I../sweet.hpp
	./qltest

cppclang: sweetqltest.cpp Makefile makedb.sh
	./makedb.sh
	clang++ -Wall --std=c++11 -lsqlite3 -lboost_regex sweetqltest.cpp -o qltest \
	--std=c++11 -O3 -march=native -I../sweet.hpp
	./qltest

c: csql.c Makefile
	./makedb.sh
	gcc -Wall -lsqlite3 csql.c -o csql --std=c99 -Ofast -march=native
	./csql
	
cclang: csql.c Makefile
	./makedb.sh
	clang -Wall -lsqlite3 csql.c -o csql --std=c99 -O3 -march=native
	./csql
