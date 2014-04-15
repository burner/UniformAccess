fiveud: uniformaccess.d fivek.d fiveud.d Makefile
	rm -rf fivetodb.db
	dmd fiveud.d uniformaccess.d fivek.d -offiveud -L-lsqlite3 -L-ldl \
	-O -inline -noboundscheck -release
	./fiveud

fiveudl: uniformaccess.d fivek.d fiveud.d Makefile
	rm -rf fivetodb.db
	ldc2 fiveud.d uniformaccess.d fivek.d -offiveudl -L-lsqlite3 -L-ldl \
	-O3 -disable-boundscheck
	./fiveudl

fiveudg: uniformaccess.d fivek.d fivetodb.d Makefile
	rm -rf fivetodb.db
	gdc fiveud.d uniformaccess.d fivek.d -o fiveudg -lsqlite3 -ldl \
	-Ofast --inline -fno-bounds-check --release
	./fiveudg

hfiveud: uniformaccess.d fivek.d fivetodb.d Makefile
	./makedb2.sh
	dmd uniformaccess.d fivek.d fivetodb.d -ofhfiveud -L-lsqlite3 -L-ldl -I. \
	-noboundscheck -release -O -inline -version=handwritten
	./hfiveud

hfiveudl: uniformaccess.d fivek.d fivetodb.d Makefile
	./makedb2.sh
	ldc2 uniformaccess.d fivek.d fivetodb.d -ofhfiveud -L-lsqlite3 -L-ldl -I. \
	-O3 -disable-boundscheck
	./hfiveud

hfiveudg: uniformaccess.d fivek.d fivetodb.d Makefile
	./makedb2.sh
	gdc uniformaccess.d -ggdb fivek.d fivetodb.d -o hfiveudg -lsqlite3 \
	--inline -fno-bounds-check -I. -Ofast --version=handwritten --release
	./hfiveudg

cpp: sweetqltest.cpp Makefile makedb.sh
	./makedb.sh
	g++ -Wall --std=c++11 -lsqlite3 -lboost_regex sweetqltest.cpp -o qltest \
	--std=c++11 -Ofast -march=native -I../sweet.hpp -flto
	./qltest

cppclang: sweetqltest.cpp Makefile makedb.sh
	./makedb.sh
	clang++ -Wall --std=c++11 -lsqlite3 -lboost_regex sweetqltest.cpp \
	-o qltestl --std=c++11 -O3 -march=native -I../sweet.hpp -flto
	./qltestl

c: csql.c Makefile
	./makedb.sh
	gcc -Wall -lsqlite3 csql.c -o csql --std=c99 -Ofast -march=native -flto
	./csql
	
cclang: csql.c Makefile
	./makedb.sh
	clang -Wall -lsqlite3 csql.c -o csqll --std=c99 -O3 -march=native -flto
	./csqll

clean:
	rm -f fiveud ; \
	rm -f fiveudg ; \
	rm -f qltest; \
	rm -f csql; \
	rm -f gccc; \
	rm -f gcccpp; \
	rm -f clangc; \
	rm -f clangcpp; \
	rm -f gdcgen; \
	rm -f gdchand; \
	rm -f dmdgen; \
	rm -f dmdhand

test: clean fiveud fiveudg hfiveud hfiveudg cpp cppclang c cclang
	number=1 ; while [[ $$number -le 100 ]] ; do \
		echo $$number :; \
		rm fivetodb.db ; \
		./fiveud >> dmdgen ; \
		rm fivetodb.db ; \
		./fiveudg >> gdcgen ; \
		./makedb2.sh ; \
		./hfiveud >> dmdhand ; \
		./makedb2.sh ; \
		./hfiveudg >> gdchand ; \
		./makedb.sh ; \
		./qltest >> gcccpp ; \
		./makedb.sh ; \
		./qltestl >> clangcpp ; \
		./makedb.sh ; \
		./csql >> gccc ; \
		./makedb.sh ; \
		./csqll >> clangc ; \
 		((number = number + 1)) ; \
	done
	dmd sum.d ; \
	./sum ; \
