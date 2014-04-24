import std.datetime;


struct Person {
	@UA(UAOptions.General.PrimaryKey) string lastname;
	@UA(UAOptions.General.PrimaryKey) string firstname;
	uint age;
	DateTime birthday;

	float height_

	@UA("tall") @property float height() pure const nothrow @safe {
		enforce(height_ >= 0.0);
		return height_;
	}

	@UA("tall") @property void height(float h) pure const nothrow @safe {
		enforce(h >= 0.0);
		return height_ = h;
	}

	@NoUA double someDataNotToAddToTheDB;

}

void someFunc() { // runtime statement building
	auto db = openDB!Mysql("ip", "port"); // Ref Counted 

	int var = foobar();
	auto w1 = where!(Person, "age", ">=")(foobar);
	auto w1 = where!(Person, "lastname", "!=")("Robert");

	auto g1 = group!Person("height");

	auto stmt = db.select!Person(w1, w2, g1);
	// or
	auto stmt = db.select!Person();
	stmt.add(w1);
	stmt.add(w2);
	stmt.add(g1);

	foreach(it; stmt) {
		// use the instance of Person
	}
}

void someOtherFunc() { // compile statement building
	auto db = openDB!Mysql("ip", "port"); // Ref Counted 

}
