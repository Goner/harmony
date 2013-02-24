#ifndef _INTERFACEUDT_H
#define _INTERFACEUDT_H

#include "udt.h"

#define TEMP_TEST_MOD

int remote_access_auth (char *account, char *password, char *license, int len);
void transact_proc_call(char *in_param, char *out_param, int *len);

int local_access_auth(char *ip, char *account, char *password);
int send_msg(char *buf, int len);
int recv_msg(char **buf, int *len);
int get_vcard_to_file(const char *file_path, const char *device_id);
int transfer_vcard(const char *file_path);
int transfer_photo(const char *file_path);
void transact_proc_call (std::string &in_param, std::string &out_param, int &len);

int udt_close();

#endif