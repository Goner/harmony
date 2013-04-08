#include <stdio.h>
#include <string.h> 
#include <signal.h>
#include <stdlib.h>
//#include <pthread.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <iostream>
#include <strstream>
#include <netdb.h>

#include "udt.h"
#include "curl.h"
#include "private_common.h"
#include "parsewebjson.h"
#include "curl_exchange.h"
#include "md5.h"
#include "message.h"


#define SERVERIP "202.85.216.203" //"10.1.8.253"
#define SERVERPORT 9100
#define CLIENT_LOCAL_PORT 9002
#define CLIENT_LOCAL_PORT1 9003

using namespace std;
int sockfd, sockfd1;
struct sockaddr_in server_addr;
struct sockaddr_in box_addr;


void mysleep(int i)
{
#ifdef WIN32
	Sleep(i);
#else
	sleep(i);
#endif
}


int mysocket()
{ 
    int sockfd = -1;
    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd == -1)
    {
        perror("create socket error");
        return -1;
    }
    else
    {
        //printf("create socket OK\n");
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
    
    ret = ::bind(listenfd, (struct sockaddr *) &serveraddr, sizeof(serveraddr));
    if (ret == -1)
    {
        perror("bind error");
        return -1;
    }
    else
    {
        //printf("bind OK\n");
    }
    
    return 0;
}

int myrecvfrom(int sockfd, char *buff, int len, int flag, struct sockaddr *addr)
{
    int recv_num;
    int sin_size = sizeof(struct sockaddr_in);
    recv_num = recvfrom(sockfd, buff, len, flag, addr, (socklen_t *)&sin_size);
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
        //printf("program sockfd invalid\n");
        return -1;
    }
    close(sockfd);
    return 0;
}


int init1()
{
    int ret = -1;
#ifdef WIN32
	WSADATA  Ws;
	if ( WSAStartup(MAKEWORD(2,2), &Ws) != 0 )
    {
          GetLastError();
          return -1;
    }
#endif
	/*¥¥Ω®UDPÃ◊Ω⁄◊÷£¨Ω¯––∞Û∂®,Œﬁ¬€ «Ω” ’–ƒÃ¯ªÿ∏¥œ˚œ¢ªπ «¥Ú∂¥œ˚œ¢ªÚ’ﬂ¥´ ‰÷÷◊”Œƒº˛œ˚œ¢µ»£¨À˘”–UDP∞¸∂º «
	Õ®π˝Õ¨“ª∏ˆsocket£¨“ÚŒ™÷ª”–’‚∏ˆsocket”Îbalance±£≥÷–ƒÃ¯¡¨Ω”£¨ƒ‹πªÀÊ ±±ªbalance’“µΩ*/
	sockfd1 = mysocket();
    if (sockfd1 < 0)
    {
        return -1;
    }
    /*UDP client»Áπ˚≤ªµ˜”√bind£¨‘ÚøÕªß∂À‘⁄œÚÕ‚∑¢∞¸ ±£¨ª·”…œµÕ≥◊‘º∫æˆ∂® π”√µƒΩ”ø⁄µƒ‘¥∂Àø⁄£¨∂¯µ˜”√bind‘Úø…“‘÷∏∂®œ‡”¶µƒ≤Œ ˝°£*/
    ret = mybind(sockfd1, CLIENT_LOCAL_PORT1);
    if (ret == -1)
    {
        return -1;
    }
    // ∑˛ŒÒ∆˜Õ¯¬Á–≈œ¢
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = inet_addr(SERVERIP);
    server_addr.sin_port = htons(SERVERPORT);
   
	return 0;
}


int init()
{
    int ret = -1;
#ifdef WIN32
	WSADATA  Ws;
	if ( WSAStartup(MAKEWORD(2,2), &Ws) != 0 )
    {
          GetLastError();
          return -1;
    }
#endif
	/*¥¥Ω®UDPÃ◊Ω⁄◊÷£¨Ω¯––∞Û∂®,Œﬁ¬€ «Ω” ’–ƒÃ¯ªÿ∏¥œ˚œ¢ªπ «¥Ú
	∂¥œ˚œ¢ªÚ’ﬂ¥´ ‰÷÷◊”Œƒº˛œ˚œ¢µ»£¨À˘”–UDP∞¸∂º «
	Õ®π˝Õ¨“ª∏ˆsocket£¨“ÚŒ™÷ª”–’‚∏ˆsocket”Îbalance±£≥÷–ƒÃ¯¡¨Ω”£¨ƒ‹πªÀÊ ±±ªbalance’“µΩ*/
	sockfd = mysocket();
    if (sockfd < 0)
    {
        return -1;
    }
    /*UDP client»Áπ˚≤ªµ˜”√bind£¨‘ÚøÕªß∂À‘⁄œÚÕ‚∑¢∞¸ ±£¨
    ª·”…œµÕ≥◊‘º∫æˆ∂® π”√µƒΩ”ø⁄µƒ‘¥∂Àø⁄£¨
    ∂¯µ˜”√bind‘Úø…“‘÷∏∂®œ‡”¶µƒ≤Œ ˝°£*/
    ret = mybind(sockfd, CLIENT_LOCAL_PORT);
    if (ret == -1)
    {
        return -1;
    }
    // ∑˛ŒÒ∆˜Õ¯¬Á–≈œ¢
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = inet_addr(SERVERIP);
    server_addr.sin_port = htons(SERVERPORT);
   
	return 0;
}

void *recv_data(void *arg)
{
    char recv_buffer[128];
    struct sockaddr_in temp_addr;
    //printf("recv thread start OK\n");
    while(1)
    {
        mysleep(1);
        memset(recv_buffer, 0, sizeof(recv_buffer));
        myrecvfrom(sockfd, recv_buffer, sizeof(recv_buffer), 0, (struct sockaddr *)&temp_addr);
        //printf("recv p2p test data:%s\n", recv_buffer);
    }

    return NULL;
}

int build_channel(int socketfd, int port, struct build_channel_c2s_message build_channel_msg, struct build_channel_s2c_message &build_channel_ack_msg)
{
    int ret = -1;
    int send_num = 0;
    int recv_num;
    int sin_size = sizeof(struct sockaddr_in);
    char send_buffer[518];
    char recv_buffer[518];
    struct sockaddr_in remote_addr;
    struct build_channel_s2c_message *p_build_channel_ack_msg = NULL;

    memset(&send_buffer, 0, sizeof(send_buffer));
    memset(&recv_buffer, 0, sizeof(recv_buffer));
    memset(&remote_addr, 0, sizeof(remote_addr));

    //¥¥Ω®socket
	/*socketfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (socketfd == -1)
    {
        perror("create socket error");
        return -1;
    }
    else
    {
        //printf("create socket OK\n");
    }*/

    /*UDP client»Áπ˚≤ªµ˜”√bind£¨‘ÚøÕªß∂À‘⁄œÚÕ‚∑¢∞¸ ±£¨ª·”…œµÕ≥◊‘º∫æˆ∂® π”√µƒΩ”ø⁄µƒ‘¥∂Àø⁄£¨∂¯µ˜”√bind‘Úø…“‘÷∏∂®πÃ∂®µƒ∂Àø⁄°£*/
    struct sockaddr_in serveraddr;
    memset(&serveraddr, 0, sizeof(serveraddr));  
    serveraddr.sin_family = AF_INET;  
    serveraddr.sin_addr.s_addr = htonl(INADDR_ANY) ;
    serveraddr.sin_port = htons(port);
    ret = ::bind(socketfd, (struct sockaddr *) &serveraddr, sizeof(serveraddr));
    if (ret == -1)
    {
        //perror("bind error");
        return -1;
    }
    else
    {
        //printf("bind OK\n");
    }
    
    // ∑˛ŒÒ∆˜Õ¯¬Á–≈œ¢
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = inet_addr(SERVERIP);
    server_addr.sin_port = htons(SERVERPORT);
    //–Œ≥…∑¢ÀÕœ˚œ¢
    send_buffer[0] = MSG_BUILD_CHANNEL_C2S;
    memcpy(send_buffer+1, &build_channel_msg, sizeof(build_channel_msg));
    
    send_num = sendto(socketfd, send_buffer, sizeof(struct build_channel_c2s_message) + 1, 0, (struct sockaddr *)&server_addr, sizeof(struct sockaddr));	
    if (send_num == -1)
    {
		perror(" sendto error");
		return -1;
	}
    
    fd_set rset;
    struct timeval tv;
    time_t lasttime;
    time_t curtime;
    lasttime = time(NULL);
    while (1)
    {
        curtime = time(NULL);
        if ((curtime - lasttime) > 30)
        {
            //printf("no get box outer info over 30 seconds\n");
            //服务器无响应
            return E_SERVER_NOT_RESPONSE;
        }
        
        tv.tv_sec = 2;
        tv.tv_usec = 0;
        FD_ZERO(&rset);
        FD_SET(socketfd, &rset);
        ret = select(socketfd + 1, &rset, NULL, NULL, &tv);
        if (ret == 0)
        {
            printf("select timeout......\n");
            continue;
        }
        else if (ret == -1)
        {
            perror("slect error");
            return -1;
        }
        else if (ret > 0)
        {
            memset(&recv_buffer, 0, sizeof(recv_buffer));
            recv_num = recvfrom(socketfd, recv_buffer, sizeof(recv_buffer), 0, (struct sockaddr *)&remote_addr, (socklen_t *)&sin_size);
            if(recv_num == -1)
            {
                perror(" recvfrom error");
                return -1;
            }
            if (recv_buffer[0] == MSG_BUILD_CHANNEL_S2C)
            {
                p_build_channel_ack_msg = (struct build_channel_s2c_message *)(recv_buffer+1);
                printf("2:recv box info OK\n");
                printf("box_status:%d box_outer_ip:%s box_outer_port:%d\n", p_build_channel_ack_msg->status, p_build_channel_ack_msg->box_ip, p_build_channel_ack_msg->box_port);
                if ((p_build_channel_ack_msg->status == 0) || (p_build_channel_ack_msg->status == 2) || (strlen(p_build_channel_ack_msg->box_ip) == 0) || (p_build_channel_ack_msg->box_port == 0))
                {
                    //盒子不在线
                    //printf("box is not online\n");
                    return E_BOX_NOT_ONLINE;
                }
                else
                {
                    printf("box is online\n");
                    build_channel_ack_msg.status = p_build_channel_ack_msg->status;
                    memcpy(build_channel_ack_msg.box_ip, p_build_channel_ack_msg->box_ip, sizeof(p_build_channel_ack_msg->box_ip));
                    build_channel_ack_msg.box_port = p_build_channel_ack_msg->box_port;
                    break;
                }
            }
            else
            {
                printf("recv wrong data:%s\n", recv_buffer);
            }
        }
    }
    
    return 0;
}

#if 0
/*π´π≤µ˜”√∑¢ÀÕ∫Ø ˝*/
int send_msg_common(UDTSOCKET usocket, char *buf, int len)
{
   int ilen=strlen(buf)+1;

   if (UDT::ERROR == UDT::sendmsg(usocket, (char *)&ilen, sizeof(int), -1,false))
   {
      //printf("sendmsg:%s\n", UDT::getlasterror().getErrorMessage());
      return -1;
   }

   if (UDT::ERROR == UDT::sendmsg(usocket, buf, ilen, -1,false))
   {
      //printf("sendmsg:%s\n", UDT::getlasterror().getErrorMessage());
      return -1;
   }

   return 0;
}

/*π´π≤Ω” ’∫Ø ˝*/

int recv_msg_common(UDTSOCKET usocket,char *buf,int *len)
{
   char *temp_buf=buf;
   int temp_len=0;
   if (UDT::ERROR == UDT::recvmsg(usocket, (char*)&temp_len, sizeof(int)))
   {
      //printf("recvmsg:%s\n", UDT::getlasterror().getErrorMessage());
      return -1;
   }

   if (UDT::ERROR == UDT::recvmsg(usocket, temp_buf, temp_len))
   {
      //printf("recvmsg:%s\n", UDT::getlasterror().getErrorMessage());
      return -1;
   }
   *len=temp_len;
   
   return 0;
}
#endif
int user_outer_login(struct outer_login_message msg, struct outer_login_ack_message &ack_msg)
{
    char url[256];
    char response[512];
    char request[512];
    char json_response[512];
        
    memset(url, 0, sizeof(url));
    memset(response, 0, sizeof(response));
    memset(request, 0, sizeof(request));
    memset(json_response, 0, sizeof(json_response));
    
    MD5 md5(msg.password);   
    std::string md5_result = md5.md5();   
    //printf("md5 result is:%s \n", md5_result.c_str());

    strcpy(url, "http://cloud.99merry.com:8080/merrycloud/box/weblogin.json");
    sprintf(request, "username=%s&password=%s", msg.username, md5_result.c_str());
    
    exchange_with_mysql(url, request, response);
    //printf("response data:\n%s\n", response);
    //π˝¬À∫ÛÃ®∑µªÿµƒjson ˝æ›
    filter_response(response, json_response);
    //printf("json_response:%s\n", json_response);

    parse_web_login(json_response, ack_msg);

    return 0;
}



int remote_auth(char *user,char *pwd, char (&ipAddress)[16])
{
	int ret = -1;
    struct outer_login_message msg;
    struct outer_login_ack_message ack_msg;
    struct build_channel_c2s_message build_channel_msg, build_channel_msg1;
    struct build_channel_s2c_message build_channel_ack_msg, build_channel_ack_msg1;

    memset(&msg, 0, sizeof(msg));
    memset(&ack_msg, 0, sizeof(ack_msg));
    memset(&build_channel_msg, 0, sizeof(build_channel_msg));
    memset(&build_channel_ack_msg, 0, sizeof(build_channel_ack_msg));
    memset(&build_channel_msg1, 0, sizeof(build_channel_msg1));
    memset(&build_channel_ack_msg1, 0, sizeof(build_channel_ack_msg1));

	//Õ‚Õ¯µ«¬º
    strcpy(msg.username, user);
    strcpy(msg.password, pwd);
    ret = user_outer_login(msg, ack_msg);
    if (ack_msg.flag == 0)
    {
        //printf("outer_login failed\n");
        return E_WRONG_USER_OR_PASSWORD;
    }
 //Ω®¡¢¥´ÀÕœ˚œ¢Õ®µ¿
    build_channel_msg.flag = 1;
    strcpy(build_channel_msg.username, msg.username);
    strcpy(build_channel_msg.serialnum, ack_msg.serialnum);
    strcpy(build_channel_msg.token, ack_msg.token);
    sockfd = mysocket();
    ret = build_channel(sockfd, CLIENT_LOCAL_PORT, build_channel_msg, build_channel_ack_msg);
    if (ret == 0)
    {
        strncpy(ipAddress, build_channel_ack_msg.box_ip, 16);
        //printf("build channel OK get box outer_ip:%s outer_port:%d\n", build_channel_ack_msg.box_ip, build_channel_ack_msg.box_port);
    }
    else
    {
        close(sockfd);
        //printf("build_channel failed\n");
        return ret;
    }


	   // ’µΩ∫–◊”Õ‚Õ¯–≈œ¢∫Û£¨πÿ±’∏√socket£¨÷ÿ–¬bindÕ¨“ª∏ˆ∂Àø⁄£¨Ωª∏¯udtπ˝≥Ã
    myclose(sockfd);

    //÷ÿ–¬bindÕ¨“ª∏ˆ∂Àø⁄£¨Ωª∏¯udt¥¶¿Ì
    ret = init();
    if(ret == -1)
    {
        close(sockfd);
	    //printf("reinit failed\n");
	    return E_NETWORK_NOT_AVAILABLE;
    }
    else
    {
        //printf("reinit OK\n");
    }
     
    memset(&box_addr, 0, sizeof(box_addr));
    box_addr.sin_family = AF_INET;
    box_addr.sin_addr.s_addr = inet_addr(build_channel_ack_msg.box_ip);
    box_addr.sin_port = htons(build_channel_ack_msg.box_port);

    char send[128] = "client datong connect test data...............";
    ret = mysendto(sockfd, send, strlen(send), 0, (struct sockaddr *)&box_addr);
    if (ret == -1)
    {
        //printf("send to box p2p test data failed\n ");
    }
    else
    {
        //printf("send to box p2p test data OK sendnum:%d box_ip:%s box_port:%d\n", ret, build_channel_ack_msg.box_ip, build_channel_ack_msg.box_port);
    }
    
    g_msg_client =UDT::socket(AF_INET, SOCK_DGRAM, 0);
    int snd_buf = 64000;
    int rcv_buf = 64000;
    UDT::setsockopt(g_msg_client, 0, UDT_SNDBUF, &snd_buf, sizeof(int));
    UDT::setsockopt(g_msg_client, 0, UDT_RCVBUF, &rcv_buf, sizeof(int));
    snd_buf = 64000;
    rcv_buf = 64000;
    UDT::setsockopt(g_msg_client, 0, UDP_SNDBUF, &snd_buf, sizeof(int));
    UDT::setsockopt(g_msg_client, 0, UDP_RCVBUF, &rcv_buf, sizeof(int));
    bool rendezvous = true;
    if (UDT::setsockopt (g_msg_client, SOL_SOCKET, UDT_RENDEZVOUS,&rendezvous , sizeof(bool)) !=0)
    {
        close(sockfd);
        close(g_msg_client);
        //printf("setsockopt SO_REUSEADDR %s \n",UDT::getlasterror().getErrorMessage());
        return E_LOW_NETWORK_QUALITY;
    }
                 
    if (UDT::ERROR == UDT::bind(g_msg_client, sockfd))
    {
        close(sockfd);
        close(g_msg_client);
        //printf("UDT bind failed:%s\n" , UDT::getlasterror().getErrorMessage());
        return E_LOW_NETWORK_QUALITY;
    }    

    if (UDT::ERROR == UDT::connect(g_msg_client, (struct sockaddr *)&box_addr,sizeof(box_addr)))
    {
        close(sockfd);
        close(g_msg_client);
        //printf("UDT connect failed:%s\n ",UDT::getlasterror().getErrorMessage());
        return E_LOW_NETWORK_QUALITY;
    }
    else
    {
        //printf("connect to client OK\n");
    }
    g_file_client =UDT::socket(AF_INET, SOCK_STREAM, 0);
    UDT::setsockopt(g_file_client, 0, UDT_SNDBUF, &snd_buf, sizeof(int));
    UDT::setsockopt(g_file_client, 0, UDT_RCVBUF, &rcv_buf, sizeof(int));
    UDT::setsockopt(g_file_client, 0, UDP_SNDBUF, &snd_buf, sizeof(int));
    UDT::setsockopt(g_file_client, 0, UDP_RCVBUF, &rcv_buf, sizeof(int));
  //Ω®¡¢¥´ ‰Œƒº˛Õ®µ¿
    build_channel_msg1.flag = 2;
    strcpy(build_channel_msg1.username, msg.username);
    strcpy(build_channel_msg1.serialnum, ack_msg.serialnum);
    strcpy(build_channel_msg1.token, ack_msg.token);
    sockfd1 = mysocket();
    ret = build_channel(sockfd1, CLIENT_LOCAL_PORT1, build_channel_msg1, build_channel_ack_msg1);
    if (ret == 0)
    {
        //printf("build channel OK get box outer_ip:%s outer_port:%d\n", build_channel_ack_msg1.box_ip, build_channel_ack_msg1.box_port);
    }
    else
    {
        close(sockfd);
        close(g_msg_client);
        close(sockfd1);
        close(g_file_client);
        //printf("build_channel failed\n");
        return ret;
    }

    // ’µΩ∫–◊”Õ‚Õ¯–≈œ¢∫Û£¨πÿ±’∏√socket£¨÷ÿ–¬bindÕ¨“ª∏ˆ∂Àø⁄£¨Ωª∏¯udtπ˝≥Ã
  myclose(sockfd1);

    //÷ÿ–¬bindÕ¨“ª∏ˆ∂Àø⁄£¨Ωª∏¯udt¥¶¿Ì
    ret = init1();
    if(ret == -1)
    {
        close(sockfd);
        close(g_msg_client);
        close(sockfd1);
        close(g_file_client);
	    //printf("reinit failed\n");
	    return E_NETWORK_NOT_AVAILABLE;
    }
    else
    {
        //printf("reinit OK\n");
    }
     
    memset(&box_addr, 0, sizeof(box_addr));
    box_addr.sin_family = AF_INET;
    box_addr.sin_addr.s_addr = inet_addr(build_channel_ack_msg1.box_ip);
    box_addr.sin_port = htons(build_channel_ack_msg1.box_port);

    char send1[128] = "client datong connect test data...............";
    ret = mysendto(sockfd1, send1, strlen(send1), 0, (struct sockaddr *)&box_addr);
    if (ret == -1)
    {
        //printf("send to box p2p test data failed\n ");
    }
    else
    {
        //printf("send to box p2p test data OK sendnum:%d box_ip:%s box_port:%d\n", ret, build_channel_ack_msg1.box_ip, build_channel_ack_msg1.box_port);
    }   
    
    if (UDT::setsockopt (g_file_client, SOL_SOCKET, UDT_RENDEZVOUS,&rendezvous , sizeof(bool)) !=0)
    {
        close(sockfd);
        close(g_msg_client);
        close(sockfd1);
        close(g_file_client);
        //printf("setsockopt SO_REUSEADDR %s \n",UDT::getlasterror().getErrorMessage());
        return E_LOW_NETWORK_QUALITY;
    }
                 
    if (UDT::ERROR == UDT::bind(g_file_client, sockfd1))
    {
        close(sockfd);
        close(g_msg_client);
        close(sockfd1);
        close(g_file_client);
        //printf("UDT bind failed:%s\n" , UDT::getlasterror().getErrorMessage());
        return E_LOW_NETWORK_QUALITY;
    }    

    if (UDT::ERROR == UDT::connect(g_file_client, (struct sockaddr *)&box_addr,sizeof(box_addr)))
    {
        close(sockfd);
        close(g_msg_client);
        close(sockfd1);
        close(g_file_client);
        //printf("UDT connect failed:%s\n ",UDT::getlasterror().getErrorMessage());
        return E_LOW_NETWORK_QUALITY;
    }
    else
    {
        //printf("connect to client OK\n");
    }
    return 0;
}

int remote_close() {
    close(sockfd);
    close(sockfd1);
    close(g_file_client);
    close(g_msg_client);
}