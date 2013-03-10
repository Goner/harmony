#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "curl.h"

#include "curl_exchange.h"

//http
//����������֤;  
size_t write_data(void *buffer, size_t size, size_t nmemb, void *userp)
{
    size_t nsize=size*nmemb;
    strcat((char *)userp,(char *)buffer);


    return nsize;
}

int exchange_with_mysql(char *url, char *request, char *response)
{
    CURL *curl;   
    CURLcode res; 
    
    printf("request:%s\n", request);
    curl = curl_easy_init();   
    curl_easy_setopt(curl, CURLOPT_URL, url);   
    curl_easy_setopt(curl, CURLOPT_POSTFIELDS, request);   
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_data);   
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, response);   
    curl_easy_setopt(curl, CURLOPT_POST, 1);  //����Ϊ��0��ʾ���β���ΪPOST 
    curl_easy_setopt(curl, CURLOPT_VERBOSE, 0); 
    /*
    HTTP/1.1 200 OK
    Content-Type: text/json; charset=UTF-8
    Content-Type: application/json
    Transfer-Encoding: chunked
    Server: Jetty(6.1.10)
    {"error":"�û����������Ų���Ϊ��","success":"false"}
    */
    curl_easy_setopt(curl, CURLOPT_HEADER, 0); //����Ϊ��0����Ӧͷ��Ϣͬ��Ӧ��һ�𴫸�WRITEFUNCTION
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1);   

    //https����
    /*
    curl_easy_setopt(curl, CURLOPT_SSLCERT, "/mnt/hgfs/work/ca-ssl/client.crt");
    curl_easy_setopt(curl, CURLOPT_SSLCERTPASSWD, "123456");
    //The format of the certificate. Supported formats are "PEM" (default), "DER", and "ENG".
    curl_easy_setopt(curl, CURLOPT_SSLCERTTYPE, "PEM");
    //The name of a file containing a private SSL key.�ͻ��˵�˽Կ
    curl_easy_setopt(curl, CURLOPT_SSLKEY, "/mnt/hgfs/work/ca-ssl/client.key");
    curl_easy_setopt(curl, CURLOPT_SSLKEYPASSWD, "123456");
    //The format of the certificate. Supported formats are "PEM" (default), "DER", and "ENG".
    curl_easy_setopt(curl, CURLOPT_SSLKEYTYPE, "PEM");
    */
    
    /*
    curl_easy_setopt(curl, CURLOPT_CAINFO, "/mnt/hgfs/work/ca-ssl/server.crt");

    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 1L);
    //curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 0L);
    */
    res = curl_easy_perform(curl);  
    curl_easy_cleanup(curl); 

    return 0;
}


