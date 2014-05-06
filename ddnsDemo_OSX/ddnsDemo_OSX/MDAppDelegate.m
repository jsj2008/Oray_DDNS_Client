//
//  MDAppDelegate.m
//  ddnsDemo_OSX
//
//  Created by Will Zhang on 14-5-5.
//  Copyright (c) 2014年 Will Zhang. All rights reserved.
//

#import "MDAppDelegate.h"
#import "OrayDDNSEngine.h"

@interface MDAppDelegate ()
@property (weak) IBOutlet NSTextFieldCell *domainTFC;
@property (weak) IBOutlet NSTextFieldCell *usernameTFC;
@property (weak) IBOutlet NSSecureTextFieldCell *passwordSTFC;

@property (weak) IBOutlet NSTextFieldCell *IPTFC;
@property (weak) IBOutlet NSTextFieldCell *responseTFC;

@property (weak) IBOutlet NSButton *autoCheckBox;
@property (weak) IBOutlet NSButton *updateBtn;

@property (weak) IBOutlet NSProgressIndicator *activityIndicator;

@property (strong,nonatomic) NSString *currentIp;
@property (strong,nonatomic) NSString *lastIp;
@property (strong,nonatomic) NSTimer *autoCheckTimer;

@property (strong,nonatomic) OrayDDNSEngine *engine;
@property (strong,nonatomic) MKNetworkOperation *checkIP;
@property (strong,nonatomic) MKNetworkOperation *updateDNS;

@end

@implementation MDAppDelegate


- (IBAction)onAutoCheckBox:(NSButton *)sender {
    NSButton *btn = (NSButton *)sender;
//    NSLog(@"%@:%li",@"checkbox pressed",btn.state);
    if (btn.state == 1) {
        _autoCheckTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(autoCheck) userInfo:nil repeats:YES];
        _updateBtn.enabled = NO;
    }else if (btn.state == 0){
        [_autoCheckTimer invalidate];
        _updateBtn.enabled = YES;
    }
}
- (IBAction)onCheckBtn:(NSButton *)sender {
    [self checkIp];
}
- (IBAction)onUpdateBtn:(id)sender {
    NSString *domain = _domainTFC.title;
    [self updateOrayWithIp:_currentIp andHostnames:@[domain]];
}
-(void)checkIp{
    
    _checkIP = [_engine checkCurrentIPOnCompletion:^(NSString *currentIP) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _IPTFC.title = currentIP;
            _currentIp = currentIP;
            _updateBtn.enabled = YES;
            _autoCheckBox.enabled = YES;
            [_activityIndicator stopAnimation:nil];
        });
    } onError:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _IPTFC.title = @"Check IP Request Failed.";
            [_activityIndicator stopAnimation:nil];
        });
    }];

    [_activityIndicator startAnimation:nil];
}
-(void)autoCheck{
    NSLog(@"currentIP:%@\nlastIP:%@",_currentIp,_lastIp);
    if (![_currentIp isEqualToString:_lastIp]) {
        [self onUpdateBtn:_autoCheckTimer];
        NSLog(@"AUTO UPDATE!");
    }
}
-(void)updateOrayWithIp:(NSString *)ip andHostnames:(NSArray *)hostnames{
    NSDictionary *authorInfo = @{@"username": _usernameTFC.title,@"password": _passwordSTFC.title};
    
    _updateDNS = [_engine updateDNSWithHosts:hostnames IPAdress:ip authorInfo:authorInfo onCompletion:^(NSDictionary *responseInfo) {
        NSString *message = [responseInfo objectForKey:@"message"];
        NSString *toIP = [responseInfo objectForKey:@"toIP"];
        
        if ([toIP length] > 0) {
            _lastIp = toIP;
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

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    self.engine = [[OrayDDNSEngine alloc]initWithDefaultSettings];
    [self.engine useCache];
}

@end
