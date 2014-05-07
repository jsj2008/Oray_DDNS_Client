//
//  IPChinaZEngine.h
//  ddnsDemo_OSX
//
//  Created by Will Zhang on 14-5-7.
//  Copyright (c) 2014年 Will Zhang. All rights reserved.
//

#import "MKNetworkEngine.h"
typedef void (^HostIPBlock)(NSDictionary *responseInfo);
typedef void (^ErrorBlock)(NSError* error);



@interface IPChinaZEngine : MKNetworkEngine
-(instancetype)initWithDefaultSettings;
-(MKNetworkOperation *)checkHostIPWithHostname:(NSString *)hostname onCompletion:(HostIPBlock)completionBlock onError:(ErrorBlock)errorBlock;

@end
