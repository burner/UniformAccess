import uniformaccess;
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
