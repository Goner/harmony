//
//  main.cpp
//  UDTTestServer
//
//  Created by wang zhenbin on 3/1/13.
//  Copyright (c) 2013 24601. All rights reserved.
//

#include <arpa/inet.h>
#include "udt.h"
#include <iostream>

using namespace std;

int main()
{
    UDTSOCKET serv = UDT::socket(AF_INET, SOCK_STREAM, 0);
    
    sockaddr_in my_addr;
    my_addr.sin_family = AF_INET;
    my_addr.sin_port = htons(9000);
    my_addr.sin_addr.s_addr = INADDR_ANY;
    memset(&(my_addr.sin_zero), '\0', 8);
    
    int bufSize = 640000;
    UDT::setsockopt(serv, 0, UDP_RCVBUF, &bufSize, sizeof(int));
    UDT::setsockopt(serv, 0, UDP_SNDBUF, &bufSize, sizeof(int));
    UDT::setsockopt(serv, 0, UDT_RCVBUF, &bufSize, sizeof(int));
    UDT::setsockopt(serv, 0, UDT_SNDBUF, &bufSize, sizeof(int));
    
    if (UDT::ERROR == UDT::bind(serv, (sockaddr*)&my_addr, sizeof(my_addr)))
    {
        cout << "bind: " << UDT::getlasterror().getErrorMessage();
        return 0;
    }
    
    UDT::listen(serv, 10);
    
    int namelen;
    sockaddr_in their_addr;
    for(;;){
        UDTSOCKET recver = UDT::accept(serv, (sockaddr*)&their_addr, &namelen);
        
        char ip[16];
        cout << "new connection: " << inet_ntoa(their_addr.sin_addr) << ":" << ntohs(their_addr.sin_port) << endl;
        
        char data[1024];
        
        if (UDT::ERROR == UDT::recv(recver, data, 4, 0))
        {
            cout << "recv:" << UDT::getlasterror().getErrorMessage() << endl;
            return 0;
        }
        
        int size = *(int*)data;
        cout << hex;
        cout << data << " " << size << endl;
        
        int package_num = 0;
        int cur_data_size = 0;
        while (cur_data_size < size){
            int recv_size = UDT::recv(recver, data, 1024, 0);
            if( UDT::ERROR == recv_size) {
                cout << "Error occus at receiv package " << package_num << endl;
                break;
            }
            cout << "received " << package_num << "packages. received size " << recv_size << endl;
            ++package_num;
            cur_data_size += recv_size;
        }
        

        UDT::close(recver);
    }
    UDT::close(serv);
    
    return 1;
}

