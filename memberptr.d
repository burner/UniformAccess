struct Foo {
	int a;
}

void bar(T)() {

}

void main() {
	bar!(&Foo.a)();
}
