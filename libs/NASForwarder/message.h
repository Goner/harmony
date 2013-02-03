#ifndef MESSAGE_H
#define MESSAGE_H

#define MAX_TORRENT_FILENAME_SIZE 128
#define MAX_USERNAME_SIZE 32
#define MAX_SERIALNUM_SIZE 64
#define MAX_PASSWD_SIZE 32
#define MAX_MAC_SIZE 20
#define MAX_IP_SIZE 20

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

#define SERVERIP "202.85.216.203"
#define SERVERPORT 9100
#define CLIENT_LOCAL_PORT 9002

#pragma pack(push)
#pragma pack(1)
 //������Ϣ
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

//client����balance������ͨ����Ϣ c:�ͻ��� s:balance������ b:����box
struct build_channel_c2s_message
{
	char mac[MAX_MAC_SIZE];
};

//balance����client,������ͨ��������Ϣ
struct build_channel_s2c_message
{
	int online_flag; //0:���Ӳ����� 1:��������
	char box_ip[MAX_IP_SIZE];
	int box_port;
};

//balance��������box���ͻ���������ͨ������Ϣ
struct make_hole_s2b_message
{
	char client_ip[MAX_IP_SIZE];
	int client_port;
};

//box����blance���ͻ���������ͨ���򶴷�����Ϣ-���а����ö�Ӧ�÷����Ŀͻ���IP�˿�
struct make_hole_b2s_message
{
	char client_ip[MAX_IP_SIZE];
	int client_port;
};

//balance���ڶ�������������Ϣ���ظ�����
struct make_hole_b2s_ack_message
{
	char outer_ip[MAX_IP_SIZE];
	int outer_port;
};

//blance�����������������ļ������
struct make_torrent_hole_s2b_message
{
	int flag;
};

//��ֹUDP������ACK��Ϣ�������ղŷ�����Ϣ����Ϣ����
struct ack_message
{
	int message_type;
};

//ȡ�����ѹ���
struct cancel_friend_sharing_message
{
	char torrent_filename[MAX_TORRENT_FILENAME_SIZE];
};
#pragma pack(pop)

int judge_message_size(char msg_type);
void * recv_message(void * arg);
int build_channel(struct build_channel_c2s_message build_channel_msg, struct build_channel_s2c_message &build_channel_ack_msg);
int myclose(int sockfd);
int mysendto(int sockfd, char *buff, int len, int flag, struct sockaddr *addr);
int init();
#endif 