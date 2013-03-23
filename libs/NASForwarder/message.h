#ifndef MESSAGE_H
#define MESSAGE_H

#define MAX_TORRENT_FILENAME_SIZE 128
#define MAX_USERNAME_SIZE 32
#define MAX_SERIALNUM_SIZE 64
#define MAX_PASSWD_SIZE 32
#define MAX_MAC_SIZE 20
#define MAX_IP_SIZE 20
#define MAX_TOKEN_SIZE 128
#define MAX_PACKET_SIZE 4000

#define MSG_HEARTBEAT 100
#define MSG_HEARTBEAT_ACK 101
#define MSG_BUILD_CHANNEL_C2S 102
#define MSG_BUILD_CHANNEL_S2C 103
#define MSG_MAKE_HOLE_S2B 104
#define MSG_MAKE_HOLE_B2S 105
#define MSG_MAKE_HOLE_B2S_ACK 106
#define MSG_ACK 107
#define MSG_TORRENT 108
#define MSG_MAKE_TORRENT_HOLE_S2B 109
#define MSG_MAKE_HOLE_EMPTY_PACKET 110
#define MSG_CANCEL_FRIEND_SHARING 111

#pragma pack(push)
#pragma pack(1)
 //心跳消息
struct heartbeat_message
{
	char username[MAX_USERNAME_SIZE];	     
	char serialnum[MAX_SERIALNUM_SIZE];  
	char mac[MAX_MAC_SIZE];          
	char outer_ip[MAX_IP_SIZE];
	int outer_port;
};

struct heartbeat_ack_message
{
	char outer_ip[MAX_IP_SIZE];
	int outer_port;
};

//用户外网登录
struct outer_login_message
{
    char username[MAX_USERNAME_SIZE];
    char password[MAX_PASSWD_SIZE];
};

//用户外网登录返回信息
struct outer_login_ack_message
{
	int flag; //0::失败 1:成功
	char token[MAX_TOKEN_SIZE]; // 返回的令牌
	char serialnum[MAX_SERIALNUM_SIZE];
};

//client发往balance请求建立通道消息 c:客户端 s:balance服务器 b:盒子box
struct build_channel_c2s_message
{
	char username[MAX_USERNAME_SIZE];	     
	char serialnum[MAX_SERIALNUM_SIZE]; 
	char token[MAX_TOKEN_SIZE];
	int flag;   // 1:建立传输消息通道 2:建立传输文件通道
};

//balance发往client,请求建立通道返回消息
struct build_channel_s2c_message
{
	int status; //0:盒子不在线 1:盒子在线 2:令牌无效
	char box_ip[MAX_IP_SIZE];
	int box_port;
};
//balance发往盒子box，客户端请求建立通道打洞消息
struct make_hole_s2b_message
{
	char client_ip[MAX_IP_SIZE];
	int client_port;
	int flag;   // 1:建立传输消息通道 2:建立传输文件通道
};

//box发往blance，客户端请求建立通道打洞返回消息-其中包含该洞应该发往的客户端IP端口
struct make_hole_b2s_message
{
	char client_ip[MAX_IP_SIZE];
	int client_port;
};

//balance将第二个洞的外网信息返回给盒子
struct make_hole_b2s_ack_message
{
	char outer_ip[MAX_IP_SIZE];
	int outer_port;
};

//blance发给盒子请求种子文件传输打洞
struct make_torrent_hole_s2b_message
{
	int flag;
};

//防止UDP丢包，ACK消息，包含刚才发送消息的消息类型
struct ack_message
{
	int message_type;
};

//取消好友共享
struct cancel_friend_sharing_message
{
	char torrent_filename[MAX_TORRENT_FILENAME_SIZE];
};
#pragma pack(pop)
#define SERVERIP "202.85.216.203" //"10.1.8.253"

#endif 

