#define _GNU_SOURCE
#include <stdio.h>
#include <assert.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/time.h>
#include <time.h>
#include <sqlite3.h> 
#include <stddef.h>
#include <sys/sysinfo.h>

uint32_t stampstart() {
	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;
	uint32_t         start;
 
	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);
 
	//printf("TIMESTAMP-START\t  %d:%02d:%02d:%d (~%d ms)\n", tm->tm_hour,
	//       tm->tm_min, tm->tm_sec, tv.tv_usec,
	//       tm->tm_hour * 3600 * 1000 + tm->tm_min * 60 * 1000 +
	//       tm->tm_sec * 1000 + tv.tv_usec / 1000);
 
	start = tm->tm_hour * 3600 * 1000 + tm->tm_min * 60 * 1000 +
		tm->tm_sec * 1000 + tv.tv_usec / 1000;
 
	return (start);
 
}
 
uint32_t stampstop(uint32_t start) {
	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;
	uint32_t         stop;
 
	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);
 
	stop = tm->tm_hour * 3600 * 1000 + tm->tm_min * 60 * 1000 +
		tm->tm_sec * 1000 + tv.tv_usec / 1000;
 
	//printf("TIMESTAMP-END\t  %d:%02d:%02d:%d (~%d ms) \n", tm->tm_hour,
	//       tm->tm_min, tm->tm_sec, tv.tv_usec,
	//       tm->tm_hour * 3600 * 1000 + tm->tm_min * 60 * 1000 +
	//       tm->tm_sec * 1000 + tv.tv_usec / 1000);
 
	//printf("ELAPSED\t  %d ms\n", stop - start);
 
	return (stop-start);
 
}

long long timespecDiff(struct timeval* start, struct timeval* end)
{
    long long t1, t2;
    t1 = start->tv_sec * 1000 + start->tv_usec;
    t2 = end->tv_sec * 1000 + end->tv_usec;
    return t1 - t2;
}

void dummy(void* d) {}

typedef struct Five_t {
	char* firstname;
	char* lastname;
	char* company;
	char* road;
	char* city;
	char* state;
	char* stateaka;
	int zip;
	char* telefon;
	char* fax;
	char* email;
	char* web;
} Five;

int main() {
	Five arr[50000];
	int idx = 0;
	FILE * fp;
	char * line = NULL;
	size_t len = 0;
	size_t read;
	int begin = stampstart();
	fp = fopen("50000.csv", "r");
	if (fp == NULL) {
		exit(EXIT_FAILURE);
	}
	char* buf = (char*)malloc(sizeof(char)*128);
	while((read = getline(&line, &len, fp)) != -1) {
		Five five;
		five.firstname = (char*)malloc(sizeof(char)*128);
		five.lastname = (char*)malloc(sizeof(char)*128);
		five.company = (char*)malloc(sizeof(char)*128);
		five.road = (char*)malloc(sizeof(char)*128);
		five.city = (char*)malloc(sizeof(char)*128);
		five.state = (char*)malloc(sizeof(char)*128);
		five.stateaka = (char*)malloc(sizeof(char)*128);
		five.telefon = (char*)malloc(sizeof(char)*128);
		five.fax = (char*)malloc(sizeof(char)*128);
		five.email = (char*)malloc(sizeof(char)*128);
		five.web = (char*)malloc(sizeof(char)*128);
		int r = sscanf(line, "%[^,],%[^,],%[^,],%[^,],%[^,],%[^,],%[^,],\"%[^,],%[^,],%[^,],%[^,],%[^,]\n",
			five.firstname, five.lastname, five.company, five.road, five.city, five.state, five.stateaka, 
			buf, five.telefon, five.fax, five.email, five.web);
		five.zip = atoi(buf);
		five.firstname = five.firstname+1;
		five.firstname[strlen(five.firstname)-1] = '\0';
		five.lastname = five.lastname+1;
		five.lastname[strlen(five.lastname)-1] = '\0';
		five.company = five.company+1;
		five.company[strlen(five.company)-1] = '\0';
		five.road = five.road+1;
		five.road[strlen(five.road)-1] = '\0';
		five.city = five.city+1;
		five.city[strlen(five.city)-1] = '\0';
		five.state = five.state+1;
		five.state[strlen(five.state)-1] = '\0';
		five.stateaka = five.stateaka+1;
		five.stateaka[strlen(five.stateaka)-1] = '\0';
		five.telefon = five.telefon+1;
		five.telefon[strlen(five.telefon)-1] = '\0';
		five.fax = five.fax+1;
		five.fax[strlen(five.fax)-1] = '\0';
		five.email = five.email+1;
		five.email[strlen(five.email)-1] = '\0';
		five.web = five.web+1;
		five.web[strlen(five.web)-1] = '\0';
		if(r != 12) {
			printf("%d %s\n", r, line);
			return 1;
		}

		arr[idx++] = five;
	}
	free(buf);
	if (line) {
		free(line);
	}
	printf("csv time %d\n", stampstop(begin));
	begin = stampstart();

	sqlite3 *db;
	int ret = sqlite3_open("testtable.db",&db);
	assert(ret == SQLITE_OK);
	//gettimeofday(&start, NULL);

	ret = sqlite3_exec(db, "BEGIN TRANSACTION;", NULL, NULL, NULL);
	assert(ret == SQLITE_OK);

	const char* istmt  = "INSERT INTO Person(Firstname, Lastname, Company, Address, County, City, State, Zip, PhoneWork, PhonePrivat, Mail, Www) Values(?,?,?,?,?,?,?,?,?,?,?,?);";
	const char* istmt2  = "INSERT INTO Person(Firstname, Lastname, Company, Address, County, City, State, Zip, PhoneWork, PhonePrivat, Mail, Www) Values(%s,%s,%s,%s,%s,%s,%s,%d,%s,%s,%s,%s);\n";
	sqlite3_stmt* stmt;
	const char* ozTest;
	ret = sqlite3_prepare_v2(db, istmt, strlen(istmt), &stmt, &ozTest);
	assert(ret == SQLITE_OK);
	for(int i = 0; i < idx; ++i) {
		int j = 1;
		/*printf(istmt2, arr[i].firstname, arr[i].lastname, 
			arr[i].company, arr[i].road, arr[i].city, arr[i].state, arr[i].stateaka, arr[i].zip, 
			arr[i].telefon, arr[i].fax, arr[i].email, arr[i].web
		);*/
		sqlite3_bind_text(stmt, j++, arr[i].firstname, strlen(arr[i].firstname), NULL);
		sqlite3_bind_text(stmt, j++, arr[i].lastname, strlen(arr[i].lastname), NULL);
		sqlite3_bind_text(stmt, j++, arr[i].company, strlen(arr[i].company), NULL);
		sqlite3_bind_text(stmt, j++, arr[i].road, strlen(arr[i].road), NULL);
		sqlite3_bind_text(stmt, j++, arr[i].city, strlen(arr[i].city), NULL);
		sqlite3_bind_text(stmt, j++, arr[i].state, strlen(arr[i].state), NULL);
		sqlite3_bind_text(stmt, j++, arr[i].stateaka, strlen(arr[i].stateaka), NULL);
		sqlite3_bind_int(stmt, j++, arr[i].zip);
		sqlite3_bind_text(stmt, j++, arr[i].telefon, strlen(arr[i].telefon), NULL);
		sqlite3_bind_text(stmt, j++, arr[i].fax, strlen(arr[i].fax), NULL);
		sqlite3_bind_text(stmt, j++, arr[i].email, strlen(arr[i].email), NULL);
		sqlite3_bind_text(stmt, j++, arr[i].web, strlen(arr[i].web), NULL);
		assert(j == 13);
		ret = sqlite3_step(stmt);
		if(ret != SQLITE_DONE) {
			printf("%d \"%s\"\n", ret, sqlite3_errmsg(db));
			printf("%s %s %s %s %s %s %s %d %s %s %s %s\n", arr[i].firstname, arr[i].lastname, 
				arr[i].company, arr[i].road, arr[i].city, arr[i].state, arr[i].stateaka, arr[i].zip, 
				arr[i].telefon, arr[i].fax, arr[i].email, arr[i].web
			);
			return 1;
		}
		sqlite3_reset(stmt);
	}
	sqlite3_exec(db, "END TRANSACTION;", NULL, NULL, NULL);
	printf("%d\n", stampstop(begin));
	sqlite3_close(db);
	return 0;
}
