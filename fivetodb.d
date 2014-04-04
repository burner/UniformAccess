import uniformaccess;
import std.stdio;
import std.datetime;
import std.file : exists;
import std.typecons;
import std.csv;
import std.conv;
import five;

version(handwritten) {
	import etc.c.sqlite3;
	void dummy(void* d) {}
}

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

	string dbname = "fivetodb.db";
	version(handwritten) {
		dbname = "testtable.db";
	}

	version(uniform) {
		checkIfDBExists(dbname);
		auto db = Sqlite(dbname);
		db.createTable!Five();
	}

	StopWatch sw;
	version(uniform) {
		sw.start();
		db.beginTransaction();
		foreach(it; arr) {
			db.insert(it);
		}
		db.endTransaction();
	}
	version(handwritten) {
		sqlite3 *db2;
		sqlite3_open(toStringz(dbname), &db2);
		sqlite3_stmt *stmt;
		sw.start();
		sqlite3_exec(db2, "BEGIN TRANSACTION;", null, null, null);
		string istmt = "INSERT INTO Person(firstname, lastname, company, road, city, state, stateaka, zip, telefon, fax, email, web) Values(?,?,?,?,?,?,?,?,?,?,?,?);";
		sqlite3_prepare_v2(db2, toStringz(istmt), to!int(istmt.length), &stmt, null);
		foreach(it; arr) {
			int j = 1;
			sqlite3_bind_text(stmt, j++, toStringz(it.firstname), to!int(it.firstname.length), null);
			sqlite3_bind_text(stmt, j++, toStringz(it.lastname), to!int(it.lastname.length), null);
			sqlite3_bind_text(stmt, j++, toStringz(it.company), to!int(it.company.length), null);
			sqlite3_bind_text(stmt, j++, toStringz(it.road), to!int(it.road.length), null);
			sqlite3_bind_text(stmt, j++, toStringz(it.city), to!int(it.city.length), null);
			sqlite3_bind_text(stmt, j++, toStringz(it.state), to!int(it.state.length), null);
			sqlite3_bind_text(stmt, j++, toStringz(it.stateaka), to!int(it.stateaka.length), null);
			sqlite3_bind_int(stmt, j++, it.zip);
			sqlite3_bind_text(stmt, j++, toStringz(it.telefon), to!int(it.telefon.length), null);
			sqlite3_bind_text(stmt, j++, toStringz(it.fax), to!int(it.fax.length), null);
			sqlite3_bind_text(stmt, j++, toStringz(it.email), to!int(it.email.length), null);
			sqlite3_bind_text(stmt, j++, toStringz(it.web), to!int(it.web.length), null);
			assert(j == 13);
			if(sqlite3_step(stmt) != SQLITE_DONE) {
				writeln(to!string(sqlite3_errmsg(db2)));
				return;
			}
			sqlite3_reset(stmt);
		}
		sqlite3_finalize(stmt);
		sqlite3_exec(db2, "END TRANSACTION;", null, null, null);

	}
	writefln("%d", sw.peek.msecs);
}
