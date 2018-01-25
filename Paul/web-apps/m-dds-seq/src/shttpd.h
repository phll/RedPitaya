#ifndef SRC_SHTTPD_H_
#define SRC_SHTTPD_H_

#include <sys/types.h>

//see shttpd.c for more info

//#define MAP_SIZE 4096UL
#define MAP_SIZE 65536UL
#define MAP_MASK (MAP_SIZE - 1)


void *accept_request(void*);
void error_die(const char *);
int get_line(int, char *, int);
void headers(int);
void bad_request(int);
int startup(u_short *);
int handle_request(char*, int, char**);
void *mainLoop(void*);
int init();
void shutdownServer();
int write_value(unsigned long, unsigned long, char**);
void sendError(char*, const char*, void*);
void response(char*, const char*, void*);
char * concat(char*,char*);


#endif /* SRC_SHTTPD_H_ */
