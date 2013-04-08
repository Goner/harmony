#ifndef _PRIVATECOMMON_H
#define _PRIVATECOMMON_H

#include "cJSON.h"
#include "cc.h"
#include "NASError.h"

#define MAX_SEM_COUNT 1
#define THREADCOUNT 12
#define MAX_CHAR_P 1024
#define MAX_IP     16
#define MAX_PORT   16
#define AUTH_S_CON_F -3
#define TRANSACT_FAILD -1
#define GET_FILE_FAILD -1
#define INTERFACE_ERROR -1
#define SEMAPHORE_FAILD -1
#define _DEBUG 1
#define CON_MSG 1
#define CON_FILE 2
using std::string;
extern char g_msg_port[];
extern char g_auth_port[];
extern char g_file_port[];
extern char g_license_port[];
extern char box_ip[MAX_IP];
#ifndef WIN32
#include <semaphore.h>
extern sem_t* g_msgSemaphore;
extern sem_t* g_fileSemaphore;
void enter_critical(sem_t* ghSemaphore);
void release_critical(sem_t* ghSemaphore);

typedef void *LPVOID;
#else
extern HANDLE g_msgSemaphore;;
extern HANDLE g_fileSemaphore;
void enter_critical(HANDLE ghSemaphore);
void release_critical(HANDLE ghSemaphore);
#endif
extern UDTSOCKET g_msg_client;
extern UDTSOCKET g_file_client;
extern UDTSOCKET g_license_client;
extern UDTSOCKET g_remotemsg_client;

/*UDT建立连接，
type：CON_MSG，消息传输
	  CON_FILE 文件传输*/
int udt_connect(UDTSOCKET *client,const char *udt_ip,char *udt_port,int type);
string Char2String(char *dest);
/*初始化信号量*/
int init_sem();
int recv_msg_common(LPVOID usocket,char *buf,int *len);
int send_msg_common(LPVOID usocket,const char *buf,int len);

#endif