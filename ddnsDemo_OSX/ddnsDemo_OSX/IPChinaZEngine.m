//
//  IPChinaZEngine.m
//  ddnsDemo_OSX
//
//  Created by Will Zhang on 14-5-7.
//  Copyright (c) 2014年 Will Zhang. All rights reserved.
//

#import "IPChinaZEngine.h"

@implementation IPChinaZEngine
-(instancetype)initWithDefaultSettings {
    
    if(self = [super initWithHostName:@"ip.chinaz.com"]) {
        
    }
    return self;
}

-(MKNetworkOperation *)checkHostIPWithHostname:(NSString *)hostname onCompletion:(HostIPBlock)completionBlock onError:(ErrorBlock)errorBlock{
    MKNetworkOperation *operation = [self operationWithPath:[NSString stringWithFormat:@"?IP=%@",hostname]];
    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation)
     {
         __block NSDictionary *responseInfo;
         NSString *str = [completedOperation responseString];
         
         NSRange headRange = [str rangeOfString:@"查询结果"];
         NSRange tailRange = [str rangeOfString:@"==>>"];
         NSRange IPRange = NSMakeRange(headRange.location+headRange.length+5, tailRange.location-headRange.location-10);
         NSString *hostIP = [str substringWithRange:IPRange];
         
         NSArray *checkArr = [hostIP componentsSeparatedByString:@"."];
         if ([checkArr count] == 4) {
             BOOL validIP = YES;
             for (NSString *part in checkArr) {
                 if ([part integerValue] > 255) {
                     validIP = NO;
                 }
             }
             if (validIP) {
                responseInfo = @{@"message": @"获取域名对应IP成功",@"hostIP": hostIP};
             }else{
                responseInfo = @{@"message": @"获取到的IP地址非法",@"hostIP": @""};
             }
         }else{
                responseInfo = @{@"message": @"未获取到域名对应IP",@"hostIP": @""};
         }
         
         completionBlock(responseInfo);
         
     }errorHandler:^(MKNetworkOperation *errorOp, NSError* error) {
         
         errorBlock(error);
     }];
    
    [self enqueueOperation:operation];
    return operation;
}

@end
