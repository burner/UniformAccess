#include <string>
#include <sstream>
#include <fstream>
#include <boost/regex.hpp>
#include <utility>
#include <iostream>
#include <algorithm>
#include <sweetql.hpp>
//#include <conv.hpp>
#include <benchmark.hpp>

class Person {
public:
	Person() {} // dummy
	Person(const std::string& f, const std::string& l, const std::string& c, 
			const std::string& a, const std::string& a2,
			const std::string& ci, const std::string& s, int z, 
			const std::string& pw, const std::string& pp, const std::string& m, 
			const std::string& w) :
		firstname(f),	 lastname(l),	 company(c),
 		address(a),		 county(a2),	 city(ci),
 		state(s),		 phoneWork(pw),	 phonePrivat(pp),
 		mail(m),		 www(w),		 zip(z) {
	}

	std::string firstname;
	std::string lastname;
	std::string company;
	std::string address;
	std::string county;
	std::string city;
	std::string state;
	std::string phoneWork;
	std::string phonePrivat;
	std::string mail;
	std::string www;
	int64_t zip;

	static SqlTable<Person>& table() {
		static SqlTable<Person> tab = SqlTable<Person>::sqlTable("Person",
			SqlColumn<Person>("Firstname", 	makeAttr(&Person::firstname)),
			SqlColumn<Person>("Lastname", 	makeAttr(&Person::lastname)),
			SqlColumn<Person>("Company", 	makeAttr(&Person::company)),
			SqlColumn<Person>("Address", 	makeAttr(&Person::address)),
			SqlColumn<Person>("County", 	makeAttr(&Person::county)),
			SqlColumn<Person>("City", 		makeAttr(&Person::city)),
			SqlColumn<Person>("State", 		makeAttr(&Person::state)),
			SqlColumn<Person>("PhoneWork", 	makeAttr(&Person::phoneWork)),
			SqlColumn<Person>("PhonePrivat",makeAttr(&Person::phonePrivat)),
			SqlColumn<Person>("Mail", 		makeAttr(&Person::mail)),
			SqlColumn<Person>("Www", 		makeAttr(&Person::www)),
			SqlColumn<Person>("Zip", 		makeAttr(&Person::zip))
		);
		return tab;
	}
};

typedef std::vector<Person> PersonVec;

PersonVec parsePersonFile(const std::string& fn) {
	PersonVec ret;
	std::ifstream infile(fn);
	std::vector<std::string> v;
	std::string line;
	boost::regex re("\"[^\"]+\"");
	while(std::getline(infile, line)) {
		auto reBe = boost::sregex_iterator(line.begin(), line.end(), re);
    	auto reEn = boost::sregex_iterator();
		std::transform(reBe, reEn, std::back_inserter(v), [&v]
			(const boost::smatch& it) {
				return it.str().substr(1, it.str().size()-2);
			}
		);
		ret.push_back(Person(v[0], v[1], v[2], v[3], v[4], v[5], v[6],
					stoi(v[7]), v[8], v[9], v[10], v[11]));
		v.clear();
	}

	return ret;
}

int main() {
	SqliteDB db("testtable.db");

	sweet::Bench in;
	std::vector<Person> per = parsePersonFile("50000.csv");
	in.stop();
	std::cout<<"Reading the file took "<<in.milli()<<" msec"<<std::endl;

	sweet::Bench insert;
	db.insert<Person>(per.begin(), per.end());
	//Reservation a("Danny", "Zeckzer", "Armsen", "02.04.2013");
	//db.insert<Reservation>(a);
	insert.stop();
	std::cout<<"Writting the persons to the db took "<<insert.milli()
		<<" msec"<<std::endl;

	return 0;
}
