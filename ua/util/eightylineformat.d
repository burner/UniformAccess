module ua.util.eightylineformat;

import std.format : formattedWrite;
import std.traits;

void format80(OutputRange, T...)(ref OutputRange o, string form, T args) {
	o.formattedWrite(form, args);
}

string format80(T...)(string form, T args) {
	import std.array : appender, Appender;
	auto app = appender!string();
	format80(app, form, args);
	return app.data();
}

unittest {
	enum s = format80("%s", "hello");
	static assert(s == "hello", s);
}
