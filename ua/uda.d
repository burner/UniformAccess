module ua.uda;

import std.conv;

import ua.options;
import ua.util.type;

/** By default all data member of an struct or class will be considered when
used in UniformAccess, the UA attribute makes the usage more verbose and
allows to provide additional options.
*/
struct UA {
	static UA opCall(T...)(T args) {
		UA ret;
		return ret;
	}

	string rename;
	bool isPrimaryKey;
	bool isNotNull;
}

/** Whatever has an NoUA attribute will not be considered in UniformAccess
*/
enum {
	NoUA
}

version(unittest) {
	struct Foo {
		@UA int a;
		@NoUA float b;
		@UA("foo") string c;

		@UA(PrimaryKey) @property int fun() { return fun_; }
		@UA(PrimaryKey) @property void fun(int f) { fun_ = f; }

		private int fun_;
	}
}

bool isUA(T, string member)() {
	string ua = getNameOf!T;
	string noUA = to!string(NoUA);

	foreach(it; __traits(getAttributes, __traits(getMember, T, member))) {
		if(is(UA == it)) {
			return true;
		} else if(is(noUA == it)) {
			return false;
		}
	}

	return true;
}

unittest {
	static assert(isUA!(Foo,"a"));
}
