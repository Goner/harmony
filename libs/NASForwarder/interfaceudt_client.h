
#ifndef _INTERFACEUDT_H
#define _INTERFACEUDT_H

#include "udt.h"

#define TEMP_TEST_MOD

/*Զ����֤  �������ӣ�δ��ɵȲ��Խ��*/
int remote_access_auth (char *account, char *password, char *license, int len);

/*JSON��Ϣ����*/
//void transact_proc_call (std::string &in_param, std::string &out_param, int &len);
void transact_proc_call(char *in_param, char *out_param, int *len);
/*������֤*/
int local_access_auth(char *ip, char *account, char *password);
int get_license(char **license);
int send_msg(char *buf, int len);
int recv_msg(char **buf, int *len);
int get_file(char *dst_file_path, char *src_file_path);
int transfer_file(char *dst_file_path, char *src_file_path);
int get_data(char *buf, int64_t off_set, int64_t len, char *src_file_path);
/*�˽ӿں�void transact_proc_call (std::string &in_param, std::string &out_param, int &len);��ͬ�ʺϲ�Ϊһ���ӿ�*/
int get_folder_meta(char *path, char *meta, int *len);
int udt_close();

#endif