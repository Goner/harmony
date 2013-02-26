#ifndef _INTERFACEUDT_H
#define _INTERFACEUDT_H

#include "udt.h"

#define TEMP_TEST_MOD

int remote_access_auth (char *account, char *password, char *license, int len);
void transact_proc_call(const char *in_param, char *out_param, int *len);

int local_access_auth(char *ip, char *account, char *password);
int send_msg(char *buf, int len);
int recv_msg(char **buf, int *len);
int get_vcard_data(const char *device_id, char **pvcard_data);
int transfer_vcard(const char *data, int data_size, const char* dvice_id);
int transfer_photo(const char *data, int data_size, const char* filename,const char* device_id);

int udt_close();

#endif