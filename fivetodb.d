import uniformaccess;
import std.stdio;
import std.datetime;
import std.file : exists;
import std.typecons;
import std.csv;
import std.conv;
import five;

void checkIfDBExists(string dbName) {
	if(!exists(dbName)) {
		auto f = File(dbName, "w");
		f.close();
	}
}

void main() {
	auto f = File("50000.csv");

	Five arr[50000];
	size_t idx = 0;

	foreach(it; f.byLine()) {
		foreach(jt; csvReader!Five(it)) {
			arr[idx++] = jt;
		}	
	}
	assert(idx == 50000, to!string(idx));

	version(DigitalMars) {
		string dbname = "fivetodb.db";
	}
	version(GNU) {
		string dbname = "fivetodbg.db";
	}
	checkIfDBExists(dbname);
	auto db = Sqlite(dbname);
	db.createTable!Five();

	StopWatch sw;
	sw.start();
	version(uniform) {
		db.beginTransaction();
		foreach(it; arr) {
			db.insert(it);
		}
		db.endTransaction();
	}
	writefln("%d", sw.peek.msecs);
}
