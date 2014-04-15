UniformAccess
=============

Template magic in D to access Sqlite3 Databases

dmd *.d -L-lsqlite3 -L-ldl -unittest


Testing
-------

The make target test requires that the sweet.hpp header are located at the
same level as this folder. It also requires sqlite3, clang, gcc, gdc and dmd to be
installed.
