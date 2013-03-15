#ifndef REMOTEAUTH_H
#define REMOTEAUTH_H

void mysleep(int i);
int mysocket();
int mybind(int listenfd, int port);

int myrecvfrom(int sockfd, char *buff, int len, int flag, struct sockaddr *addr);

int mysendto(int sockfd, char *buff, int len, int flag, struct sockaddr *addr);
int myclose(int sockfd);
int init();
int init1();
int build_channel(int socketfd, int port, struct build_channel_c2s_message build_channel_msg, struct build_channel_s2c_message &build_channel_ack_msg);
int user_outer_login(struct outer_login_message msg, struct outer_login_ack_message &ack_msg);
int remote_auth(char *user,char *pwd, char (&ipAddress)[16]);

#endif