module five;
import uniformaccess;

struct Five {
	@("UA", "Primary_Key") string firstname;
	@("UA", "Primary_Key") string lastname;
	@("UA", "Primary_Key") string company;
	string road;
	string city;
	string state;
	string stateaka;
	int zip;
	string telefon;
	string fax;
	string email;
	string web;

	//pragma(msg, genUniformAccess!Five);
	mixin(genUniformAccess!Five);
}
