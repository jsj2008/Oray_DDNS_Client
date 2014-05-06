//
//  OrayDDNSEngine.m
//  ddnsDemo_OSX
//
//  Created by Will Zhang on 14-5-6.
//  Copyright (c) 2014年 Will Zhang. All rights reserved.
//

#import "OrayDDNSEngine.h"
#define UPDATE_URL(HOSTS,IP) [NSString stringWithFormat:@"ph/update?hostname=%@&myip=%@",HOSTS,IP]

@implementation OrayDDNSEngine

-(instancetype)initWithDefaultSettings {
    
    if(self = [super initWithHostName:@"ddns.oray.com" customHeaderFields:@{@"User-Agent" : @"Oray"}]) {
        
    }
    return self;
}

-(MKNetworkOperation *)checkCurrentIPOnCompletion:(CurrentIPBlock)completionBlock onError:(ErrorBlock)errorBlock{
    MKNetworkOperation *operation = [self operationWithPath:@"checkip"];
    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation)
     {

         NSString *str = [completedOperation responseString];
         NSRange headRange = [str rangeOfString:@": "];
         NSRange tailRange = [str rangeOfString:@"</body>"];
         NSUInteger location = headRange.location+headRange.length;
         NSUInteger length = tailRange.location - location;
         NSRange ipRange = NSMakeRange(location, length);
         NSString *ipStr = [str substringWithRange:ipRange];
         
         completionBlock(ipStr);
         
     }errorHandler:^(MKNetworkOperation *errorOp, NSError* error) {
         
         errorBlock(error);
     }];
    
    [self enqueueOperation:operation];
    return operation;
}

-(MKNetworkOperation *)updateDNSWithHosts:(NSArray *)hosts IPAdress:(NSString *)IP authorInfo:(NSDictionary *)info onCompletion:(UpdateResoponseBlock)completionBlock onError:(ErrorBlock)errorBlock{
    
    NSString *hostStr = @"";

    if ([hosts count] == 1) {
        hostStr = (NSString *)(hosts[0]);
    }else if([hosts count] > 1){
        hostStr = [hosts componentsJoinedByString:@","];
    }

    NSString *username = [info objectForKey:@"username"];
    NSString *password = [info objectForKey:@"password"];

    
    MKNetworkOperation *operation = [self operationWithPath:UPDATE_URL(hostStr,IP)];
    
    
    [operation setUsername:username password:password];
    
    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation)
     {
 //////////////////////////////////////////////////////////////////////////////////////////////////////
 //      good        更新成功    域名的IP地址已经更新，同时会返回本次更新成功的IP，用空格隔开，如：good 1.2.3.4  //
 //      nochg       更新成功    但没有改变IP。一般这种情况为本次提交的IP跟上一次的一样                        //
 //      notfqdn     未有激活花生壳的域名                                                               //
 //      nohost      域名不存在或未激活花生壳                                                            //
 //      abuse       请求失败    频繁请求或验证失败时会出现                                                //
 //      !donator	表示此功能需要付费用户才能使用 如https                                                //
 //      911         系统错误                                                                         //
 //////////////////////////////////////////////////////////////////////////////////////////////////////
         NSDictionary *responseInfo;
         NSString *response = [completedOperation responseString];
         NSString *message;
         NSString *toIP = @"";
         if ([response rangeOfString:@"good"].length > 0) {
             toIP = [response componentsSeparatedByString:@" "][1];
             message =  [response stringByReplacingOccurrencesOfString:@"good" withString:@"更新成功"];
             
         }else if ([response rangeOfString:@"nochg"].length > 0) {
             toIP = IP;
             message =  @"更新成功,但没有改变IP";
             
         }else if ([response rangeOfString:@"notfqdn"].length > 0) {
             
             message =  @"未有激活花生壳的域名";
             
         }else if ([response rangeOfString:@"nohost"].length > 0) {
             
             message =  @"域名不存在或未激活花生壳";
             
         }else if ([response rangeOfString:@"abuse"].length > 0) {
             
             message =  @"请求失败,频繁请求或验证失败时会出现";
             
         }else if ([response rangeOfString:@"!donator"].length > 0) {
             
             message =  @"表示此功能需要付费用户才能使用 如https";
             
         }else if ([response rangeOfString:@"911"].length > 0) {
             
             message =  @"系统错误";
             
         }else if ([response rangeOfString:@"badauth"].length > 0) {
             
             message =  @"用户名或密码错误";
             
         }
         
         responseInfo = @{@"message": message,@"toIP": toIP};
         
         completionBlock(responseInfo);
         
     }errorHandler:^(MKNetworkOperation *errorOp, NSError* error) {
         errorBlock(error);
     }];
    
    [self enqueueOperation:operation];
    return operation;
}

@end
