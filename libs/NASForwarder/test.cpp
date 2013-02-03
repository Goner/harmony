
#include "stdafx.h"
#include <winsock2.h>
#include <ws2tcpip.h>
#include <wspiapi.h>
#include <iostream>
#include <strstream>

#include <Windows.h>
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
#include "private_common.h"
#include "message.h"
using std::cin;
using std::cout;
using std::endl;
using std::string;
using namespace std;



typedef struct sendpar{
	char *jsons_tring;
	UDTSOCKET *client;
	char *recv_buf;

}SENDPAR;

int sockfd;
struct sockaddr_in server_addr;
struct sockaddr_in box_addr;

/*string Char2String(char *dest)
{
	strstream ss;
	string strd;
	ss<<dest;
	//ss<<"000";
	cout<<ss<<endl;
	strd=ss.str();
	cout<<strd<<endl;
	return strd;
}*/

/*发送函数*/
DWORD WINAPI udt_sendjson(LPVOID sp)
{
   printf("waiting\n");
   WaitForSingleObject(g_msgSemaphore, INFINITE);  
   SENDPAR *send_par=(SENDPAR *)sp;
   int json_len = strlen(send_par->jsons_tring);
   UDTSOCKET msghandle=*(send_par->client);
   char recv_buff[1024]={0};
   int recv_len=25;
   /*发送请求*/
   printf("json_len=%d\n",json_len);
   printf("send_par->jsons_tring=%s\n",send_par->jsons_tring);
   printf("start time!!\n");
   if (UDT::ERROR == UDT::sendmsg(msghandle, send_par->jsons_tring, json_len+1, -1,false))
   {
      cout << "sendmsg: " << UDT::getlasterror().getErrorMessage() << endl;
	  ReleaseSemaphore(g_msgSemaphore, 1, NULL);  
      return -1;
   }
   printf("send success!\n");
   
   /*接收返回消息*/
   if (UDT::ERROR == UDT::recvmsg(msghandle,recv_buff ,recv_len))
   {
      cout << "recvmsg: " << UDT::getlasterror().getErrorMessage() << endl;
	  ReleaseSemaphore(g_msgSemaphore, 1, NULL);  
      return -1;
   }
   send_par->recv_buf=recv_buff;
   printf("recv_buff==%s\n",recv_buff);
   ReleaseSemaphore(g_msgSemaphore, 1, NULL);  

   return 0;
}

int get_file(char *dst_file_path, char *src_file_path);

int main(int argc,  char* argv[])
{
	UDTSOCKET client;
	//udt_connect(&g_msg_client,argv[1],argv[2],1);
	//udt_connect(&g_file_client,argv[1],argv[2],2);
	SENDPAR send_par;
	char par[1024]={0};
	char myjson[]="{colors:[\"red\",\"green\"]}";
	send_par.client=&client;
	char port[16]={0};
	int i=1;
	if(argv[3]==NULL)
	{
		printf("缺少选项参数\n");
	}
	i=atoi(argv[3]);
	//printf("%s\n",argv[3]);
	printf("%d\n",i);
	printf("%s\n",argv[4]);
	//string temp="{\"METHOD\":\"FRIEND\",\"TYPE\":\"GETFRIENDINFO\",\"USERNAME\":\"xxx\"}";
	//string temp="{\"METHOD\":\"SETCFG\",\"TYPE\":\"PPPOE\",\"USERNAME\":\"1111\",\"PASSWORD\":\"xxx\"}";
	//string temp="{\"METHOD\":\"SETCFG\",\"TYPE\":\"ACCOUNT\",\"ACCOUNT\":\"yuehaibo\",\"PASSWORD\":\"123123\"}";
	//{“METHOD”:“SHARE”, “TYPE”:”CREATE”,”USERNAME”:”XXXXX” ,“FRIENDLIST”: [{“NAME”:”jonny”,”SERIALNUM”:”123456”},{“NAME”:”john”,”SERIALNUM”:”455666”}, {“NAME”:”ken”,”SERIALNUM”:”455666”}],“FILELIST”:[”/web/1.jpg”,”/web/2.jpg”,”/web/3.jpg”]}
	//string temp="{\"METHOD\":\"SHARE\",\"TYPE\":\"CREATE\",\"USERNAME\":\"yuehaibo\",\"FRIENDLIST\":[{\"NAME\":\"jonny\",\"SERIALNUM\":\"123456\"},{\"NAME\":\"john\",\"SERIALNUM\":\"455666\"},{\"NAME\":\"ken\",\"SERIALNUM\":\"455666\"}],\"FILELIST\":[\"/web/1.jpg\",\"/web/2.jpg\",\"/web/3.jpg\"]}";
	//"{\"METHOD\":\"DOWNLOAD\",\"TYPE\":\"CREATE\",\"URL\":\"/merry/storage/public/1.torrent\"}"
	//"{\"METHOD\":\"DOWNLOAD\",\"TYPE\":\"GETTASKLIST\",\"TORRENTNAME\":\"1.torrent\"}"
	//"{\"METHOD\":\"SETCFG\",\"TYPE\":\"WIFIMASTER\",\"SSID\":\"10-111\",\"PASSWORD\":\"4009901099mmm\"}";
	//"{\"METHOD\":\"SETCFG\",\"TYPE\":\"LOGIN\",\"ACCOUNT\":\"yuehaibo\",\"PASSWORD\":\"123123\"}"
	//"{\"METHOD\":\"ALBUMSHARE\",\"TYPE\":\"ADD\",\"FILELIST\":[\"1.jpg\"]}"
	//"{\"METHOD\":\"ALBUMSHARE\",\"TYPE\":\"GETSHARESTATE\",\"ID\":[\"0\"]}"
	
	string temp; 
	int len_temp=0;
	send_par.jsons_tring = myjson;
	char *buf=(char *)malloc(40);;
	g_msgSemaphore = CreateSemaphore( 
	NULL, // default security attributes - lpSemaphoreAttributes是信号量的安全属性
	MAX_SEM_COUNT, // initial count - lInitialCount是初始化的信号量
	MAX_SEM_COUNT, // maximum count - lMaximumCount是允许信号量增加到最大值
	NULL); // unnamed semaphore - lpName是信号量的名称
	if (g_msgSemaphore == NULL) 
	{
	  printf("CreateSemaphore error: %d\n", GetLastError());
	  return -1;
	}

#if 1
	int ret = -1;
    struct build_channel_c2s_message build_channel_msg;
    struct build_channel_s2c_message build_channel_ack_msg;
    
    memset(&build_channel_msg, 0, sizeof(build_channel_msg));
    memset(&build_channel_ack_msg, 0, sizeof(build_channel_ack_msg));

    strcpy(build_channel_msg.mac, "1212121212");
    ret = build_channel(build_channel_msg, build_channel_ack_msg);
    if (ret == 0)
    {
        printf("build channel OK get box outer_ip:%s outer_port:%d\n", build_channel_ack_msg.box_ip, build_channel_ack_msg.box_port);
    }
    else
    {
        printf("build_channel failed\n");
        return -1;
    }
	
    //收到盒子外网信息后，关闭该socket，重新bind同一个端口，模拟交给udt过程
    myclose(sockfd);
	WSACleanup();
	ret = init();
    if(ret == -1)
    {
	    printf("reinit failed\n");
	    return -1;
    }
    else
    {
        printf("reinit OK\n");
    }
	memset(&box_addr, 0, sizeof(box_addr));
	char send[128] = "client datong connect test data...............";
    box_addr.sin_family = AF_INET;
    box_addr.sin_addr.s_addr = inet_addr(build_channel_ack_msg.box_ip);
    box_addr.sin_port = htons(build_channel_ack_msg.box_port);
	mysendto(sockfd, send, strlen(send), 0, (struct sockaddr *)&box_addr);
	myclose(sockfd);
	WSACleanup();
#endif
	switch (i)
	{
		case 1:
			
		//	udt_connect(&g_msg_client,argv[1],argv[2],1);
			//temp=Char2String(argv[4]);
#if 1
#if 0
	ret = init();
    if(ret == -1)
    {
	    printf("reinit failed\n");
	    return -1;
    }
    else
    {
        printf("reinit OK\n");
    }
	memset(&box_addr, 0, sizeof(box_addr));
	char send[128] = "client datong connect test data...............";
    box_addr.sin_family = AF_INET;
    box_addr.sin_addr.s_addr = inet_addr(build_channel_ack_msg.box_ip);
    box_addr.sin_port = htons(build_channel_ack_msg.box_port);
	mysendto(sockfd, send, strlen(send), 0, (struct sockaddr *)&box_addr);
	char recv_buffer[518];
	struct sockaddr_in remote_addr;
	int recv_num=0;
	int sin_size = sizeof(struct sockaddr_in);
	memset(&recv_buffer, 0, sizeof(recv_buffer));
	recv_num = recvfrom(sockfd, recv_buffer, sizeof(recv_buffer), 0, (struct sockaddr *)&remote_addr, (int /*socklen_t*/ *)&sin_size);
    if(recv_num == -1)
	{
		perror(" recvfrom error");
		return -1;
	}
	printf("recvform====%s\n\n",recv_buffer);
	myclose(sockfd);
	WSACleanup();
#endif
			sprintf(port,"%d",build_channel_ack_msg.box_port);
			printf("port==%s\n",port);
			udt_connect(&g_msg_client,build_channel_ack_msg.box_ip,port,1);
#endif
			//Sleep(40000);
			//udt_connect(&g_msg_client,"10.1.8.132","9528",1);
			len_temp=strlen(argv[4]);
			transact_proc_call(argv[4],par,&len_temp);
			printf("par==%s\n",par);
			break;
		case 2:
			udt_connect(&g_msg_client,argv[1],argv[2],2);
			transfer_file(argv[4], argv[5]);
			break;
		case 3:
			udt_connect(&g_msg_client,argv[1],argv[2],2);
			get_file(argv[5],argv[4]);
			break;
		default:
			printf("无这个选项哦！\n");
			break;
	}
  // int size = 100000;
  // char* data = new char[size];
	//get_file("../abd.pdf","./abc.pdf");
	//transfer_file("./aaa.xls", "D:/bcd.xls");
   // CreateThread(NULL, 0,udt_sendjson, &send_par, 0, NULL);
	//printf("%s",send_par.recv_buf);
	//CreateThread(NULL, 0,udt_sendjson, &send_par, 0, NULL);
	//memset(buf,0,40);
	 //transact_proc_call (std::string &in_param, std::string &out_param, int &len);
	//transact_proc_call(temp,par,len_temp);

	//Sleep(50000);
	//transact_proc_call(temp,par,len_temp);
	//get_data(buf, 12, 12,"./bbb.txt");
	//cout<<par<<endl;
	free(buf);
	buf=NULL;
	Sleep(30000);

   UDT::close(g_msg_client);

   //delete [] data;

   // use this function to release the UDT library
   UDT::cleanup();

  // return 1;

	return 0;
}