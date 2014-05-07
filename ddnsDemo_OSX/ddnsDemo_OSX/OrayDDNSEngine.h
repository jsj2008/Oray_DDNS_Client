//
//  OrayDDNSEngine.h
//  ddnsDemo_OSX
//
//  Created by Will Zhang on 14-5-6.
//  Copyright (c) 2014年 Will Zhang. All rights reserved.
//

#import "MKNetworkEngine.h"

typedef void (^LocalIPBlock)(NSString *LocalIP);
typedef void (^UpdateResoponseBlock)(NSDictionary *responseInfo);
typedef void (^ErrorBlock)(NSError* error);

@interface OrayDDNSEngine : MKNetworkEngine

-(instancetype)initWithDefaultSettings;
-(MKNetworkOperation *)checkLocalIPOnCompletion:(LocalIPBlock)completionBlock onError:(ErrorBlock)errorBlock;
-(MKNetworkOperation *)updateDNSWithHosts:(NSArray *)hosts IPAdress:(NSString *)IP authorInfo:(NSDictionary *)info onCompletion:(UpdateResoponseBlock)completionBlock onError:(ErrorBlock)errorBlock;

@end
