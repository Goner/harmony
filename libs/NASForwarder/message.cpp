#include <windows.h>
#include <stdio.h>
#include <string.h> 
#include <signal.h>
#include <stdlib.h>
//#include <pthread.h>
#include <sys/types.h>
#include <winsock.h>
//#include <ws2tcpip.h>
//#include <wspiapi.h>
//#include <netinet/in.h>
//#include <arpa/inet.h>
//#include <unistd.h>
//#include <netdb.h>

#include "message.h"

#pragma comment(lib, "WS2_32")

#define SERVERIP "202.85.216.203"
//#define SERVERIP "10.1.8.253"
#define SERVERPORT 9100
#define CLIENT_LOCAL_PORT 9002

extern int sockfd;
extern struct sockaddr_in server_addr;
extern struct sockaddr_in box_addr;

int mysocket()
{ 
    int sockfd = -1;
    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd == -1)
    {
		WSAGetLastError();
		perror("create socket error");
        return -1;
    }
    else
    {
        printf("create socket OK\n");
    }

    return sockfd;
}

int mybind(int listenfd, int port)
{
    int ret = -1;
    struct sockaddr_in serveraddr;
    memset(&serveraddr, 0, sizeof(serveraddr));  
    serveraddr.sin_family = AF_INET;  
    serveraddr.sin_addr.s_addr = htonl(INADDR_ANY) ;
    serveraddr.sin_port = htons(port);
    
    ret = bind(listenfd, (struct sockaddr *) &serveraddr, sizeof(serveraddr));  
    if (ret == -1)
    {
        perror("bind error");
        return -1;
    }
    else
    {
        printf("bind OK\n");
    }
    
    return 0;
}

int myrecvfrom(int sockfd, char *buff, int len, int flag, struct sockaddr *addr)
{
    int recv_num;
    int sin_size = sizeof(struct sockaddr_in);
    recv_num = recvfrom(sockfd, buff, len, flag, addr, (int/*socklen_t*/ *)&sin_size);
    if(recv_num == -1)
	{
		perror(" recvfrom error");
		return -1;
	}

    return recv_num;
}

int mysendto(int sockfd, char *buff, int len, int flag, struct sockaddr *addr)
{
    int send_num = 0;
    send_num = sendto(sockfd, buff, len, flag, addr, sizeof(struct sockaddr));	
    if (send_num == -1)
    {
		perror(" sendto error");
		return -1;
	}

    return send_num;
}

int myclose(int sockfd)
{
    if (sockfd < 0)
    {   
        printf("program sockfd invalid\n");
        return -1;
    }
    closesocket(sockfd);

    return 0;
}

int init()
{
    int ret = -1;
	WSADATA  Ws;
	if ( WSAStartup(MAKEWORD(2,2), &Ws) != 0 )
    {
          GetLastError();
          return -1;
    }
	/*创建UDP套节字，进行绑定,无论是接收心跳回复消息还是打洞消息或者传输种子文件消息等，所有UDP包都是
	通过同一个socket，因为只有这个socket与balance保持心跳连接，能够随时被balance找到*/
	sockfd = mysocket();
    if (sockfd < 0)
    {
        return -1;
    }
    /*UDP client如果不调用bind，则客户端在向外发包时，会由系统自己决定使用的接口的源端口，而调用bind则可以指定相应的参数。*/
    ret = mybind(sockfd, CLIENT_LOCAL_PORT);
    if (ret == -1)
    {
        return -1;
    }
    // 服务器网络信息
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = inet_addr(SERVERIP);
    server_addr.sin_port = htons(SERVERPORT);
   
	return 0;
}

//void *recv_data(void *arg)
//void *recv_data(void *arg)
DWORD WINAPI recv_data(LPVOID sp)
{
    char recv_buffer[128];
    struct sockaddr_in temp_addr;
    printf("recv thread start OK\n");
    while(1)
    {
//        sleep(1);
		Sleep(1000);
        memset(recv_buffer, 0, sizeof(recv_buffer));
        myrecvfrom(sockfd, recv_buffer, sizeof(recv_buffer), 0, (struct sockaddr *)&temp_addr);
        printf("recv p2p test data:%s\n", recv_buffer);
    }

    return NULL;
}

int build_channel(struct build_channel_c2s_message build_channel_msg, struct build_channel_s2c_message &build_channel_ack_msg)
{
    WSADATA  Ws;
	if ( WSAStartup(MAKEWORD(2,2), &Ws) != 0 )
    {
          GetLastError();
          return -1;
    }
	int ret = -1;
    int send_num = 0;
    int recv_num;
    int sin_size = sizeof(struct sockaddr_in);
	int errorcode=0;
    char send_buffer[518];
    char recv_buffer[518];
    struct sockaddr_in remote_addr;
    struct build_channel_s2c_message *p_build_channel_ack_msg = NULL;

    memset(&send_buffer, 0, sizeof(send_buffer));
    memset(&recv_buffer, 0, sizeof(recv_buffer));
    memset(&remote_addr, 0, sizeof(remote_addr));

    //创建socket
	  sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd == -1)
    {
		errorcode=WSAGetLastError();
		perror("create socket error");
        return -1;
    }
    else
    {
        printf("create socket OK\n");
    }

    /*UDP client如果不调用bind，则客户端在向外发包时，会由系统自己决定使用的接口的源端口，而调用bind则可以指定固定的端口。*/
    struct sockaddr_in serveraddr;
    memset(&serveraddr, 0, sizeof(serveraddr));  
    serveraddr.sin_family = AF_INET;  
    serveraddr.sin_addr.s_addr = htonl(INADDR_ANY) ;
    serveraddr.sin_port = htons(CLIENT_LOCAL_PORT);
    ret = bind(sockfd, (struct sockaddr *) &serveraddr, sizeof(serveraddr));  
    if (ret == -1)
    {
        perror("bind error");
        return -1;
    }
    else
    {
        printf("bind OK\n");
    }
    
    // 服务器网络信息
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = inet_addr(SERVERIP);
    server_addr.sin_port = htons(SERVERPORT);
    //形成发送消息
    send_buffer[0] = MSG_BUILD_CHANNEL_C2S;
    memcpy(send_buffer+1, &build_channel_msg, sizeof(build_channel_msg));
    
    send_num = sendto(sockfd, send_buffer, sizeof(struct build_channel_c2s_message) + 1, 0, (struct sockaddr *)&server_addr, sizeof(struct sockaddr));	
    if (send_num == -1)
    {
		perror(" sendto error");
		return -1;
	}    
    printf("send request to build channel with mac:%s\n", build_channel_msg.mac);
    //阻塞接收返回盒子的外网信息
    recv_num = recvfrom(sockfd, recv_buffer, sizeof(recv_buffer), 0, (struct sockaddr *)&remote_addr, (int /*socklen_t*/ *)&sin_size);
    if(recv_num == -1)
	{
		perror(" recvfrom error");
		return -1;
	}
    if (recv_buffer[0] == MSG_BUILD_CHANNEL_S2C)
    {
        p_build_channel_ack_msg = (struct build_channel_s2c_message *)(recv_buffer+1);
        printf("recv box info OK\n");
        printf("box_online_flag:%d box_outer_ip:%s box_outer_port:%d\n", p_build_channel_ack_msg->online_flag, p_build_channel_ack_msg->box_ip, p_build_channel_ack_msg->box_port);
        build_channel_ack_msg.online_flag = p_build_channel_ack_msg->online_flag;
        memcpy(build_channel_ack_msg.box_ip, p_build_channel_ack_msg->box_ip, sizeof(p_build_channel_ack_msg->box_ip));
        build_channel_ack_msg.box_port = p_build_channel_ack_msg->box_port;
    }
    else
    {
        memset(&recv_buffer, 0, sizeof(recv_buffer));
		recv_num = recvfrom(sockfd, recv_buffer, sizeof(recv_buffer), 0, (struct sockaddr *)&remote_addr, (int /*socklen_t*/ *)&sin_size);
		if(recv_num == -1)
		{
			perror(" recvfrom error");
			return -1;
		}
		if (recv_buffer[0] == MSG_BUILD_CHANNEL_S2C)
		{
			p_build_channel_ack_msg = (struct build_channel_s2c_message *)(recv_buffer+1);
			printf("recv box info OK\n");
			printf("box_online_flag:%d box_outer_ip:%s box_outer_port:%d\n", p_build_channel_ack_msg->online_flag, p_build_channel_ack_msg->box_ip, p_build_channel_ack_msg->box_port);
			build_channel_ack_msg.online_flag = p_build_channel_ack_msg->online_flag;
			memcpy(build_channel_ack_msg.box_ip, p_build_channel_ack_msg->box_ip, sizeof(p_build_channel_ack_msg->box_ip));
			build_channel_ack_msg.box_port = p_build_channel_ack_msg->box_port;
		}
		else
		{
			printf("recv wrong data:%s\n", recv_buffer);
			return -1;
		}
    }
    
    return 0;
}