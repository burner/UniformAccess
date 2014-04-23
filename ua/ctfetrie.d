module ua.ctfetrie;

import std.array;
import std.stdio;
import std.typecons;

import ua.util.eightylineformat;

alias Tuple!(string, "id", string, "action") TrieEntry;

string buildTrie(TrieEntry[] names) pure @safe {
	auto app = appender!string();
	foreach(idx, it; names) {
		buildTrieImpl(app, 1, it, idx == 0);
	}

	return app.data();
}

void indent(ref Appender!string app, size_t indent) pure @safe nothrow {
	for(size_t i = 0; i < indent; ++i) {
		app.put("    ");
	}
}

void buildTrieImpl(ref Appender!string app, size_t deapth, TrieEntry name,
		bool first) pure @safe {
	assert(!name.id.empty);

	if(first) {
		app.indent(deapth);
		app.formattedWrite("if(input.empty) break;\n");
		app.formattedWrite("switch(input.front) {\n");
	}

	app.indent(deapth);
	app.formattedWrite("case %c: { %s break;}\n", name.id.front, name.action);

	name.id.popFront();
	if(!name.id.empty) {
		buildTrieImpl(app, deapth+1, name, false);
	}
	app.put('\n');
}

unittest {
	enum trie = buildTrie([TrieEntry("foo", "bar();")]);
	//writeln(trie);
}
