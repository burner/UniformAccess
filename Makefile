fiveud: uniformaccess.d fivek.d fivetodb.d Makefile
	rm -rf fivetodb.db
	dmd uniformaccess.d fivek.d fivetodb.d -offiveud -L-lsqlite3 -L-ldl -I. -noboundscheck -release -O -inline -version=uniform
	./fiveud

fiveudg: uniformaccess.d fivek.d fivetodb.d Makefile
	rm -rf fivetodb.db
	gdc uniformaccess.d -ggdb fivek.d fivetodb.d -o fiveudg -lsqlite3 --inline -fno-bounds-check -I. -Ofast --version=uniform --release
	./fiveudg

hfiveud: uniformaccess.d fivek.d fivetodb.d Makefile
	./makedb2.sh
	dmd uniformaccess.d fivek.d fivetodb.d -offiveud -L-lsqlite3 -L-ldl -I. -noboundscheck -release -O -inline -version=handwritten
	./fiveud

hfiveudg: uniformaccess.d fivek.d fivetodb.d Makefile
	./makedb2.sh
	gdc uniformaccess.d -ggdb fivek.d fivetodb.d -o fiveudg -lsqlite3 --inline -fno-bounds-check -I. -Ofast --version=handwritten --release
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
