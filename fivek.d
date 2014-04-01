module five;
import uniformaccess;

@("UA") struct Five {
	@("UA", "Primary_Key") string firstname;
	@("UA", "Primary_Key") string lastname;
	@("UA", "Primary_Key") string company;
	@("UA") string road;
	@("UA") string city;
	@("UA") string state;
	@("UA") string stateaka;
	@("UA") int zip;
	@("UA") string telefon;
	@("UA") string fax;
	@("UA") string email;
	@("UA") string web;

	//pragma(msg, genUniformAccess!Five);
	mixin(genUniformAccess!Five);
}
