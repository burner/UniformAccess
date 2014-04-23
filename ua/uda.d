module ua.uda;

import std.traits;

import ua.options;

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

/* whatever has an NoUA attribute will not be considered in UniformAccess
*/
enum NoUA;

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


