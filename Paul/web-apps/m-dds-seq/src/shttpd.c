#include <stdio.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <ctype.h>
#include <strings.h>
#include <string.h>
#include <sys/stat.h>
#include <pthread.h>
#include <sys/wait.h>
#include <stdlib.h>
#include <errno.h>
#include <signal.h>
#include <fcntl.h>
#include "shttpd.h"

/****
** author Paul Hill
** based on jdbhttpd
** contains init function to start the server, which then runs in a mainLoop until it is shutdown
** For every incoming connection a new thread is created and the connection is handled in accept_request (http stuff, basic validation) and handle_request (handle actual request(payload))
****/

#define SERVER_STRING "Server: shttpd\r\n"

//max payload length
#define MAX_CONTENT_LENGTH 200000

#define FILES_DIR "/var/opt/m-dds-seq"
#define SETTINGS_FILE "/var/opt/m-dds-seq/settings_"			//final settings_file name will be settings_+date
#define SETTINGS_META_FILE "/var/opt/m-dds-seq/settings_meta"   //date of recent file

int server_running = 0;
int server_sock = -1;
u_short port = 0;


/*handle a valid http request which passes checks in accept_request
* buf   incoming data
* size  length of buf
* out   error message or result string
* return -1 if error, 0 otherwise
*/
int handle_request(char* buf, int size, char** out){
  int length = (size>1024)?1024:size;
  char sub[1024];
  int i=1, j=0;
  unsigned long addr=0;
  unsigned long val=0;//long is 32bit on RedPitaya!
  char *c;

  FILE *f, *m;
	char *file_name = NULL, *content = NULL;
	time_t t;
  long fsize;

  switch(buf[0]){
    case '0'://write fpga register
      while(buf[i]!=';' && i<length-1 ){
        sub[i-1] = buf[i];
        ++i;
      }
      sub[i-1]='\0';
      addr = strtoul(sub, &c, 10);
      ++i;
      while(buf[i]!=';' && i<length-1 ){
        sub[j] = buf[i];
        ++i;
        ++j;
      }
      sub[j]='\0';
      val = strtoul(sub, &c, 10); 
      return write_value(addr, val, out);
      break;
    case '1'://save sequences
        //save current time in meta file
      t = time(0);
      m = fopen(SETTINGS_META_FILE, "w");
      if(m==NULL){
        *out = (char*)"FAILED TO OPEN META FILE";
        return -1;
      }
      if(fprintf(m, "%s",ctime(&t))<0){
        *out = (char*)"IO ERROR";
        fclose(m);
        return -1;
      }
      fclose(m);

      //generate file_name : settings_+date
      file_name = concat((char*)SETTINGS_FILE, ctime(&t));
      if(file_name==NULL){
        *out = (char*)"OUT OF MEMORY";
        return -1;
      }

      //save settings
      f = fopen(file_name, "w");
      free(file_name);
      if(f==NULL){
        *out = (char*)"FAILED TO CREATE SETTINGS FILE";
        return -1;
      }

      for(i=0;i<size-1;++i){
        buf[i]=buf[i+1];
      }
      if(fwrite(buf, sizeof(char), size-1, f)<0){
        *out = (char*)"IO ERROR";
        fclose(f);
        return -1;
      }
      fclose(f);
      break;
    case '2'://load sequences
      //get date of recent file
      m = fopen(SETTINGS_META_FILE, "r");
      if(m==NULL){
        *out = (char*)"FAILED TO OPEN META FILE";
        return -1;
      }
      char date[100];
      if(fgets(date, 100, m)==NULL ){
        *out = (char*)"IO ERROR";
        fclose(m);
        return -1;
      }
      fclose(m);

      //generate filenames : settings_+date
      file_name = concat((char*)SETTINGS_FILE, date);
      if(file_name==NULL){
        *out = (char*)"OUT OF MEMORY";
        return -1;
      }

      //load settings
      f = fopen(file_name, "r");
      free(file_name);
      if(f==NULL){
        *out = (char*)"FAILED TO OPEN SETTINGS FILE";
        return -1;
      }

      fseek(f,0,SEEK_END);
      fsize = ftell(f);
      fseek(f,0, SEEK_SET);

      content = (char*)malloc(fsize+1);
      if(content==NULL){
        *out = (char*)"OUT OF MEMORY";
        fclose(f);
        return -1;
      }

      fread(content, fsize, 1, f);
      if(fread(content, fsize, 1, f)<0){
        *out = (char*)"IO ERROR";
        fclose(f);
        free(content);
        return -1;
      }
      fclose(f);
      *out = content;
      break;
    case 3: //idle
      return 0;
    default:
      break;
  }
  return 0;
}

//process an incoming tcp connection
void * accept_request(void* client){
 char buf[1024];
 int content_length = -1;

 //read headers and check for neccessary data. Is this a valid request?
 int numchars = get_line(*((int*)client), buf, sizeof(buf));
 while ((numchars > 0) && strcmp("\n", buf)){//read headers
   buf[15] = '\0';
   if (strcasecmp(buf, "Content-Length:") == 0)
    content_length = atoi(&(buf[16]));
   numchars = get_line(*((int*)client), buf, sizeof(buf));
 }
  if (content_length == -1) {
   bad_request(*((int*)client));
   close(*((int*)client));
   free(client);
   return NULL;
  }

  //"valid" http request
  headers(*((int*)client));

  //check if bad arguments
  if(content_length<1){
    sendError(buf, "WRONG OR NO CONTENT", client);
    free(client);
    return NULL;
  }else if(content_length>MAX_CONTENT_LENGTH){
    sendError(buf, "TOO MUCH CONTENT", client);
    free(client);
    return NULL;
  }

  //allocate space for payload data
  char * data = NULL;
  data = (char*)malloc(content_length*sizeof(char));
  if(data==NULL){
    sendError(buf, "INTERNAL ERROR", client);
    free(client);
    return NULL;
  }

  //read in payload
  int i=0;
  char c;
  for(i=0;i<content_length;++i){
    if(recv(*((int*)client), &c, 1, 0)>0){
      data[i]=c;
    }else{
      sendError(buf, "TIMEOUT", client);
      free(data);
      free(client);
      return NULL;
    }
  }

  //handle request and inform client about success or failure
  char* out = NULL;
  if(handle_request(data,i, &out)==-1){
    if(out!=NULL){
      send(*((int*)client), out, strlen(out), 0);
    }
    else{
      response(buf, "UNKNOWN ERROR WHILE PROCESSING CONTENT", client);
    }
  }else{
    if(out==NULL)
      response(buf, "OK", client);
    else{
      send(*((int*)client), out, strlen(out), 0);
      free(out);
    }
  }

 close(*((int*)client));
 free(data);
 free(client);
 return NULL;
}

//send an error message and close client socket
void sendError(char *buf, const char* msg, void *client){
  strcpy(buf, msg);
  send(*((int*)client), buf, strlen(buf), 0);
  close(*((int*)client));
}

//send a response message but don't close client socket
void response(char *buf, const char* msg, void *client){
  strcpy(buf, msg);
  send(*((int*)client), buf, strlen(buf), 0);
}

int get_line(int sock, char *buf, int size){
 int i = 0;
 char c = '\0';
 int n;

 while ((i < size - 1) && (c != '\n'))
 {
  n = recv(sock, &c, 1, 0);
  /* DEBUG printf("%02X\n", c); */
  if (n > 0){
   if (c == '\r'){
    n = recv(sock, &c, 1, MSG_PEEK);
    /* DEBUG printf("%02X\n", c); */
    if ((n > 0) && (c == '\n'))
     recv(sock, &c, 1, 0);
    else
     c = '\n';
   }
   buf[i] = c;
   i++;
  }
  else
   c = '\n';
 }
 buf[i] = '\0';

 return(i);
}

void bad_request(int client){
 char buf[1024];

 strcpy(buf, "HTTP/1.0 400 BAD REQUEST\r\n");
 send(client, buf, strlen(buf), 0);
 strcpy(buf, "Content-type: text/html\r\n");
 send(client, buf, strlen(buf), 0);
 strcpy(buf, "\r\n");
 send(client, buf, strlen(buf), 0);
}

/**********************************************************************/
/* Return the informational HTTP headers about a file. */
/* Parameters: the socket to print the headers on
 *             the name of the file */
/**********************************************************************/
void headers(int client){
 char buf[1024];

 strcpy(buf, "HTTP/1.0 200 OK\r\n");
 send(client, buf, strlen(buf), 0);
 strcpy(buf, "Access-Control-Allow-Origin:*\r\n");
 send(client, buf, strlen(buf), 0);
 strcpy(buf, SERVER_STRING);
 send(client, buf, strlen(buf), 0);
 strcpy(buf, "Content-Type: text/html\r\n");
 send(client, buf, strlen(buf), 0);
 strcpy(buf, "\r\n");
 send(client, buf, strlen(buf), 0);
}

void error_die(const char *sc){
 fprintf(stderr, "%s",sc);
 exit(1);
}

//build server socket
int startup(u_short *port){
 int httpd = 0;
 struct sockaddr_in name;
 struct timeval tv;

 httpd = socket(PF_INET, SOCK_STREAM, 0);
 if (httpd == -1)
  error_die("socket");
 memset(&name, 0, sizeof(name));
 name.sin_family = AF_INET;
 name.sin_port = htons(*port);
 name.sin_addr.s_addr = htonl(INADDR_ANY);
 if (bind(httpd, (struct sockaddr *)&name, sizeof(name)) < 0)
  error_die("bind");
 if (*port == 0){  /* if dynamically allocating a port */
  socklen_t namelen = sizeof(name);
  if (getsockname(httpd, (struct sockaddr *)&name, &namelen) == -1)
   error_die("getsockname");
  *port = ntohs(name.sin_port);
 }

 tv.tv_sec = 10;
 tv.tv_usec = 0;
 setsockopt(httpd, SOL_SOCKET, SO_RCVTIMEO, (char *)&tv,sizeof(struct timeval));

 if (listen(httpd, 5) < 0)
  error_die("listen");
 return(httpd);
}

//init procedure to start server. Is called from main.c
int init(){
  struct stat st = {0};
	if (stat(FILES_DIR, &st) == -1) {
	    if(mkdir(FILES_DIR, 0700)==-1)						//create directory for settings file if not existing
	    	return -1;											//may fail on an other RedPitaya (other OS version, manipulated file structure,..)
	}


	pthread_t newthread;
	server_running = 1;
	if (pthread_create(&newthread , NULL, &mainLoop, NULL) != 0)
   return -1;
	return 0;
}

void shutdownServer(){
	server_running = 0;
  if(server_sock!=-1){
    close(server_sock);
  }
}

//main server loop, where server is started and server accepts clients. For each client a new (detached) thread is created.
void * mainLoop(void* foo){
 int client_sock = -1;
 struct sockaddr_in client_name;
 socklen_t client_name_len = sizeof(client_name);
 pthread_t newthread;

 server_sock = startup(&port);
 printf("httpd running on port %d\n", port);
 while (server_running)
 {
  client_sock = accept(server_sock,
                       (struct sockaddr *)&client_name,
                       &client_name_len);

	if(!server_running)
		break;

  int *new_fd = (int*)malloc(sizeof *new_fd);
  if (client_sock == -1 || new_fd ==NULL)
    continue;
  *new_fd = client_sock;
   /* accept_request(client_sock); */
  if (pthread_create(&newthread , NULL, &accept_request, new_fd) != 0)
    perror("pthread_create");
  else
    pthread_detach(newthread);
  }

 close(server_sock);

 printf("shutdown\n");
 return NULL;
}

//write value to fpga
int write_value(unsigned int a_addr, unsigned int a_value, char** error) {
    int fd = -1;
    if((fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1){
      fprintf(stderr, "Error at line %d, file %s (%d) [%s]\n", __LINE__, __FILE__, errno, strerror(errno));
      *error = strerror(errno);
      return -1;
    }
    void *map_base = mmap(0, MAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, a_addr & ~MAP_MASK);
	if(map_base == (void *) -1){
    fprintf(stderr, "Error at line %d, file %s (%d) [%s]\n", __LINE__, __FILE__, errno, strerror(errno));
    *error = strerror(errno);
    return -1;
  }

	void* virt_addr = map_base + (a_addr & MAP_MASK);
	*((unsigned int *) virt_addr) = a_value;

  if (map_base != (void*)(-1)) {
		if(munmap(map_base, MAP_SIZE) == -1){
      fprintf(stderr, "Error at line %d, file %s (%d) [%s]\n", __LINE__, __FILE__, errno, strerror(errno));
      *error = strerror(errno);
      return -1;
    }
		map_base = (void*)(-1);
	}

	if (fd != -1) {
		close(fd);
	}

  return 0;
}

char* concat(char *s1, char *s2){
    char *result = (char*)malloc(strlen(s1)+strlen(s2)+1);//+1 for the zero-terminator; free externally !
    if(result==NULL)
    	return NULL;
    strcpy(result, s1);
    strcat(result, s2);
    return result;
}
