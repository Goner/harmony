// interfaceudt_client.cpp :
//
#include <stdio.h>
#include <stdlib.h>

#ifndef WIN32
	#include <sys/socket.h>
	#include <netdb.h>
    #include <unistd.h>
#else
	#include "stdafx.h"
	#include <winsock2.h>
	#include <ws2tcpip.h>
	#include <wspiapi.h>
	#include <Windows.h>

#endif

#include <iostream>
#include <strstream>


#include <string>
#include <string.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "interfaceudt_client.h"
#include "private_common.h"
using std::cin;
using std::cout;
using std::endl;
using std::string;
using namespace std;




int send_msg(char *buf, int len)
{
	int ret=-1; 
	ret=send_msg_common(&g_msg_client,buf,len);
	return ret;
}

int recv_msg(char **buf, int *len)
{
	int ret=-1;
	recv_msg_common(&g_msg_client, *buf, len);
	return ret;
}




int udt_connect(UDTSOCKET *client,const char *udt_ip,char *udt_port,int con_type)
{
   UDT::startup();
   int i=0;
   int udt_con=-1;
   struct addrinfo hints, *local, *peer;

   memset(&hints, 0, sizeof(struct addrinfo));

   hints.ai_flags = AI_PASSIVE;
   hints.ai_family = AF_INET;
  // hints.ai_socktype = SOCK_STREAM;
   if(CON_MSG==con_type)
   {
	   hints.ai_socktype = SOCK_DGRAM;
	    //printf("SOCK_DGRAM\n");
   }else
   {
       hints.ai_socktype = SOCK_STREAM;
	   //printf("SOCK_STREAM\n");
   }
   if (0 != getaddrinfo(NULL, udt_port, &hints, &local))
   {
      //cout << "incorrect network address.\n" << endl;
      return INTERFACE_ERROR;
   }
   cout<<"local->ai_family==" << local->ai_family<<endl;
 
   *client = UDT::socket(local->ai_family, local->ai_socktype, local->ai_protocol);
    //for ios reset buf size
    int snd_buf = 64000;
    int rcv_buf = 64000;
    UDT::setsockopt(*client, 0, UDT_SNDBUF, &snd_buf, sizeof(int));
    UDT::setsockopt(*client, 0, UDT_RCVBUF, &rcv_buf, sizeof(int));
    snd_buf = 64000;
    rcv_buf = 64000;
    UDT::setsockopt(*client, 0, UDP_SNDBUF, &snd_buf, sizeof(int));
    UDT::setsockopt(*client, 0, UDP_RCVBUF, &rcv_buf, sizeof(int));
    
   freeaddrinfo(local);
   //printf("udt_ip==%s\n",udt_ip);
   //printf("udt_port==%s\n",udt_port);
   if (0 != getaddrinfo(udt_ip, udt_port, &hints, &peer))
   {
      //cout << "incorrect server/peer address. " << udt_ip << ":" << udt_port << endl;
      return INTERFACE_ERROR;
   }

   //printf("peer->ai_addrlen==%ud \n",peer->ai_addrlen);
   while(i<4&&UDT::ERROR==udt_con)
   {
       udt_con=UDT::connect(*client, peer->ai_addr, peer->ai_addrlen);
       //cout << "connect: " << UDT::getlasterror().getErrorMessage() << endl;
	   i++;
#ifdef WIN32
	   Sleep(100);
#else
       usleep(100);
#endif
   }

   if(i>=4&&UDT::ERROR==udt_con)
   {
	  //cout << "connect: " << UDT::getlasterror().getErrorMessage() << endl;
      return INTERFACE_ERROR;
   }
#if 0
   if (UDT::ERROR == UDT::connect(*client, peer->ai_addr, peer->ai_addrlen))
   {
      //cout << "connect: " << UDT::getlasterror().getErrorMessage() << endl;
      return INTERFACE_ERROR;
   }
#endif
   freeaddrinfo(peer);

   return 0;
}



int local_access_auth(const char *ip, const char *account, const char *password)
{
	int ret=-1;
	UDTSOCKET client;
	char buf[MAX_CHAR_P]={0};
	int auth_result = 0;

	strcpy(box_ip,ip);
	//char *auth_port;
	ret=udt_connect(&client,ip,g_auth_port,CON_MSG);

	if(ret==-1)
	{
		cout<<"connect:faild!!"<<endl;
		return INTERFACE_ERROR;	
	}
	
	sprintf(buf,"{\"METHOD\":\"SETCFG\",\"TYPE\":\"LOGIN\",\"ACCOUNT\":\"%s\",\"PASSWORD\":\"%s\"}",account,password);
	ret=send_msg_common(&client,buf,strlen(buf)+1);
	if(ret!=0)
	{
		cout<<"send_msg:account and password faild!!"<<endl;
		return INTERFACE_ERROR;
	}
    
    char result[1024];
    int result_len=1024;
	ret=recv_msg_common(&client, result,&result_len);
    if(ret!=0)
	{
		cout<<"recv_msg:account and password faild!!"<<endl;
		return INTERFACE_ERROR;
	}
    
    cJSON* json = cJSON_Parse(result);
    auth_result = strcmp(json->child->valuestring, "SUCCESS");
    cJSON_Delete(json);

	UDT::close(client);
    UDT::cleanup();
	/**/
	if(SUCCESS==auth_result)
	{		
		ret=udt_connect(&g_msg_client,ip,g_msg_port,CON_MSG);
		if(SUCCESS!=ret)
		{
			return AUTH_S_CON_F;
		}

		ret=udt_connect(&g_file_client,ip,g_file_port,CON_FILE);
		if(SUCCESS!=ret)
		{
			return AUTH_S_CON_F;
		}
		init_sem();
	}
	return auth_result;

}



const char* transact_proc_call (const char *in_param)
{
	char *temp_buf=NULL;
	char buf[MAX_CHAR_P]={0};
	//printf("in_param=%s\n",in_param);
	strncpy(buf,in_param,MAX_CHAR_P);
	int temp_len=strlen(buf)+1;
	int result_len=0;
	int ret=-1;
	//printf("buf==%s\n",buf);
	enter_critical(g_msgSemaphore);

	ret=send_msg_common(&g_msg_client,in_param,strlen(in_param));
	if(SUCCESS!=ret)
	{
		cout<<" transact_proc_call:send_msg_common faild!!"<<endl;
		release_critical(g_msgSemaphore); 
		return NULL;
	}

   temp_len=0;
   //printf("recv json\n");
   if (UDT::ERROR == UDT::recvmsg(g_msg_client, (char*)&temp_len, sizeof(int)))
   {
      //cout << " transact_proc_call:recvmsg: " << UDT::getlasterror().getErrorMessage() << endl;
	  release_critical(g_msgSemaphore); 
      return NULL;
   }
    temp_buf=(char *)malloc(temp_len+1);
   if(NULL==temp_buf)
   {
	  //cout << " transact_proc_call:malloc faild!" << endl;
	  release_critical(g_msgSemaphore);
	  return NULL;
   }
    memset(temp_buf, 0, temp_len + 1);
    //printf("temp_len==%d\n",temp_len);
    
   if (UDT::ERROR == UDT::recvmsg(g_msg_client, temp_buf, temp_len))
   {
      //cout << "transact_proc_call:recvmsg: " << UDT::getlasterror().getErrorMessage() << endl;
	  release_critical(g_msgSemaphore);
      return NULL;
   }
    
   //printf("out_param==%s\n",temp_buf);
   release_critical(g_msgSemaphore);
   return temp_buf;
}


int get_vcard_data(const char *device_id, char **pvcard_data)
{
    cJSON *root;
    char *myjson;
    int ret=-1;
    int len=0;
    int64_t size=-1;
    int data_size = 0;
    int recv_size=0;
    char buf[MAX_CHAR_P] = {};
    enter_critical(g_fileSemaphore);

    root=cJSON_CreateObject();
    cJSON_AddStringToObject(root,"METHOD","GETCARD");
    cJSON_AddStringToObject(root,"TYPE","GETCARD");
    cJSON_AddStringToObject(root,"DEVICEID",device_id);
    myjson=cJSON_Print(root);
    if(myjson==NULL)
    {
        cout<<"myjson : NULL!!"<<endl;
        return -1;
    }

    len=strlen(myjson)+1;
    //printf("json success:%s\n",myjson);

    if (UDT::ERROR == UDT::send(g_file_client, (char*)&len, sizeof(int), 0))
    {
		free(myjson);
		myjson=NULL;
		cJSON_Delete (root);
        //cout << "get_file: send:json len " << UDT::getlasterror().getErrorMessage() << endl;
        return -1;
    }
    //printf("send len success\n");
    if (UDT::ERROR == UDT::send(g_file_client, myjson, len, 0))
    {
        free(myjson);
        myjson=NULL;
        cJSON_Delete (root);
        //cout <<  "get_file: send: "<< UDT::getlasterror().getErrorMessage() << endl;
        return -1;
    }
    free(myjson);
    myjson=NULL;
    cJSON_Delete (root);
    //printf("send json success\n");
    

    if (UDT::ERROR == UDT::recv(g_file_client, (char*)&size, sizeof(int64_t), 0))
    {
        //cout << "get_file: recv" << UDT::getlasterror().getErrorMessage() << endl;
        return -1;
    }

    if (size < 0)
    {
        //cout << "cann not get vcard file on the server\n";
        return -1;
    }
    //printf("vcard data size=%lld\n",size);

    char *vcard_data = (char *)malloc(size);
    while(size-data_size>0)
    {
        memset( buf,0,MAX_CHAR_P);
        recv_size=UDT::recv(g_file_client, buf, MAX_CHAR_P, 0);
        //printf("received package size==%d\n",recv_size);
        if (UDT::ERROR == recv_size){
            //cout << "get_file: recv" << UDT::getlasterror().getErrorMessage() << endl;
            free(vcard_data);
            return -1;
        }
       memcpy(vcard_data + data_size, buf, recv_size);
	   data_size += recv_size;
	   //printf("received data size == %d\n", data_size);
    }
    //printf("get vcard file\n");

    release_critical(g_fileSemaphore);
    *pvcard_data = vcard_data;
    return size;
}


int transfer_data_for_cmd(const char *data, int data_size, const char *json_cmd)
{
    const int package_max_size = 1024;
	char buf[package_max_size]={0};
	int send_size = 0;
    int data_pos = 0;
    int len = 0;
	int64_t size;

	enter_critical(g_fileSemaphore);

	len=strlen(json_cmd)+1;
    if (UDT::ERROR == UDT::send(g_file_client, (char*)&len, sizeof(int), 0))
    {
      //cout << "transfer_file: send: " << UDT::getlasterror().getErrorMessage() << endl;
      return GET_FILE_FAILD;
    }

    if (UDT::ERROR == UDT::send(g_file_client, json_cmd, len, 0))
    {
      //cout <<  "transfer_file: send: "<< UDT::getlasterror().getErrorMessage() << endl;
      return GET_FILE_FAILD;
    }

    if (UDT::ERROR == UDT::recv(g_file_client, (char*)&size, sizeof(int64_t), 0))
    {
      //cout << "transfer_file: recv" << UDT::getlasterror().getErrorMessage() << endl;
      return GET_FILE_FAILD;
    }

    //printf("size==%lld\n",size);

    while(data_pos < data_size) {
        memset(buf,0,MAX_CHAR_P);
        //send_size = (package_max_size < data_size - data_pos) ? package_max_size : data_size - data_pos;
        if(package_max_size < data_size - data_pos) {
            send_size = package_max_size;
        }else {
            send_size = data_size - data_pos;
        }
        memcpy(buf, data + data_pos, send_size);

        send_size = UDT::send(g_file_client, buf, send_size, 0);
        if (UDT::ERROR == send_size) {
            //cout << "transfer_file: send: " << UDT::getlasterror().getErrorMessage() << endl;
            return GET_FILE_FAILD;
        }
        data_pos += send_size;
   }
   //printf("send data %d\n", data_pos);

   release_critical(g_fileSemaphore);
   return SUCCESS;
}

int transfer_vcard(const char *data, int data_size, const char* device_id)
{
    int ret = 0;
    cJSON *root;
    char *myjson=NULL;
    char sizeStr[1024] = {};
    sprintf(sizeStr, "%d", data_size);
    
	root=cJSON_CreateObject();
	cJSON_AddStringToObject(root,"METHOD","TRANSFERCARD");
	cJSON_AddStringToObject(root,"TYPE","TRANSFERCARD");
	cJSON_AddStringToObject(root,"DEVICEID",device_id);
    cJSON_AddStringToObject(root, "FILESIZE", sizeStr);
	myjson=cJSON_Print(root);
    ret = transfer_data_for_cmd(data, data_size, myjson);
    free(myjson);
    cJSON_Delete (root);
    return ret;
    
}
int transfer_photo(const char *data, int data_size, const char* filename,const char* device_id)
{
    int ret = 0;
    cJSON *root;
    char *myjson=NULL;
    char sizeStr[1024] = {};
    sprintf(sizeStr, "%d", data_size);
    
	root=cJSON_CreateObject();
	cJSON_AddStringToObject(root,"METHOD","TRANSFERPHOTO");
	cJSON_AddStringToObject(root,"TYPE","TRANSFERPHOTO");
	cJSON_AddStringToObject(root,"DEVICEID",device_id);
    cJSON_AddStringToObject(root,"FILENAME",filename);
    cJSON_AddStringToObject(root, "FILESIZE", sizeStr);
	myjson=cJSON_Print(root);
    ret = transfer_data_for_cmd(data, data_size, myjson);
    free(myjson);
    cJSON_Delete (root);
    return ret;
}

int udt_close()
{
    
	UDT::close(g_msg_client);
	UDT::close(g_file_client);
	UDT::cleanup();
	return SUCCESS;
}




