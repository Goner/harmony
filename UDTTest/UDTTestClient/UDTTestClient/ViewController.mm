//
//  ViewController.m
//  UDTTestClient
//
//  Created by wang zhenbin on 3/1/13.
//  Copyright (c) 2013 24601. All rights reserved.
//

#import "ViewController.h"
#import "udt.h"
#import "netdb.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction) startUDTTest
{
    UDTSOCKET s = UDT::socket(AF_INET, SOCK_STREAM, 0);
    //for ios reset buf size
    int snd_buf = 64000;
    int rcv_buf = 64000;
    UDT::setsockopt(s, 0, UDT_SNDBUF, &snd_buf, sizeof(int));
    UDT::setsockopt(s, 0, UDT_RCVBUF, &rcv_buf, sizeof(int));
    snd_buf = 64000;
    rcv_buf = 64000;
    UDT::setsockopt(s, 0, UDP_SNDBUF, &snd_buf, sizeof(int));
    UDT::setsockopt(s, 0, UDP_RCVBUF, &rcv_buf, sizeof(int));
    
    struct addrinfo hints;
    memset(&hints, 0, sizeof(struct addrinfo));
    struct addrinfo *result;
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_PASSIVE;
    
    getaddrinfo("192.168.1.100", "9000", &hints, &result);
    
    if(UDT::ERROR == UDT::connect(s,result->ai_addr, result->ai_addrlen)){
        NSLog(@"Failed to connect to server");
    }
    
    int size = 0x67989;
    UDT::send(s, (char*)&size, sizeof(int), 0);
    
    int pos = 0;
    char buf[1024];
    while (pos < size) {
        int send_size = std::min(size-pos, 1024);
        send_size =  UDT::send(s, buf, send_size, 0);
        printf("sent size is %x", send_size);
        pos += send_size;
    }
    
    UDT::close(s);
    
    
}

@end
