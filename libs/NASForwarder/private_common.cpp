#ifdef WIN32
#include "stdafx.h"
#include <winsock2.h>
#include <ws2tcpip.h>
#include <wspiapi.h>
#include <Windows.h>
#endif

#include <iostream>
#include <strstream>
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <string.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "interfaceudt_client.h"
#include  "private_common.h"
using std::cin;
using std::cout;
using std::endl;

using namespace std;

char g_msg_port[]="9900";
char g_auth_port[]="9001";
char g_file_port[]="9901";
char g_license_port[]="9003";
char box_ip[MAX_IP]={0};
UDTSOCKET g_msg_client;
UDTSOCKET g_file_client;
UDTSOCKET g_license_client;
UDTSOCKET g_remotemsg_client;


#ifndef WIN32
sem_t sem_msg;
sem_t sem_file;
sem_t* g_msgSemaphore = &sem_msg;
sem_t* g_fileSemaphore = &sem_file;
void enter_critical(sem_t* ghSemaphore)
{
	sem_wait(ghSemaphore);
}

void release_critical(sem_t* ghSemaphore)
{
	sem_post(ghSemaphore);
}

int init_sem()
{
    sem_init(g_msgSemaphore, 0, MAX_SEM_COUNT);
    sem_init(g_fileSemaphore, 0, MAX_SEM_COUNT);
}
#else
HANDLE g_msgSemaphore;
HANDLE g_fileSemaphore;

void enter_critical(HANDLE ghSemaphore)
{
	WaitForSingleObject(ghSemaphore, INFINITE);
}

void release_critical(HANDLE ghSemaphore)
{
	ReleaseSemaphore(ghSemaphore, 1, NULL);  
}

int init_sem()
{
	g_msgSemaphore = CreateSemaphore(
                                     NULL, // default security attributes - lpSemaphoreAttributes «–≈∫≈¡øµƒ∞≤»´ Ù–�?
                                     MAX_SEM_COUNT, // initial count - lInitialCount «≥ı ºªØµƒ–≈∫≈¡ø
                                     MAX_SEM_COUNT, // maximum count - lMaximumCount «‘ –Ì–≈∫≈¡ø‘ˆº”µΩ◊Ó¥Û÷µ
                                     NULL); // unnamed semaphore - lpName «–≈∫≈¡øµƒ√˚≥�?
	if (g_msgSemaphore == NULL)
	{
        printf("CreateSemaphore error: %d\n", GetLastError());
        return SEMAPHORE_FAILD;
	}
    
	g_fileSemaphore = CreateSemaphore(
                                      NULL, // default security attributes - lpSemaphoreAttributes «–≈∫≈¡øµƒ∞≤»´ Ù–�?
                                      MAX_SEM_COUNT, // initial count - lInitialCount «≥ı ºªØµƒ–≈∫≈¡ø
                                      MAX_SEM_COUNT, // maximum count - lMaximumCount «‘ –Ì–≈∫≈¡ø‘ˆº”µΩ◊Ó¥Û÷µ
                                      NULL); // unnamed semaphore - lpName «–≈∫≈¡øµƒ√˚≥�?
	if (g_fileSemaphore == NULL) 
	{
        printf("CreateSemaphore error: %d\n", GetLastError());
        return SEMAPHORE_FAILD;
	}
	return SUCCESS;
}
#endif

string Char2String(char *dest)
{
	strstream ss;
	string strd;
	ss<<dest;
	strd=ss.str();
	return strd;
}

/*�������÷��ͺ���*/
int send_msg_common(LPVOID usocket,char *buf,int len)
{
   UDTSOCKET usk = *(UDTSOCKET*)usocket;
   int ilen=strlen(buf)+1;


   if (UDT::ERROR == UDT::sendmsg(usk, (char *)&ilen, sizeof(int), -1,false))
   {
      cout << "sendmsg: " << UDT::getlasterror().getErrorMessage() << endl;
	 // ReleaseSemaphore(ghSemaphore, 1, NULL);  
      return INTERFACE_ERROR;
   }

   if (UDT::ERROR == UDT::sendmsg(usk, buf, ilen, -1,false))
   {
      cout << "sendmsg: " << UDT::getlasterror().getErrorMessage() << endl;
	 // ReleaseSemaphore(ghSemaphore, 1, NULL);  
      return INTERFACE_ERROR;
   }

   return 0;

}

/*�������պ���*/

int recv_msg_common(LPVOID usocket,char *buf,int *len)
{
   UDTSOCKET usk = *(UDTSOCKET*)usocket;
   char *temp_buf=buf;
   int temp_len=0;
   if (UDT::ERROR == UDT::recvmsg(usk, (char*)&temp_len, sizeof(int)))
   {
      cout << "recvmsg: " << UDT::getlasterror().getErrorMessage() << endl;
      return INTERFACE_ERROR;
   }

   if (UDT::ERROR == UDT::recvmsg(usk, temp_buf, temp_len))
   {
      cout << "recvmsg: " << UDT::getlasterror().getErrorMessage() << endl;
      return INTERFACE_ERROR;
   }
   *len=temp_len;
   return 0;
}