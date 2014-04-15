// Robert burner Schadek rburners@gmail.com LGPL3 
module uniformaccess;

import std.stdio;
import std.algorithm;
import std.exception;
import std.array;
public import std.string;
public import std.conv;
import std.traits;

import etc.c.sqlite3;

public pure bool cStrCmp(string s)(const(char)* cs) @trusted nothrow {
	if(cs is null) {
		return false;
	}

	size_t i = 0;
	for(; i < s.length; ++i) {
		if(cs[i] == '\0') {
			return false;
		} 
		if(cs[i] != s[i]) {
			return false;
		}
	}

	return i == s.length && cs[i] == '\0';
}

unittest {
	assert(cStrCmp!"hello"(toStringz("hello")));
	assert(!cStrCmp!"hello"(toStringz("hellouz")));
	assert(!cStrCmp!"hello"(toStringz("hellz")));
	assert(!cStrCmp!"hello"(toStringz("hell")));
}

struct StaticToStringZ(const size_t size) {
	char[size] data = void;
	
	pure void clear() @safe nothrow {
		this.data[] = '\0';
	}

	const(char)* toStringZ(string s) @trusted nothrow {
		size_t idx = 0;
		foreach(char c; s) {
			this.data[idx++] = c;
		}
		this.data[idx] = '\0';

		return cast(const(char)*)this.data.ptr;
	}	
}

unittest {
	StaticToStringZ!1024 s;
	auto cs = s.toStringZ("Hello");
	assert(to!string(cs) == "Hello");
}

struct Data {
	@("NotUA") float someother;
	@("UA") int interval;
	@("UA", "foo") int bar;
	@("UA", "wingdings", "Primary_Key") int key;
	//@("UA") int zzz;
	int zzz;
}

@("UA", "SomeOtherTableName2") struct Datas444 {
	@("NotUA") float someother;
	@("UA") int interval;
	@("UA", "foo") int bar;
	@("UA", "wingdings", "Primary_Key") int key;
	@("UA", "Primary_Key") int zzz;
}

/// Get Primary Key of Aggregation

string[] extractPrimaryKeyNames(T)() {
	string[] ret;
	foreach(it;__traits(allMembers, T)) {
		if(isCallable!(__traits(getMember, T, it))) {
			continue;
		} else {
			string[] tmp = extractMemberNamesImpl!(T,it)().split(" ").array;
			if(tmp.empty) {
				continue;
			}
			foreach(jt; tmp) {
				jt.strip();
			}
			string cName = customName(tmp);
			if(isUA(tmp) && holdsPrimaryKey(tmp) && !cName.empty) {
				ret ~= cName;
			} else if(isUA(tmp) && holdsPrimaryKey(tmp) && cName.empty) {
				ret ~= it;
			}
		}
	}
	return ret;
}

unittest {
	static assert(extractPrimaryKeyNames!Data() == ["wingdings"],
		extractPrimaryKeyNames!Data());
	static assert(extractPrimaryKeyNames!Datas444() == ["wingdings", "zzz"],
		extractPrimaryKeyNames!Datas444());
}

/// Get Tabelname the Aggregation maps

string getName(T)() @safe {
	enum fully = fullyQualifiedName!T;
	int l = -1;
	foreach_reverse(idx, dchar it; fully) {
		if(it == '.') {
			l = to!int(idx);
			break;
		}
	}
	if(l != -1) {
		return fully[l+1 .. $];
	} else {
		return fully;
	}
}

unittest {
	import std.container : Array;

	static assert(getName!Data == "Data");
	//static assert(getName!Array == "std.container.Array");
}

bool getTableWithoutRowId(T)() {
	string ret;
	foreach(it; __traits(getAttributes, T)) {
		ret ~= it ~ " ";
	}
	string[] tmp = ret.split(" ");
	foreach(it; tmp) {
		it.strip();
	}

	bool wo = false;
	foreach(it; tmp) {
		if(it == "WITHOUT_ROWID") {
			wo = true;
			break;
		}
	}

	if(tmp.length >= 1 && tmp[0] == "UA" && wo) {
		return true;
	} else {
		return false;
	}
}

bool isTableWithoutRowId(T)() {
	string ret;
	foreach(it; __traits(getAttributes, T)) {
		ret ~= it ~ " ";
	}
	string[] tmp = ret.split(" ");
	foreach(ref it; tmp) {
		it.strip();
	}

	foreach(it; tmp) {
		if(it == "WITHOUT_ROWID") {
			return true;
		}
	}
	return false;
}

string getTableNameOfAggregation(T)() {
	string ret;
	foreach(it; __traits(getAttributes, T)) {
		ret ~= it ~ " ";
	}
	string[] tmp = ret.split(" ");
	foreach(ref it; tmp) {
		it.strip();
	}

	if(tmp.length >= 2 && tmp[0] == "UA" && tmp[1] != "WITHOUT_ROWID" &&
			!tmp[1].empty) {
		return tmp[1] != "WITHOUT_ROWID" ? tmp[1] : tmp[2];
	} else {
		return getName!T;
	}
}

@("UA") struct EntryF {
}

unittest {
	static assert(getTableNameOfAggregation!EntryF() == "EntryF",
		getTableNameOfAggregation!EntryF);
	static assert(getTableNameOfAggregation!Data() == "Data",
		getTableNameOfAggregation!Data);
	static assert(getTableNameOfAggregation!Datas444() ==
			"SomeOtherTableName2", getTableNameOfAggregation!Datas444);
}

/// Get names of column the data member map

pure bool isUA(string[] arr) @safe nothrow {
	foreach(it; arr) {
		if(it == "UA") {
			return true;
		} else if(it == "NotUA") {
			return false;
		} else {
			return true;
		}
	}
	return true;
}

pure string customName(string[] arr) @safe nothrow {
	foreach(it; arr) {
		if(it != "UA" && it != "NotUA" && it != "Primary_Key" && !it.empty &&
				it != "AutoIncrement") {
			return it;
		}
	}
	return "";
}

pure bool holdsPrimaryKey(string[] arr) @safe nothrow {
	foreach(it; arr) {
		if(it == "Primary_Key") {
			return true;
		}
	}
	return false;
}

string[2][] extractMemberNamesWithout(T)() {
	string[2][] ret;
	foreach(it;__traits(allMembers, T)) {
		if(isCallable!(__traits(getMember, T, it))) {
			continue;
		} else {
			string[] tmp = extractMemberNamesImpl!(T,it)().split(" ").array;
			string cName = customName(tmp);
			if(isUA(tmp) && !holdsPrimaryKey(tmp)) {
				ret ~= cName.empty ? [it,it] : [cName, it];
			}
		}
	}

	return ret;
}

string[2][] extractMemberNames(T)() {
	string[2][] ret;
	foreach(it;__traits(allMembers, T)) {
		if(isCallable!(__traits(getMember, T, it))) {
			continue;
		} else {
			string[] tmp = extractMemberNamesImpl!(T,it)().split(" ").array;
			string cName = customName(tmp);
			if(isUA(tmp)) {
				ret ~= cName.empty ? [it,it] : [cName, it];
			}
		}
	}

	return ret;
}

string extractMemberNamesImpl(T,string m)() {
	string ret;
	foreach(it; __traits(getAttributes, __traits(getMember, T, m))) {
		ret ~= it.strip() ~ " ";
	}
	return ret;
}

unittest {
	static assert(extractMemberNamesWithout!Data() == 
		[["interval", "interval"], ["foo", "bar"], 
		["zzz", "zzz"]], 
		extractMemberNamesWithout!Data()
	);
}


/* Sqlite Part */

// insert

pure string insertDataMember(string a) @safe nothrow {
	return
	"\tstatic if(is(typeof(this." ~  a ~ ") == long)) {\n" ~
	"\t\tsqlite3_bind_int64(stmt, i++, this." ~ a ~ ");\n" ~
	"\t} else static if(isIntegral!(typeof(this." ~  a ~ "))) {\n" ~
	"\t\tsqlite3_bind_int(stmt, i++, this." ~ a ~ ");\n" ~
	"\t} else static if(isFloatingPoint!(typeof(this." ~ a ~ "))) {\n" ~
	"\t\tsqlite3_bind_double(stmt, i++, this." ~ a ~ ");\n" ~
	"\t} else static if(isSomeString!(typeof(this." ~ a ~ "))) {\n" ~
	"\t\tsqlite3_bind_text(stmt, i++, toStringz(this." ~ a ~ "), to!int(this." 
	//"\t\tsqlite3_bind_text(stmt, i++, toCstrPara.toStringZ(this." ~ a ~ "), to!int(this." 
	//~ a ~ ".length), SQLITE_STATIC);\n" ~
	~ a ~ ".length), null);\n" ~
	"\t} else {\n" ~
	"\t\tstatic assert(false);\n" ~
	"\t}\n";
}

string genInsertElemCount(T)() {
	string[2][] member;
	if(isTableWithoutRowId!T()) {
	   	member = extractMemberNames!T();
	} else {
	   	member = extractMemberNamesWithout!T();
	}
	return to!string(member.length+1);
}

string genInsertStatement(T)() {
	string[2][] member;
	if(isTableWithoutRowId!T()) {
	   	member = extractMemberNames!T();
	} else {
	   	member = extractMemberNamesWithout!T();
	}
	//string[2][] member = extractMemberNames!T();
	string tableName = getTableNameOfAggregation!T();

	string stmtStr = "INSERT INTO "~ tableName ~ "(";
	foreach(it; member) {
		stmtStr ~= it[0] ~ ",";
	}
	stmtStr = stmtStr[0 .. $-1] ~ ") Values(";
	foreach(it; member) {
		stmtStr ~= "?, ";
	}
	stmtStr = stmtStr[0 .. $-2] ~ ");";
	return stmtStr;
}

version(unittest) {
	@("UA", "SomeOtherTableName") struct Datas2 {
		@("NotUA") float someother;
		@("UA") float interval;
		@("UA", "foo") int bar;
		@("UA") int zzz;
		@("UA", "wingdings", "Primary_Key") int key;
	}
}

string genInsertAddParameterMixinString(T)() {
	string[2][] member;
	//string[2][] member = extractMemberNames!T();
	if(isTableWithoutRowId!T()) {
	   	member = extractMemberNames!T();
	} else {
	   	member = extractMemberNamesWithout!T();
	}
	string ret;
	
	foreach(it; member) {
		ret ~= insertDataMember(it[1]);
	}

	return ret;
}

bool isAutoincrement(string[] names) {
	foreach(it; names) {
		if(it == "AutoIncrement") {
			return true;
		}
	}
	return false;
}

// remove

string tableNameOfKey(string[2][] hay, string nee) {
	foreach(it; hay) {
		if(it[1] == nee) {
			return it[0];
		}
	}
	assert(false, nee ~ to!string(hay));
}

string memberNameOfKey(string[2][] hay, string nee) {
	foreach(string[2] it; hay) {
		if(it[0] == nee) {
			return it[1];
		}
	}
	assert(false, nee ~ to!string(hay));
}

string genRemoveStatement(T)() {
	string[2][] member = extractMemberNames!T();
	string[] keys = extractPrimaryKeyNames!T();
	assert(!keys.empty);
	string ret = "DELETE FROM " ~ getTableNameOfAggregation!T() ~ " WHERE ";
	foreach(it; keys) {
		ret ~= it ~ "=? AND ";
	}
	ret = ret[0 .. $-4] ~ ";";
	return ret;
}

string genRemoveParameterMixinString(T)() {
	string[2][] member = extractMemberNames!T();
	string[] keys = extractPrimaryKeyNames!T();
	string ret;
	foreach(it; keys) {
		ret ~= insertDataMember(memberNameOfKey(member, it));
	}
	return ret;
}

// update

bool isPrimaryKeyElement(string[] keys, string name) {
	foreach(it; keys) {
		if(it == name) {
			return true;
		}
	}
	return false;
}

string genUpdateStatement(T)() {
	string[2][] member = extractMemberNamesWithout!T();
	string[] keys = extractPrimaryKeyNames!T();
	assert(!keys.empty);

	string ret = "UPDATE " ~ getTableNameOfAggregation!T() ~ " SET ";
	foreach(it; member) {
		if(!isPrimaryKeyElement(keys, it[0])) {
			ret~= it[0] ~ "=? ,";
		}
	}
	ret = ret[0 .. (!ret.empty ? $-2 : $)] ~ " Where ";
	foreach(it; keys) {
		ret ~= it ~ "=? AND ";
	}
	ret = ret[0 .. $-4] ~ ";";
	return ret;
}

string genUpdateParameterMixinString(T)() {
	string[2][] member = extractMemberNames!T();
	string[] keys = extractPrimaryKeyNames!T();
	string ret;
	foreach(it; member) {
		if(!isPrimaryKeyElement(keys, it[0])) {
			ret ~= insertDataMember(it[1]);
		}
	}
	foreach(it; keys) {
		ret ~= insertDataMember(memberNameOfKey(member, it));
	}
	return ret;
}

//pragma(msg, genUpdateStatement!Data());
//pragma(msg, genUpdateParameterMixinString!Data());

// select

pure string fillDataMember(string a, string dba) @safe nothrow {
	return 
	//"case \"" ~ dba ~ "\":\n" ~
	//"\tif(cStrCmp!cn == \"" ~ dba ~ "\") {\n" ~
	"\tif(cStrCmp!\"" ~ dba ~ "\"(cn)) {\n" ~
	"\t\tstatic if(is(typeof(T." ~ a ~ ") == long)) {\n" ~
	"\t\t\tif(sqlite3_column_type(stmt, i) == SQLITE_INTEGER) {\n" ~
	"\t\t\t\tret." ~ a ~ " = sqlite3_column_int(stmt, i);\n" ~ 
	"\t\t\t}\n" ~
	"\t\t} else static if(isIntegral!(typeof(T." ~ a ~ "))) {\n" ~
	"\t\t\tif(sqlite3_column_type(stmt, i) == SQLITE_INTEGER) {\n" ~
	"\t\t\t\tret." ~ a ~ " = sqlite3_column_int(stmt, i);\n" ~ 
	"\t\t\t}\n" ~
	"\t\t} else static if(isFloatingPoint!(typeof(T." ~ a ~ "))) {\n" ~
	"\t\t\tif(sqlite3_column_type(stmt, i) == SQLITE_FLOAT) {\n" ~
	"\t\t\t\tret." ~ a ~ " = sqlite3_column_double(stmt, i);\n" ~ 
	"\t\t\t}\n" ~
	"\t\t} else static if(isSomeString!(typeof(T." ~ a ~ "))) {\n" ~
	"\t\t\tif(sqlite3_column_type(stmt, i) == SQLITE3_TEXT) {\n" ~
	"\t\t\t\tret." ~ a ~ " = to!string(sqlite3_column_text(stmt, i));\n" ~
	"\t\t\t}\n" ~
	"\t\t}\n" ~
	//"break;";
	"\t}\n";
}

string genRangeItemFill(T)() {
	string ret = "T buildItem(T)() {" ~
		"\n\tT ret" ~ (is(T : Object) ? " = new T();" : ";") ~
		"\n\tsize_t cc = sqlite3_column_count(stmt);\n" ~
		"\tfor(int i = 0; i < cc; ++i) {\n" ~
		//"string cn = to!string(sqlite3_column_name(stmt, i));"~
		"\tconst(char)* cn = sqlite3_column_name(stmt, i);\n"~
		//"switch(cn) {" ~
		//"default: break;";
		"";
	foreach(string[2] it; extractMemberNames!T()) {
		ret ~= fillDataMember(it[1], it[0]);
	}
	
	ret ~= "\t}\n\treturn ret;\n}\n";
	return ret;
}

// Create Table

string sqliteTypeNameFromType(T)(string[2] a) {
	return 
	"\tstatic if(isIntegral!(typeof(this." ~ a[1] ~ "))) {\n" ~
	"\t\tcreateTableStmt ~= \"" ~ a[0] ~ " INTEGER,\";\n" ~
	"\t} else static if(isFloatingPoint!(typeof(this." ~ a[1] ~ "))) {\n" ~
	"\t\tcreateTableStmt ~= \"" ~ a[0] ~ " FLOAT,\";\n" ~
	"\t} else static if(isSomeString!(typeof(this." ~ a[1] ~ "))) {\n" ~
	"\t\tcreateTableStmt ~= \"" ~ a[0] ~ " STRING,\";\n" ~
	"\t}\n";
}

string genCreateTableStatement(T)() {
	enum member = extractMemberNames!T();
	string tableName = getTableNameOfAggregation!T();
	string[] keys = extractPrimaryKeyNames!T();
	string ret = "string createTableStmt = \"CREATE TABLE " ~ tableName ~ "(\";\n";
	foreach(it; member) {
		ret ~= sqliteTypeNameFromType!(T)(it);
	}
	if(!keys.empty) {
		ret ~= "\tcreateTableStmt = createTableStmt[0 .. $-1] ~ \", " 
			~ "PRIMARY KEY(";
		foreach(key; keys) {
			ret ~= key ~ ",";
		}
		ret = ret[0 .. $-1] ~ "))\"";
	} else {
		ret ~= "\tcreateTableStmt = createTableStmt[0 .. $-1] ~ \")\"";
	}
	if(getTableWithoutRowId!T()) {
		ret ~= " ~ \" WITHOUT ROWID\"";
	}
	return ret;
}

//pragma(msg, genCreateTableStatement!Data());

// Sqlite object

struct Sqlite {
private:
	private string dbName;
	sqlite3 *db;
	sqlite3_stmt *stmtTmp;
	bool dbOpen;
	int inTrans;
public:

	struct UniRange(T) {
	private:
		T currentItem;
		int sqlRsltCode;
		sqlite3_stmt* stmt;
		bool done;

	public:
		this(sqlite3_stmt* s, int rsltCode) {
			sqlRsltCode = rsltCode;
			stmt = s;
			if(sqlRsltCode == SQLITE_OK) {
				sqlRsltCode = sqlite3_step(stmt);
				if(sqlRsltCode == SQLITE_ROW) {
					this.currentItem = buildItem!T();
				} else {
					//writeln(sqlRsltCode);
					done = true;
					sqlite3_finalize(stmt);
				}
			} else {
				//writeln(sqlRsltCode);
				done = true;
				sqlite3_finalize(stmt);
			}
		}
	
		@property bool empty() const pure nothrow {
			return done;
		}

		@property T front() {
			return this.currentItem;
		}

		@property void popFront() { 
			sqlRsltCode = sqlite3_step(stmt);
			if(sqlRsltCode == SQLITE_ROW) {
				this.currentItem = buildItem!T();
			} else {
				done = true;
				sqlite3_finalize(stmt);
			}
		}

		mixin(genRangeItemFill!T());
	}

	static Sqlite opCall(string dbn, int openType = SQLITE_OPEN_READWRITE) { 
		Sqlite ret;
		ret.dbName = dbn;
		int errCode = sqlite3_open_v2(toStringz(ret.dbName), &ret.db, 
			openType, null
		);
		if(errCode != SQLITE_OK) {
			auto errmsg = sqlite3_errmsg(ret.db);
			auto err = new Exception("Can't open database " 
				~ ret.dbName ~ " because of \"" ~ to!string(errmsg) ~ "\""
			);
			throw err;
		}
		ret.dbOpen = true;
		return ret;
	}

	~this() {
		this.close();
	}

	void close() {
		if(dbOpen) {
			sqlite3_close(db);
		}
	}

	// Select

	UniRange!(T) select(T)(string where = "") {
		string tn = getTableNameOfAggregation!T();
		string s = "SELECT * FROM " ~ tn ~ 
			(where.length == 0 ? "" : " WHERE " ~
			 checkForDeleteAndInsertDropExpr(where)) ~ ";";
		//writeln(s);
		return makeIterator!(T)(s);
	}

	UniRange!(T) makeIterator(T)(string stmtStr) {
		sqlite3_stmt* stmt2;
		StaticToStringZ!4096 s;
 		int rsltCode = sqlite3_prepare(db, s.toStringZ(stmtStr),
			to!int(stmtStr.length), &stmt2, null
		);
		if(rsltCode == SQLITE_ERROR) {
			throw new Exception("Select Statement:\"" ~
					stmtStr ~ "\" failed with error:\"" ~
					to!string(sqlite3_errmsg(db)) ~ "\"");
		} else if(rsltCode == SQLITE_OK) {
			return UniRange!(T)(stmt2, rsltCode);
		} else {
			assert(false, to!string(sqlite3_errmsg(db)));
		}
	}

	// Insert

	void insert(T)(ref T t) {
		sqlite3_stmt* stmt;
		int doStuff = this.inTrans;
		if(this.inTrans > 0) {
			this.inTrans++;
		}

		if(this.inTrans > 2) {
			t.uniformAccessInsert(this.db, stmtTmp, doStuff);
		} else {
			t.uniformAccessInsert(this.db, stmt, doStuff);
		}

		if(doStuff == 1) {
			assert(stmt !is null);
			stmtTmp = stmt;
			assert(stmtTmp !is null);
		} else {
			sqlite3_reset(stmt);
			assert(stmt is null);
		}
	}

	// Remove
	void remove(T)(ref T t) {
		sqlite3_stmt* stmt;
		t.uniformAccessRemove(this.db, stmt);
		sqlite3_finalize(stmt);
	}

	// Update
	void update(T)(ref T t) {
		sqlite3_stmt* stmt;
		t.uniformAccessUpdate(this.db, stmt);
		sqlite3_finalize(stmt);
	}

	// Create
	void createTable(T)() {
		sqlite3_stmt* stmt;
		T.uniformAccessCreateTable(this.db, stmt);
		sqlite3_finalize(stmt);
	}

	// Helper

	void step(sqlite3_stmt* stmt) {
		if(sqlite3_step(stmt) != SQLITE_DONE) {
			scope(exit) sqlite3_finalize(stmt);
			throw new Exception(to!string(sqlite3_errmsg(db)));
		}
	}

	void beginTransaction() {
		char* errorMessage;
		if(sqlite3_exec(db, "BEGIN TRANSACTION", null, null, &errorMessage) 
				!= SQLITE_OK) {
			scope(exit) sqlite3_free(errorMessage);
			throw new Exception("Begin Transaction failed with error " ~ 
				to!string(errorMessage));
		}
		this.inTrans = 1;
	}

	void endTransaction() {
		char* errorMessage;
		if(sqlite3_exec(db, "COMMIT TRANSACTION", null, null, &errorMessage)
				!= SQLITE_OK) {
			scope(exit) sqlite3_free(errorMessage);
			throw new Exception("Begin Transaction failed with error " ~ 
				to!string(errorMessage));
		}
		sqlite3_finalize(this.stmtTmp);
		this.inTrans = 0;
	}

	static string checkForDeleteAndInsertDropExpr(string str) {
		if(std.string.indexOf(str, "drop", CaseSensitive.no) != -1 ||
				std.string.indexOf(str, "insert", CaseSensitive.no) != -1 ||
				std.string.indexOf(str, "remove", CaseSensitive.no) != -1) {
			throw new Error("Stmt must not contain non const operation");
		}
		return str;
	}
}

string genUniformAccess(T)() {
	string ret = 
		"import etc.c.sqlite3;\n"
		~ "import std.traits;\n"
		~ "void uniformAccessInsert(sqlite3* db, ref sqlite3_stmt* stmt, const int once) {\n"
		~ "\tauto elemCount = " ~ genInsertElemCount!T() ~ ";\n"
		~ "\tenum insertStmt = \""~ genInsertStatement!T() ~ "\";\n"
		~ "\tStaticToStringZ!(insertStmt.length+1) toCstr;\n"
		~ "\tif(once <= 1) {\n"
		~ "\t\tStaticToStringZ!(2048) toCstrPara;\n"
		~ "\tint errCode = sqlite3_prepare_v2(db, toCstr.toStringZ(insertStmt)"
		//~ "\t\tint errCode = sqlite3_prepare_v2(db, toStringz(insertStmt)"
		~ ",\n\t\t\tto!int(insertStmt.length), &stmt, null\n\t\t);\n"
		~ "\t\tif(errCode != SQLITE_OK) {\n"
		~ "\t\t	scope(exit) sqlite3_finalize(stmt);\n"
		~ "\t\t	throw new Exception(insertStmt ~ \" FAILED \" ~\n"
		~ "\t\t		to!string(sqlite3_errmsg(db))\n"
		~ "\t\t	);\n"
		~ "\t\t}\n"
		~ "\t}\n"
		~ "\tassert(stmt !is null, \"stmt \" ~ to!string(once));\n"
		~ "\tassert(db !is null, \"db\");\n"

		~ "\tint i = 1;	\n"
		~ genInsertAddParameterMixinString!T() ~ "\n"
		~ "\tassert(i == elemCount);\n"
		~ "\tif(sqlite3_step(stmt) != SQLITE_DONE) {\n"
		~ "\t	scope(exit) sqlite3_finalize(stmt);\n"
		~ "\t	throw new Exception(to!string(sqlite3_errmsg(db)) ~ \" \" ~\n"
		~ "\t		insertStmt ~ \" \" ~ to!string(this)\n"
		~ "\t	);\n"
		~ "\t}\n"
		~ "\tif(once == 0) {\n"
		~ "\t\tsqlite3_finalize(stmt);\n"
		~ "\t}\n\n"
		~ "}\n\n"

		~ "void uniformAccessRemove(sqlite3* db, sqlite3_stmt* stmt) {\n"
		~ "\tenum removeStmt = \"" ~ genRemoveStatement!T() ~ "\";\n"
		~ "\tStaticToStringZ!(removeStmt.length+1) toCstr;\n"
		~ "\tStaticToStringZ!(2048) toCstrPara;\n"
		~ "\tint errCode = sqlite3_prepare_v2(db, toCstr.toStringZ(removeStmt)"
		~ ",\n\tto!int(removeStmt.length), &stmt, null\n\t);\n"
		~ "\tif(errCode != SQLITE_OK) {\n"
		~ "\t	scope(exit) sqlite3_finalize(stmt);\n"
		~ "\t	throw new Exception(removeStmt ~ \" FAILED \" ~\n"
		~ "\t		to!string(sqlite3_errmsg(db))\n"
		~ "\t	);\n"
		~ "\t}\n"
		~ "\tint i = 1;\n"
		~ genRemoveParameterMixinString!T() ~ "\n"

		~ "\tif(sqlite3_step(stmt) != SQLITE_DONE) {\n"
		~ "\t	scope(exit) sqlite3_finalize(stmt);\n"
		~ "\t	throw new Exception(to!string(sqlite3_errmsg(db)) ~ \" \" ~\n"
		~ "\t		removeStmt ~ \" \" ~ to!string(this)\n"
		~ "\t	);\n"
		~ "\t}\n"
		~ "\tsqlite3_finalize(stmt);\n"
		~ "}\n\n"

		~ "void uniformAccessUpdate(sqlite3* db, sqlite3_stmt* stmt) {\n"
		~ "\tenum updateStmt = \"" ~ genUpdateStatement!T() ~ "\";\n"
		~ "\tStaticToStringZ!(updateStmt.length+1) toCstr;\n"
		~ "\tStaticToStringZ!(2048) toCstrPara;\n"
		~ "\tint errCode = sqlite3_prepare_v2(db, toCstr.toStringZ(updateStmt)"
		~ ",\n\tto!int(updateStmt.length), &stmt, null\n\t);\n"
		~ "\tif(errCode != SQLITE_OK) {\n"
		~ "\t	scope(exit) sqlite3_finalize(stmt);\n"
		~ "\t	throw new Exception(updateStmt ~ \" FAILED \" ~\n"
		~ "\t		to!string(sqlite3_errmsg(db))\n"
		~ "\t	);\n"
		~ "\t}\n"
		~ "\tint i = 1;\n"
		~ genUpdateParameterMixinString!T() ~ "\n"
		

		~ "\tif(sqlite3_step(stmt) != SQLITE_DONE) {\n"
		~ "\t	scope(exit) sqlite3_finalize(stmt);\n"
		~ "\t	throw new Exception(to!string(sqlite3_errmsg(db)) ~ \" \" ~\n"
		~ "\t		updateStmt ~ \" \" ~ to!string(this)\n"
		~ "\t	);\n"
		~ "\t}\n"
		~ "\tsqlite3_finalize(stmt);\n"
		~ "}\n\n"

		~ "static void uniformAccessCreateTable(sqlite3* db, "
		~ "sqlite3_stmt* stmt) {\n" ~ "\t" 
		~ genCreateTableStatement!T() ~ ";\n"
		~ "\tint errCode = sqlite3_prepare_v2(db, toStringz(createTableStmt),\n"
		~ "\t	to!int(createTableStmt.length), &stmt, null\n"
		~ "\t);\n"
		~ "\tif(errCode != SQLITE_OK) {\n"
		~ "\t	scope(exit) sqlite3_finalize(stmt);\n"
		~ "\t	throw new Exception(createTableStmt ~ \" FAILED \" ~\n"
		~ "\t		to!string(sqlite3_errmsg(db))\n"
		~ "\t	);\n"
		~ "\t}\n"
		~ "\tif(sqlite3_step(stmt) != SQLITE_DONE) {\n"
		~ "\t	scope(exit) sqlite3_finalize(stmt);\n"
		~ "\t	throw new Exception(to!string(sqlite3_errmsg(db)) ~ \" \" ~\n"
		~ "\t		createTableStmt\n"
		~ "\t	);\n"
		~ "\t}\n"
		~ "\tsqlite3_finalize(stmt);\n"
		~ "}\n\n";

	return ret;
}
