struct UA {
	string rename;
	bool primaryKey;

	static UA opCall(T...)(T args) {
		UA ret;
		return ret;
	}
}

struct UAOptions {
	enum General {
		PrimaryKey
	}

	enum MySQL {
		SomeMySQLOption
	}

	enum Where {
		EQ,
		LE,
		GE,
		NEQ
	}
}

void main() {
	@UA("foo", UAOptions.General.PrimaryKey) int a;
}
