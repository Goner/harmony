// interfaceudt_client.cpp : 定义控制台应用程序的入口点。
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


int remote_access_auth (char *account, char *password, char *license, int len)
{
	char remote_ip[MAX_IP]="10.1.8.132";
	char remote_msg_port[MAX_PORT]="8200";
	udt_connect(&g_msg_client,remote_ip,remote_msg_port,CON_MSG);
	return SUCCESS;
}

/*此接口和void transact_proc_call (std::string &in_param, std::string &out_param, int &len);相同合并为一个接口*/
int get_folder_meta(char *path, char *meta, int *len)
{
	return SUCCESS;
}

/*建立连接*/
int udt_connect(UDTSOCKET *client,char *udt_ip,char *udt_port,int con_type)
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
	   hints.ai_socktype = SOCK_DGRAM;/*SOCK_STREAM不支持sendmsg模式*/
	    printf("SOCK_DGRAM\n");
   }else
   {
       hints.ai_socktype = SOCK_STREAM;
	   printf("SOCK_STREAM\n");
   }
   if (0 != getaddrinfo(NULL, udt_port, &hints, &local))
   {
      cout << "incorrect network address.\n" << endl;
      return INTERFACE_ERROR;
   }
   cout<<"local->ai_family=="+local->ai_family<<endl;
 
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
   printf("udt_ip==%s\n",udt_ip);
   printf("udt_port==%s\n",udt_port);
   if (0 != getaddrinfo(udt_ip, udt_port, &hints, &peer))
   {
      cout << "incorrect server/peer address. " << udt_ip << ":" << udt_port << endl;
      return INTERFACE_ERROR;
   }

   printf("peer->ai_addrlen==%ud \n",peer->ai_addrlen);
   while(i<4&&UDT::ERROR==udt_con)
   {
       udt_con=UDT::connect(*client, peer->ai_addr, peer->ai_addrlen);
	   i++;
#ifdef WIN32
	   Sleep(100);
#else
       usleep(100);
#endif
   }

   if(i>4&&UDT::ERROR==udt_con)
   {
	  cout << "connect: " << UDT::getlasterror().getErrorMessage() << endl;
      return INTERFACE_ERROR;
   }
#if 0
   if (UDT::ERROR == UDT::connect(*client, peer->ai_addr, peer->ai_addrlen))
   {
      cout << "connect: " << UDT::getlasterror().getErrorMessage() << endl;
      return INTERFACE_ERROR;
   }
#endif
   freeaddrinfo(peer);

   return 0;
}


/*认证建立连接*/
int local_access_auth(char *ip, char *account, char *password)
{
	int ret=-1;
	UDTSOCKET client;
	char buf[MAX_CHAR_P]={0};
	int auth_result=-1;
	int result_len=0;
	strcpy(box_ip,ip);
	//char *auth_port;
	ret=udt_connect(&client,ip,g_auth_port,CON_MSG);

	if(ret==-1)
	{
		cout<<"connect:faild!!"<<endl;
		return INTERFACE_ERROR;	
	}
	
	sprintf(buf,"account:%s;password:%s",account,password);
	ret=send_msg_common(&client,buf,strlen(buf)+1);
	if(ret!=0)
	{
		cout<<"send_msg:account and password faild!!"<<endl;
		return INTERFACE_ERROR;
	}
	ret=recv_msg_common(&client,(char *)&auth_result,&result_len);
	if(ret!=0)
	{
		cout<<"recv_msg:account and password faild!!"<<endl;
		return INTERFACE_ERROR;
	}
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

		ret=udt_connect(&g_file_client,ip,g_file_port,CON_MSG);
		if(SUCCESS!=ret)
		{
			return AUTH_S_CON_F;
		}
		init_sem();
	}
	return auth_result;	

}
/*发送和接收json函数*/


void transact_proc_call (char *in_param, char *out_param, int *len)
//void transact_proc_call (std::string &in_param, std::string &out_param, int &len)
{
	char *temp_buf=out_param;
	char buf[MAX_CHAR_P]={0};
	printf("in_param=%s\n",in_param);
	strncpy(buf,in_param,MAX_CHAR_P);
	int temp_len=strlen(buf)+1;
	int result_len=0;
	int ret=-1;
	printf("buf==%s\n",buf);
	enter_critical(g_msgSemaphore);
	/*先发送数据长度，再发送真实数据*/
	ret=send_msg_common(&g_msg_client,buf,*len);
	if(SUCCESS!=ret)
	{
		cout<<" transact_proc_call:send_msg_common faild!!"<<endl;
		*len=TRANSACT_FAILD;
		release_critical(g_msgSemaphore); 
		return ;
	}

/*先接收数据长度，再接收真实数据*/

   temp_len=0;
   printf("recv json\n");
   if (UDT::ERROR == UDT::recvmsg(g_msg_client, (char*)&temp_len, sizeof(int)))
   {
      cout << " transact_proc_call:recvmsg: " << UDT::getlasterror().getErrorMessage() << endl;
	  *len=TRANSACT_FAILD;
	  release_critical(g_msgSemaphore); 
      return ;
   }
  // temp_buf=(char *)malloc(temp_len+1);
   printf("temp_len==%d\n",temp_len);
   if(NULL==temp_buf)
   {
	  cout << " transact_proc_call:malloc faild!" << endl;
	  *len=TRANSACT_FAILD;
	  release_critical(g_msgSemaphore);
	  return ;
   }
   if (UDT::ERROR == UDT::recvmsg(g_msg_client, temp_buf, temp_len))
   {
      cout << "transact_proc_call:recvmsg: " << UDT::getlasterror().getErrorMessage() << endl;
	  *len=TRANSACT_FAILD;
	  release_critical(g_msgSemaphore);
      return;
   }
   //out_param=temp_buf;
   #ifdef _DEBUG
   //cout<<"debug:resvmsg:"<<out_param<<endl;
   #endif
   printf("out_param==%s\n",out_param);
   *len=temp_len;
   release_critical(g_msgSemaphore);
   return;
}

/*{“METHOD”:”GETDATA”,”TYPE”:”GETDATA”,”FILESRC”:”/ROOT/xxxx”,”LEN”:”123”,”OFFSET”:”1234”}
返回文件大小*/
int get_data(char *buf, int64_t off_set, int64_t len, char *src_file_path)
{
	char *temp_buf=buf;
	char *temp_box_src=src_file_path;
	char file_size[16]={0};
	char char_offset[16]={0};
	cJSON *root=NULL;
	char *myjson=NULL;
	int ret=-1;
	int temp_len=0;
	enter_critical(g_fileSemaphore);
	sprintf(file_size,"%lld",len);
	printf("file_size==%s\n",file_size);
	sprintf(char_offset,"%lld",off_set);
	root=cJSON_CreateObject();
	cJSON_AddStringToObject(root,"METHOD","GETDATA");
	cJSON_AddStringToObject(root,"TYPE","GETDATA");
	cJSON_AddStringToObject(root,"LEN",file_size);
	cJSON_AddStringToObject(root,"FILESRC",temp_box_src);
	cJSON_AddStringToObject(root,"OFFSET",char_offset);
	myjson=cJSON_Print(root);
	if(myjson==NULL)
	{
		cout<<"myjson : NULL!!"<<endl;
		return GET_FILE_FAILD;
	}
	temp_len = strlen(myjson)+1;

   if (UDT::ERROR == UDT::send(g_file_client, (char*)&temp_len, sizeof(int), 0))
   {
		free(myjson);
		myjson=NULL;
		cJSON_Delete (root);
	  cout << "get_data: send: " << UDT::getlasterror().getErrorMessage() << endl;
      return GET_FILE_FAILD;
   }

   if (UDT::ERROR == UDT::send(g_file_client, myjson, temp_len, 0))
   {
		free(myjson);
		myjson=NULL;
		cJSON_Delete (root);
	  cout <<  "get_data: send: "<< UDT::getlasterror().getErrorMessage() << endl;
      return GET_FILE_FAILD;
   }
   free(myjson);
   myjson=NULL;
   cJSON_Delete (root);

   /*接收要接收的文件大小*/
  /* if (UDT::ERROR == UDT::recv(g_file_client, (char*)&temp_len, sizeof(int), 0))
   {
      cout << "get_data: recv" << UDT::getlasterror().getErrorMessage() << endl;
      return GET_FILE_FAILD;
   }
   printf("temp_len==%d\n",temp_len);*/
   if (UDT::ERROR == UDT::recv(g_file_client, temp_buf, len, 0))
   {
      cout << "get_data: recv" << UDT::getlasterror().getErrorMessage() << endl;
      return GET_FILE_FAILD;
   }

   printf("temp_buf=%s\n",temp_buf);
   release_critical(g_fileSemaphore); 
   return SUCCESS;
}


/*license 以文件形式传输
{“METHOD”:”GETLICENSE”,”TYPE”:”GETLICENSE”,”LOCAL_FILESIZE”:”0”}
返回文件大小*/
int get_license(char *license)
{
	char *temp_license=license;
	char file_size[16]={0};
	char temp_filename[MAX_CHAR_P]={0};
	FILE *local_fp;
#ifndef WIN32
    struct stat stat_buffer;
#else
	struct _stat stat_buffer;
#endif
	cJSON *root;
	char *myjson;
	int ret=-1;
	int temp_len=0;
	int64_t size;
	int64_t temp_size;
	int recv_size=0;
	udt_connect(&g_license_client,box_ip,g_license_port,CON_FILE);
	//memset(&stat_buffer,0,sizeof(struct _stat));
	strcpy(temp_license,"../license.ls");
#ifndef WIN32
    memset(&stat_buffer,0,sizeof(struct stat));
    ret= stat((const char *)temp_license,&stat_buffer);
#else
    memset(&stat_buffer,0,sizeof(struct _stat));
	ret= _stat((const char *)temp_license,&stat_buffer);
#endif
	sprintf(file_size,"%d",stat_buffer.st_size);
	root=cJSON_CreateObject();
	cJSON_AddStringToObject(root,"METHOD","GETLICENSE");
	cJSON_AddStringToObject(root,"TYPE","GETLICENSE");
	cJSON_AddStringToObject(root,"LOCAL_FILESIZE",file_size);
	myjson=cJSON_Print(root);
	if(myjson==NULL)
	{
		cout<<"myjson : NULL!!"<<endl;
		return GET_FILE_FAILD;
	}
	if( (local_fp=fopen(temp_license,"wb+"))==NULL )
	{
		cout<<"get_license : open local faild!!"<<endl;
		return GET_FILE_FAILD;
	}
	temp_len = strlen(myjson)+1;
	/*传输要接收的文件目录*/
   if (UDT::ERROR == UDT::send(g_license_client, (char*)&temp_len, sizeof(int), 0))
   {
		free(myjson);
		myjson=NULL;
		cJSON_Delete (root);
	  cout << "get_license: send: " << UDT::getlasterror().getErrorMessage() << endl;
      return GET_FILE_FAILD;
   }

   if (UDT::ERROR == UDT::send(g_license_client, myjson, temp_len, 0))
   {
		free(myjson);
		myjson=NULL;
		cJSON_Delete (root);
	  cout <<  "get_license: send: "<< UDT::getlasterror().getErrorMessage() << endl;
      return GET_FILE_FAILD;
   }
   free(myjson);
   myjson=NULL;
   cJSON_Delete (root);

   /*接收要接收的文件大小*/
   if (UDT::ERROR == UDT::recv(g_file_client, (char*)&size, sizeof(int64_t), 0))
   {
      cout << "get_license: recv" << UDT::getlasterror().getErrorMessage() << endl;
      return GET_FILE_FAILD;
   }

   if (size < 0)
   {
      cout << "no license " << " on the server\n";
      return GET_FILE_FAILD;
   }
   temp_size=+stat_buffer.st_size;
   fseek(local_fp,stat_buffer.st_size,0); 

    /*开始接收文件*/
   while(size-temp_size>MAX_CHAR_P)
   {
	   memset( temp_filename,0,MAX_CHAR_P);
	   recv_size=UDT::recv(g_file_client, temp_filename, MAX_CHAR_P, 0);
	   
	   if (UDT::ERROR == recv_size)
	   {
		  cout << "get_license: recv" << UDT::getlasterror().getErrorMessage() << endl;
		  return GET_FILE_FAILD;
	   }

	   temp_size=+recv_size;
	   if(1!=fwrite(temp_filename,MAX_CHAR_P,1,local_fp))
	   {
		  cout << "get_license: fwrite faild!!"<< endl;
		  return GET_FILE_FAILD;
	   }
   }
   recv_size=UDT::recv(g_file_client, temp_filename, size-temp_size, 0);
   if(1!=fwrite(temp_filename,(size - temp_size),1,local_fp))
	{
		cout << "get_license: fwrite faild!!"<< endl;
		return GET_FILE_FAILD;
	}
   fclose(local_fp);
   UDT::close(g_file_client);
   return SUCCESS;
}


/*文件访问 中的函数都需要用先用json字符串交互命令,然后再传输文件
{“METHOD”:”GETFILE”,”TYPE”:”GETFILE”,”FILESRC”:”/ROOT/xxxx”,”LOCAL_FILESIZE”:”0”}
返回文件大小*/
int get_file(char *dst_file_path, char *src_file_path)
{
	char *temp_local_dst=dst_file_path;
	char *temp_box_src=src_file_path;
	char temp_filename[MAX_CHAR_P]={0};
#ifndef WIN32
    struct stat stat_buffer;
#else
	struct _stat stat_buffer;
#endif
	char file_size[16]={0};
	FILE *local_fp;
	cJSON *root;
	char *myjson;
	int ret=-1;
	int len=0;
	int64_t size=-1;
	int64_t temp_size=-1;
	int recv_size=0;
	int temp_recvsize=0;
	enter_critical(g_fileSemaphore);
	//memset(&stat_buffer,0,sizeof(struct _stat));
#ifndef WIN32
    memset(&stat_buffer,0,sizeof(struct stat));
    ret= stat((const char *)temp_local_dst,&stat_buffer);
#else
    memset(&stat_buffer,0,sizeof(struct _stat));
	ret= _stat((const char *)temp_local_dst,&stat_buffer);
#endif
	sprintf(file_size,"%d",stat_buffer.st_size);
	root=cJSON_CreateObject();
	cJSON_AddStringToObject(root,"METHOD","GETFILE");
	cJSON_AddStringToObject(root,"TYPE","GETFILE");
	cJSON_AddStringToObject(root,"FILESRC",temp_box_src);
	cJSON_AddStringToObject(root,"LOCAL_FILESIZE",file_size);
	myjson=cJSON_Print(root);
	if(myjson==NULL)
	{
		cout<<"myjson : NULL!!"<<endl;
		return GET_FILE_FAILD;
	}
	if( (local_fp=fopen(temp_local_dst,"a+b"))==NULL )
	{
		cout<<"get_file : open local faild!!"<<endl;
		return GET_FILE_FAILD;
	}
	len=strlen(myjson)+1;
	printf("json success:%s\n",myjson);
	/*传输要接收的文件目录*/
   if (UDT::ERROR == UDT::send(g_file_client, (char*)&len, sizeof(int), 0))
   {
		free(myjson);
		myjson=NULL;
		cJSON_Delete (root);
	  cout << "get_file: send:json len " << UDT::getlasterror().getErrorMessage() << endl;
      return GET_FILE_FAILD;
   }
   printf("send len success\n");
   if (UDT::ERROR == UDT::send(g_file_client, myjson, len, 0))
   {
		free(myjson);
		myjson=NULL;
		cJSON_Delete (root);
	  cout <<  "get_file: send: "<< UDT::getlasterror().getErrorMessage() << endl;
      return GET_FILE_FAILD;
   }
   free(myjson);
   myjson=NULL;
   cJSON_Delete (root);
   printf("send json success\n");
      
   /*接收要接收的文件大小*/
   if (UDT::ERROR == UDT::recv(g_file_client, (char*)&size, sizeof(int64_t), 0))
   {
      cout << "get_file: recv" << UDT::getlasterror().getErrorMessage() << endl;
      return GET_FILE_FAILD;
   }

   if (size < 0)
   {
      cout << "no such file " << temp_box_src << " on the server\n";
      return GET_FILE_FAILD;
   }
   printf("size=%lld\n",size);

   temp_size=+stat_buffer.st_size;
   printf("temp_size=%lld\n",temp_size);
   fseek(local_fp,stat_buffer.st_size,0); 
   printf("begin recv file\n");
   printf("size-temp_size==%d\n",size-temp_size);
   /*开始接收文件*/
   while(size-temp_size>MAX_CHAR_P)
   {
	   printf("size-temp_size==%d\n",size-temp_size);
	   memset( temp_filename,0,MAX_CHAR_P);
	   recv_size=UDT::recv(g_file_client, temp_filename, MAX_CHAR_P, 0);
	   printf("recv_size==%d\n",recv_size);
	   if (UDT::ERROR == recv_size)
	   {
		  cout << "get_file: recv" << UDT::getlasterror().getErrorMessage() << endl;
		  return GET_FILE_FAILD;
	   }

	   temp_size+=recv_size;
	   printf("temp_size==%lld\n",temp_size);
	   if(1!=fwrite(temp_filename,recv_size,1,local_fp))
	   {
		  cout << "get_file: fwrite faild!!"<< endl;
		  return GET_FILE_FAILD;
	   }
   }
   printf("recv last pakage\n");
   recv_size=0;
   temp_recvsize=0;
   while(file_size - temp_size-recv_size>0)
   {
	  recv_size=UDT::recv(g_file_client, temp_filename, (size - temp_size), 0);
	  if (UDT::ERROR == recv_size)
	  {
		cout << "proc_transferfile: recv" << UDT::getlasterror().getErrorMessage() << endl;
		fclose(local_fp);
		return -1;
	  }
	  recv_size+=temp_recvsize;
   }
   if(1!=fwrite(temp_filename,recv_size,1,local_fp))
	{
		cout << "get_file: fwrite faild!!"<< endl;
		return GET_FILE_FAILD;
	}
   release_critical(g_fileSemaphore);
   fclose(local_fp);
   return SUCCESS;
}

/*{“METHOD”:”TRANSFERFILE”,”TYPE”:”TRANSFERFILE”,”FILEDST”:”/ROOT/xxxx”，”FILESIZE”:”0“}

返回文件大小*/
int transfer_file(char *dst_file_path, char *src_file_path)
{
	char *temp_local_dst=src_file_path;
	char *temp_box_src=dst_file_path;
	char temp_filename[MAX_CHAR_P]={0};
	char file_size[16]={0};
#ifndef WIN32
    struct stat stat_buffer;
#else
	struct _stat stat_buffer;
#endif
	int i=0;
	FILE *local_fp;
	cJSON *root;
	char *myjson=NULL;
	int len=0;
	int64_t size;
	int64_t temp_size;
	int recv_size=0;
	int ret=-1;
	/*临界区*/
	enter_critical(g_fileSemaphore);

	if( (local_fp=fopen(temp_local_dst,"rb"))==NULL )
	{
		cout<<"transfer_file : open local faild!!"<<endl;
		return GET_FILE_FAILD;
	}

#ifndef WIN32
    memset(&stat_buffer,0,sizeof(struct stat));
    ret= stat((const char *)temp_local_dst,&stat_buffer);
#else
    memset(&stat_buffer,0,sizeof(struct _stat));
	ret= _stat((const char *)temp_local_dst,&stat_buffer);
#endif
	printf("stat_buffer.st_size==%d\n",stat_buffer.st_size);
	sprintf(file_size,"%d",stat_buffer.st_size);
	root=cJSON_CreateObject();
	cJSON_AddStringToObject(root,"METHOD","TRANSFERFILE");
	cJSON_AddStringToObject(root,"TYPE","TRANSFERFILE");
	cJSON_AddStringToObject(root,"FILEDST",temp_box_src);
	cJSON_AddStringToObject(root,"FILESIZE",file_size);
	myjson=cJSON_Print(root);
	/*传输要接收的文件目录*/
	len=strlen(myjson)+1;
   if (UDT::ERROR == UDT::send(g_file_client, (char*)&len, sizeof(int), 0))
   {
      cout << "transfer_file: send: " << UDT::getlasterror().getErrorMessage() << endl;
      return GET_FILE_FAILD;
   }

   if (UDT::ERROR == UDT::send(g_file_client, myjson, len, 0))
   {
      cout <<  "transfer_file: send: "<< UDT::getlasterror().getErrorMessage() << endl;
      return GET_FILE_FAILD;
   }
   free(myjson);
   myjson=NULL;
   cJSON_Delete (root);
   /*接收返回消息*/

   if (UDT::ERROR == UDT::recv(g_file_client, (char*)&size, sizeof(int64_t), 0))
   {
      cout << "transfer_file: recv" << UDT::getlasterror().getErrorMessage() << endl;
      return GET_FILE_FAILD;
   }

   printf("size==%d\n",size);
   fseek(local_fp,size,0); 
   while(!feof(local_fp)) 
   {
		memset(temp_filename,0,MAX_CHAR_P);
		
		len=fread((void*)temp_filename,MAX_CHAR_P,1,local_fp);
		//printf("len=%d\n",len);

		if (UDT::ERROR == UDT::send(g_file_client, temp_filename, MAX_CHAR_P, 0))
		{
			cout << "transfer_file: send: " << UDT::getlasterror().getErrorMessage() << endl;
			fclose(local_fp);
			return GET_FILE_FAILD;
		}
		i+=1;
		//printf("len=%d\n",len);
   }
   printf("i==%d\n",i);
   /*释放临界区*/
   release_critical(g_fileSemaphore);
   fclose(local_fp);
   return SUCCESS;

}


int udt_close()
{
	UDT::close(g_msg_client);
	UDT::close(g_file_client);
	UDT::cleanup();
	return SUCCESS;
}




