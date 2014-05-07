//
//  MDAppDelegate.m
//  ddnsDemo_OSX
//
//  Created by Will Zhang on 14-5-5.
//  Copyright (c) 2014年 Will Zhang. All rights reserved.
//

#import "MDAppDelegate.h"
#import "OrayDDNSEngine.h"
#import "IPChinaZEngine.h"
#import "SimplePing.h"

@interface MDAppDelegate ()<SimplePingDelegate>

@property (weak) IBOutlet NSTextFieldCell *domainTFC;
@property (weak) IBOutlet NSTextFieldCell *usernameTFC;
@property (weak) IBOutlet NSSecureTextFieldCell *passwordSTFC;

@property (weak) IBOutlet NSTextFieldCell *IPTFC;
@property (weak) IBOutlet NSTextFieldCell *responseTFC;

@property (weak) IBOutlet NSButton *autoCheckBox;
@property (weak) IBOutlet NSButton *updateBtn;

@property (weak) IBOutlet NSProgressIndicator *activityIndicator;

@property (strong,nonatomic) NSString *localIP;
@property (strong,nonatomic) NSString *hostIP;
@property (strong,nonatomic) NSTimer *autoCheckTimer;

@property (strong,nonatomic) OrayDDNSEngine *orayEngine;
@property (strong,nonatomic) MKNetworkOperation *checkLocalIP;
@property (strong,nonatomic) MKNetworkOperation *updateDNS;

@property (strong,nonatomic) IPChinaZEngine *chinazEngine;
@property (strong,nonatomic) MKNetworkOperation *checkHostIP;
@property (strong,nonatomic) SimplePing *ping;

@property (assign,nonatomic) BOOL shouldAutoCheck;
@end

@implementation MDAppDelegate
- (IBAction)onPingBtn:(id)sender {
    [self pingHost];
}

-(void)autoCheck{
    [self checkLocal];
    [self checkHost];
}
-(void)compareIPLocalToDomain{
    NSLog(@"LOCAL IP:%@ | HOST IP:%@",_localIP,_hostIP);
    if (![_localIP isEqualToString:_hostIP]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_shouldAutoCheck) {
                [self onUpdateBtn:_autoCheckTimer];
                NSLog(@"AUTO UPDATE!");
            }
        });
    }
}
-(void)checkLocal{
    
    _checkLocalIP = [_orayEngine checkLocalIPOnCompletion:^(NSString *currentLocalIP) {
        if (![_localIP isEqualToString:currentLocalIP]) {
            NSLog(@"Local IP changed to %@",currentLocalIP);
            _localIP = currentLocalIP;
            [self compareIPLocalToDomain];
        }else{
            NSLog(@"Local IP did not change.");
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            _IPTFC.title = currentLocalIP;
            if (!_shouldAutoCheck) {
                _updateBtn.enabled = YES;
            }
            _autoCheckBox.enabled = YES;
            [_activityIndicator stopAnimation:nil];
        });
    } onError:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _IPTFC.title = @"Check Local IP Request Failed.";
            [_activityIndicator stopAnimation:nil];
        });
    }];
    
    [_activityIndicator startAnimation:nil];
}
-(void)checkHost{
    NSString *hostname = _domainTFC.title;
    _checkHostIP = [_chinazEngine checkHostIPWithHostname:hostname onCompletion:^(NSDictionary *responseInfo) {
        NSString *message = [responseInfo objectForKey:@"message"];
        NSString *hostIP = [responseInfo objectForKey:@"hostIP"];
        if ([hostIP length] > 0) {
            if (![_hostIP isEqualToString:hostIP]) {
                NSLog(@"Host : %@ IP changed to %@",hostname,hostIP);
                _hostIP = hostIP;
                [self compareIPLocalToDomain];
            }else{
                NSLog(@"Host IP did not change.");
            }
        }else{
            _hostIP = hostIP;
            [self compareIPLocalToDomain];
        }
        NSLog(@"%@",message);
        
        [_activityIndicator stopAnimation:nil];
    } onError:^(NSError *error) {
        NSLog(@"Check IP For HOST : %@ Request Failed With Error : %@",hostname,error);
        [_activityIndicator stopAnimation:nil];
    }];
    
    [_activityIndicator startAnimation:nil];
}
-(void)pingHost{
    NSString *hostname = _domainTFC.title;
    _ping = [SimplePing simplePingWithHostName:hostname];
    _ping.delegate = self;
    [_ping start];
}
-(void)simplePing:(SimplePing *)pinger didStartWithAddress:(NSData *)address{

    [_ping stop];
}
-(void)simplePing:(SimplePing *)pinger didFailWithError:(NSError *)error{
    
    [_ping stop];
}
-(void)simplePing:(SimplePing *)pinger didSendPacket:(NSData *)packet{
    
}
-(void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet{
    
}
-(void)simplePing:(SimplePing *)pinger didReceiveUnexpectedPacket:(NSData *)packet{
    
}
-(void)simplePing:(SimplePing *)pinger didFailToSendPacket:(NSData *)packet error:(NSError *)error{
    
}
-(IBAction)onAutoCheckBox:(NSButton *)sender {
    NSButton *btn = (NSButton *)sender;
//    NSLog(@"%@:%li",@"checkbox pressed",btn.state);
    if (btn.state == 1) {
        _shouldAutoCheck = YES;
        _autoCheckTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(autoCheck) userInfo:nil repeats:YES];
        _updateBtn.enabled = NO;
    }else if (btn.state == 0){
        _shouldAutoCheck = NO;
        [_autoCheckTimer invalidate];
        _updateBtn.enabled = YES;
    }
}
-(IBAction)onCheckBtn:(NSButton *)sender {
    [self checkLocal];
}
-(IBAction)onUpdateBtn:(id)sender {
    NSString *domain = _domainTFC.title;
    [self updateOrayWithIp:_localIP andHostnames:@[domain]];
}
-(void)updateOrayWithIp:(NSString *)ip andHostnames:(NSArray *)hostnames{
    NSDictionary *authorInfo = @{@"username": _usernameTFC.title,@"password": _passwordSTFC.title};
    
    _updateDNS = [_orayEngine updateDNSWithHosts:hostnames IPAdress:ip authorInfo:authorInfo onCompletion:^(NSDictionary *responseInfo) {
        NSString *message = [responseInfo objectForKey:@"message"];
        NSString *toIP = [responseInfo objectForKey:@"toIP"];
        
        if ([toIP length] > 0) {
            _hostIP = toIP;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            _responseTFC.title = message;
            [_activityIndicator stopAnimation:nil];
        });
        
    } onError:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _responseTFC.title = @"Update Oray Request Failed.";
            [_activityIndicator stopAnimation:nil];
        });
    }];
    
    [_activityIndicator startAnimation:nil];
}

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    self.orayEngine = [[OrayDDNSEngine alloc]initWithDefaultSettings];
    [self.orayEngine useCache];
    self.chinazEngine = [[IPChinaZEngine alloc]initWithDefaultSettings];
    [self.chinazEngine useCache];
    
    _shouldAutoCheck = NO;
}

@end
