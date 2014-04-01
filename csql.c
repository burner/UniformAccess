#define _GNU_SOURCE
#include <stdio.h>
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
	struct timeval start, end;
	gettimeofday(&start, NULL);

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
	printf("%d\n", stampstop(begin));
	begin = stampstart();

	sqlite3 *db;
	sqlite3_open("testtable.db",&db);
	//gettimeofday(&start, NULL);

	sqlite3_exec(db, "BEGIN TRANSACTION;", NULL, NULL, NULL);
	const char* istmt  = "INSERT INTO Person(Firstname, Lastname, Company, Address, County, City, State, Zip, PhoneWork, PhonePrivat, Mail, Www) Values(?,?,?,?,?,?,?,?,?,?,?,?);";
	sqlite3_stmt* stmt;
	sqlite3_prepare_v2(db, istmt, strlen(istmt), &stmt, NULL);
	for(int i = 0; i < idx; ++i) {
		int j = 1;
		sqlite3_bind_text(stmt, j++, arr[i].firstname, strlen(arr[i].firstname), &dummy);
		sqlite3_bind_text(stmt, j++, arr[i].lastname, strlen(arr[i].lastname), &dummy);
		sqlite3_bind_text(stmt, j++, arr[i].company, strlen(arr[i].company), &dummy);
		sqlite3_bind_text(stmt, j++, arr[i].road, strlen(arr[i].road), &dummy);
		sqlite3_bind_text(stmt, j++, arr[i].city, strlen(arr[i].city), &dummy);
		sqlite3_bind_text(stmt, j++, arr[i].state, strlen(arr[i].state), &dummy);
		sqlite3_bind_text(stmt, j++, arr[i].stateaka, strlen(arr[i].stateaka), &dummy);
		sqlite3_bind_int(stmt, j++, arr[i].zip);
		sqlite3_bind_text(stmt, j++, arr[i].telefon, strlen(arr[i].telefon), &dummy);
		sqlite3_bind_text(stmt, j++, arr[i].fax, strlen(arr[i].fax), &dummy);
		sqlite3_bind_text(stmt, j++, arr[i].email, strlen(arr[i].email), &dummy);
		sqlite3_bind_text(stmt, j++, arr[i].web, strlen(arr[i].web), &dummy);
		sqlite3_step(stmt);
	}
	sqlite3_exec(db, "END TRANSACTION;", NULL, NULL, NULL);
	printf("%d\n", stampstop(begin));
	sqlite3_close(db);
	return 0;
}
