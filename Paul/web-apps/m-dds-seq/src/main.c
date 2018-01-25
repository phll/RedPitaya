#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "shttpd.h"
#include "main.h"

/****
** author Paul Hill
** implement module entry points for NGNIX-RedPitaya module
** start and stop a small http server
** provide its port for the web-frontend (via rp_params)
****/

extern u_short port;


const char *rp_app_desc(void)
{
  return (const char *)"Multi DDS Sequencer.\n";
}

int rp_app_init(void)
{
  return init();
}

int rp_app_exit(void)
{
	shutdownServer();
  return 0;
}

int rp_set_params(rp_app_params_t *p, int len)
{
  return 0;
}

int rp_get_params(rp_app_params_t **p)
{
  rp_app_params_t *p_copy = NULL;
  p_copy = (rp_app_params_t *)malloc((2) * sizeof(rp_app_params_t));
  if(p_copy == NULL)
      return -1;

  char* name = (char*)"port";
  int p_strlen = strlen(name);
  p_copy[0].name = (char *)malloc(p_strlen+1);				//nginx module tries to free this later
  strncpy((char *)&p_copy[0].name[0], &name[0],
                p_strlen);
  p_copy[0].name[p_strlen]='\0';
  p_copy[0].value = port;
  p_copy[1].name = NULL; 					//prudent! Otherwise NGINX does not know array length

  *p = p_copy;
	return 1;
}

int rp_get_signals(float ***s, int *sig_num, int *sig_len)
{
  if(*s == NULL)
    return -1;
  *sig_len = 0;
  return 0;
}
