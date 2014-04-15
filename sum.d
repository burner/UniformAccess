import std.stdio;
import std.conv;

void main() {
	auto names = ["dmdgen", "gdcgen", "dmdhand", "gdchand", "gcccpp",
		 "clangcpp", "gccc", "clangc"];

	int[] sum = new int[names.length];
	int[] lines = new int[names.length];

	foreach(idx, it; names) {
		auto f = File(it);
		foreach(jt; f.byLine) {
			sum[idx] += to!int(jt);
			lines[idx]++;
		}
	}

	foreach(idx, it; names) {
		writefln("%10s %6d %7.2f", it, sum[idx], to!double(sum[idx]) /
			to!double(lines[idx])
		);
	}
}
