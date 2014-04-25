/** This module is about creating where statements for various sql version.

Where statements can be created at compile time, at runtime and partially at
compile time.
*/
module ua.where;

import std.stdio;
import std.traits;
import std.string;

struct Where(T) {
	public enum Op {
		EQ,
		LE,
		GE,
		NEQ
	}

	string t = getNameOf!T;
	string member;
	Op op;
	string value;
}

Where!T where(T, string member, Where!T.Op op, long value)() {
	Where!T ret;
	ret.member = member;
	ret.op = op;
	ret.value = to!string(value);
	return ret;
}

unittest {
	struct Foo {
		int a;
	}

	auto w = where!(Foo, "a", Op.EQ, 10);
	writeln(__LINE__);
}
