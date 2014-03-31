import uniformaccess;
import std.logger;
import std.range;

@("UA", "SomeOtherTableName") struct SomeStruct {
	@("NotUA") float someother;
	@("UA") float interval;
	@("UA", "foo") int bar;
	@("UA") int zzz;
	@("UA", "wingdings", "Primary_Key") int key;

	//pragma(msg, genUniformAccess!SomeStruct);
	mixin(genUniformAccess!SomeStruct);
}

unittest {
	/*auto db = Sqlite("foobar.sqlite");
	SomeStruct d;
	db.createTable!SomeStruct();
	d.someother = 1337.0;
	d.interval = 12;
	d.bar = 34;
	d.zzz = 7331;
	d.key = 128;
	db.insert(d);
	log();

	auto sel = db.select!SomeStruct();
	foreach(SomeStruct it; sel) {
		logF("%f %d %d %d", it.interval, it.bar, it.zzz, it.key);
	}*/
}

@("UA", "stocks") struct Entry {
	@("UA", "Primary_Key", "Symbol") string symbol;
	@("UA", "Primary_Key", "Date") int date;
	@("UA", "Open") real open;
	@("UA", "Close") real close;
	@("UA", "High") real high;
	@("UA", "Low") real low;
	@("UA", "Volume") int volume;

	void fun() {
	}
	mixin(genUniformAccess!Entry);
}

void main() {
}
