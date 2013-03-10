#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "cJSON.h"
#include "parsewebjson.h"

int filter_response(char *src_response, char *dst_response)
{
    char *head = NULL;
    char *tail = NULL;

    //���ַ���s�������ַ�c�����������������ָ��ָ���ַ�c��һ�γ��ֵ�λ�ã����򷵻�NULL��
    head = strchr(src_response, '{');
    if (head ==NULL)
    {
        return -1;
    }
    tail = strrchr(src_response, '}');
    if (tail == NULL)
    {
        return -1;
    }
    memcpy(dst_response, head, tail - head + 1);

    return 0;
}

/*�ɹ�����0��ʧ�ܷ���-1*/
int parse_web_login(char *json_response, struct outer_login_ack_message &ack_msg)
{
    cJSON *root = NULL;
    cJSON *result = NULL;   
    cJSON *error = NULL;  
    cJSON *token = NULL;  
    cJSON *sn    = NULL;
    
    root= cJSON_Parse(json_response);
    if (root != NULL)
    {
        //�ж��Ƿ���Ҫ����
        result = cJSON_GetObjectItem(root, "success");
        if (result != NULL)
        {
            if (strcmp(result->valuestring, "false") == 0)
            {
                //ʧ�ܵ�ʱ�����������Ϣ
                ack_msg.flag = 0;
                error = cJSON_GetObjectItem(root, "error");
                if (error != NULL)
                {
                    printf("login failed error:%s\n", error->valuestring);
                }
            }
            else if (strcmp(result->valuestring, "true") == 0)
            {
                //��¼��֤�ɹ�
                token = cJSON_GetObjectItem(root, "token");
                sn    = cJSON_GetObjectItem(root, "box_sn");
                ack_msg.flag = 1;
                strcpy(ack_msg.token, token->valuestring);
                strcpy(ack_msg.serialnum, sn->valuestring);
                printf("login ok login_ack.flag:%d token:%s sn:%s\n", ack_msg.flag, ack_msg.token, ack_msg.serialnum);
            }
        }
        else
        {
            return -1;
        }
    }
    
    return 0;
}
