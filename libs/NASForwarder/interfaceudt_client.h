#ifndef _INTERFACEUDT_H
#define _INTERFACEUDT_H

#include "udt.h"

#define TEMP_TEST_MOD

const char* transact_proc_call(const char *in_param);

int local_access_auth(const char *ip, const char *account, const char *password);
int send_msg(char *buf, int len);
int recv_msg(char **buf, int *len);
int get_vcard_data(const char *device_id, char **pvcard_data);
int transfer_vcard(const char *data, int data_size, const char* dvice_id);
int transfer_photo(const char *data, int data_size, const char* filename,const char* device_id);

int udt_close();

#endif