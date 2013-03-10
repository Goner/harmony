#ifndef PARSEWEBJSON_H
#define PARSEWEBJSON_H

#include "message.h"

int filter_response(char *src_response, char *dst_response);
int parse_web_login(char *json_response, struct outer_login_ack_message &outerlogin_ack_msg);

#endif

