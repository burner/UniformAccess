module ua.util.type;

import std.traits;
import std.string;

string getNameOf(T)() pure @safe nothrow {
	auto fully = fullyQualifiedName!T;
	ptrdiff_t point;
	try {
   		point = fully.lastIndexOf('.');
	} catch(Exception e) {
		assert(false);
	}
	if(point != -1 && point+1 < fully.length) {
		return fully[point+1 .. $];
	} else {
		return fully;
	}
}

version(unittest) {
	struct Foo {
	}
}

unittest {
	static assert(getNameOf!Foo == "Foo", getNameOf!Foo);
}

