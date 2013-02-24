
#ifndef _INTERFACEUDT_H
#define _INTERFACEUDT_H

#include "udt.h"

#define TEMP_TEST_MOD

/*远程认证  建立连接，未完成等测试结果*/
int remote_access_auth (char *account, char *password, char *license, int len);

/*JSON消息传输*/
//void transact_proc_call (std::string &in_param, std::string &out_param, int &len);
void transact_proc_call(char *in_param, char *out_param, int *len);
/*本地认证*/
int local_access_auth(char *ip, char *account, char *password);
int get_license(char **license);
int send_msg(char *buf, int len);
int recv_msg(char **buf, int *len);
int get_file(char *dst_file_path, char *src_file_path);
int transfer_file(char *dst_file_path, char *src_file_path);
int get_data(char *buf, int64_t off_set, int64_t len, char *src_file_path);
/*此接口和void transact_proc_call (std::string &in_param, std::string &out_param, int &len);相同故合并为一个接口*/
int get_folder_meta(char *path, char *meta, int *len);
int udt_close();

#endif