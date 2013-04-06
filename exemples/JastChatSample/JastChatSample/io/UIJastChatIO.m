//
//  UIJastChatIO.m
//  JastChatSample
//
//  Created by adelskott on 06/04/13.
//  Copyright (c) 2013 adelskott. All rights reserved.
//

#import "UIJastChatIO.h"
#import "SocketIOPacket.h"
#import "SocketIOJSONSerialization.h"

static UIJastChatIO* UIJastChatIO_instance = nil;


@implementation UIJastChatIO

+(UIJastChatIO*)getInstance{
    if (!UIJastChatIO_instance)
        UIJastChatIO_instance = [UIJastChatIO new];
    return UIJastChatIO_instance;
}


-(void)socketconnect{
    socketIO = [[SocketIO alloc] initWithDelegate:self];
    [socketIO connectToHost:@"localhost" onPort:80 withParams:nil withNamespace:@"/ns"];
}

- (void) socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error{
    if(run){
        [self performSelector:@selector(socketconnect) withObject:nil afterDelay:2];
    }else{
        socketIO.delegate = nil;
        socketIO = nil;
    }
}

- (void) socketIO:(SocketIO *)socket onError:(NSError *)error{
    [self performSelector:@selector(socketconnect) withObject:nil afterDelay:2];
}


- (void) socketIODidConnect:(SocketIO *)socket{
    NSLog(@"Connected");
    [self connectChannel:@"peoplelist" getold:YES];
}

-(void)connectChannel:(NSString*)channel getold:(BOOL)getold{
    NSDictionary *dict = @{@"client":_clientid, @"key": _key, @"app":_appid,@"channel":channel};
    [socketIO sendEvent:@"psubscribe" withData:dict];
}

- (void) socketIO:(SocketIO *)socket didReceiveEvent:(SocketIOPacket *)packet{
    NSLog(@"%@",packet.data);
    NSDictionary *d = [packet dataAsJSON];
    NSString *str = nil;
    if (d){
        NSArray *ar = d[@"args"];
        if ([ar count])
            str = ar[0];
    }
    
    NSData *utf8Data = [str dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *json = [SocketIOJSONSerialization objectFromJSONData:utf8Data error:nil];
    NSString *channel = json[@"channel"];
    NSDictionary *dic = json[@"data"];
    
    if (callbacks[channel]){
        void(^rep)(NSDictionary* rep) = callbacks[channel];
        rep(dic);
    }
}
-(void)listen:(NSString*)channel cb:(void(^)(NSDictionary* rep))cb{
    if (!callbacks) {
        callbacks = [NSMutableDictionary new];
    }
    if (cb)
        [callbacks setObject:[cb copy] forKey:channel];
    else
        [callbacks removeObjectForKey:channel];
        
}
-(void)sendmessage:(NSString*)channel message:(id)message{
    NSDictionary *dict = @{@"client":_clientid, @"key": _key, @"app":_appid,@"channel":channel,@"message":message};
    [socketIO sendEvent:@"publish" withData:dict];
}
@end
