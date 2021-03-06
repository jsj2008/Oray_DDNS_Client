//
//  MDViewController.m
//  ddnsDemo
//
//  Created by Will Zhang on 14-5-5.
//  Copyright (c) 2014年 Will Zhang. All rights reserved.
//

#import "MDViewController.h"
#import "ASIHTTPRequest.h"
#import "SimplePing.h"

@interface MDViewController () <SimplePingDelegate>
@property (weak, nonatomic) IBOutlet UILabel *ipLabel;
@property (strong,nonatomic) NSString *currentIp;
@property (strong,nonatomic) NSString *lastIp;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *domainTextField;
@property (weak, nonatomic) IBOutlet UIButton *updateBtn;
@property (weak, nonatomic) IBOutlet UILabel *updateResponseLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UISwitch *autoSwitch;
@property (strong,nonatomic) NSTimer *autoCheckTimer;
@property (weak, nonatomic) IBOutlet UIButton *checkHostBtn;
@property (strong,nonatomic) SimplePing *ping;
@end

@implementation MDViewController

#pragma mark - Actions
- (IBAction)handleAutoSwitch:(UISwitch *)sender {
    if (sender.isOn) {
        _autoCheckTimer = [NSTimer scheduledTimerWithTimeInterval:600 target:self selector:@selector(autoCheck) userInfo:nil repeats:YES];
        _updateBtn.enabled = NO;
    }else{
        [_autoCheckTimer invalidate];
        _updateBtn.enabled = YES;
    }
}

- (IBAction)onCheckBtn:(id)sender {
    [self checkIp];
}

- (IBAction)onUpdateBtn:(id)sender {
    NSString *domain = _domainTextField.text;
    [self updateOrayWithIp:_currentIp andHostnames:@[domain]];
}

#pragma mark - Network Activities
-(void)checkIp{
    NSString *checkUrlStr = @"http://ddns.oray.com/checkip";
    NSURL *checkUrl = [NSURL URLWithString:checkUrlStr];
    __weak ASIHTTPRequest *request = [[ASIHTTPRequest alloc]initWithURL:checkUrl];
    [request setTimeOutSeconds:30];
    [request setCompletionBlock:^{
        if (request.responseStatusCode == 200) {
            NSString *str = request.responseString;
            NSRange headRange = [str rangeOfString:@": "];
            NSRange tailRange = [str rangeOfString:@"</body>"];
            NSUInteger location = headRange.location+headRange.length;
            NSUInteger length = tailRange.location - location;
            NSRange ipRange = NSMakeRange(location, length);
            NSString *ipStr = [str substringWithRange:ipRange];
            dispatch_async(dispatch_get_main_queue(), ^{
                _ipLabel.text = ipStr;
                _currentIp = ipStr;
                _updateBtn.enabled = YES;
                _autoSwitch.enabled = YES;
                [_activityIndicator stopAnimating];
            });
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                _ipLabel.text = @"公网IP查询失败";
                [_activityIndicator stopAnimating];
            });
        }
    }];
    [request setFailedBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            _ipLabel.text = @"Check IP Request Failed.";
            [_activityIndicator stopAnimating];
        });
    }];
    [request startAsynchronous];
    [_activityIndicator startAnimating];
}
-(void)pingHost{
    NSString *hostname = _domainTextField.text;
    _ping = [SimplePing simplePingWithHostName:hostname];
    _ping.delegate = self;
    [_ping start];
    [_activityIndicator startAnimating];
}
//-(void)checkHost{
//    NSString *urlStr = [NSString stringWithFormat:@"http://ip.chinaz.com/?IP=%@",_domainTextField.text];
//    NSURL *url = [NSURL URLWithString:urlStr];
//    __block ASIHTTPRequest *request = [[ASIHTTPRequest alloc]initWithURL:url];
//    [request setTimeOutSeconds:30];
//    [request setCompletionBlock:^{
//        if (request.responseStatusCode == 200) {
//            NSString *str = request.responseString;
//            NSRange headRange = [str rangeOfString:@"查询结果"];
//            NSRange tailRange = [str rangeOfString:@"==>>"];
//
//            NSRange IPRange = NSMakeRange(headRange.location+headRange.length+5, tailRange.location-headRange.location-10);
//            NSString *hostIP = [str substringWithRange:IPRange];
//            NSArray *checkArr = [hostIP componentsSeparatedByString:@"."];
//            if ([checkArr count] == 4) {
//                BOOL validIP = YES;
//                for (NSString *part in checkArr) {
//                    if ([part integerValue] > 255) {
//                        validIP = NO;
//                    }
//                }
//                if (validIP) {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [_checkHostBtn setTitle:hostIP forState:UIControlStateNormal];
//                        [_activityIndicator stopAnimating];
//                    });
//                }else{
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [_checkHostBtn setTitle:@"获取域名对应IP失败" forState:UIControlStateNormal];
//                        [_activityIndicator stopAnimating];
//                    });
//                }
//            }else{
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [_checkHostBtn setTitle:@"获取域名对应IP失败" forState:UIControlStateNormal];
//                    [_activityIndicator stopAnimating];
//                });
//            }
//        }else{
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [_checkHostBtn setTitle:@"获取域名对应IP失败" forState:UIControlStateNormal];
//                [_activityIndicator stopAnimating];
//            });
//        }
//    }];
//    [request setFailedBlock:^{
//        dispatch_async(dispatch_get_main_queue(), ^{
//            _ipLabel.text = @"Check Host Request Failed.";
//            [_activityIndicator stopAnimating];
//        });
//    }];
//    [request startAsynchronous];
//    [_activityIndicator startAnimating];
//}
-(void)autoCheck{
    [self checkIp];
    [self pingHost];
}
-(void)compareIPLocalToDomain{
    NSLog(@"currentIP:%@\nlastIP:%@",_currentIp,_lastIp);
    if (![_currentIp isEqualToString:_lastIp]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self onUpdateBtn:_autoCheckTimer];
            NSLog(@"AUTO UPDATE!");
        });
    }
}
-(void)updateOrayWithIp:(NSString *)ip andHostnames:(NSArray *)hostnames{
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //      good        更新成功    域名的IP地址已经更新，同时会返回本次更新成功的IP，用空格隔开，如：good 1.2.3.4      //
    //      nochg       更新成功    但没有改变IP。一般这种情况为本次提交的IP跟上一次的一样                            //
    //      notfqdn     未有激活花生壳的域名                                                                   //
    //      nohost      域名不存在或未激活花生壳                                                                //
    //      abuse       请求失败    频繁请求或验证失败时会出现                                                    //
    //      !donator	表示此功能需要付费用户才能使用 如https                                                   //
    //      911         系统错误                                                                             //
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    NSString *updateUrlStr = [NSString stringWithFormat:@"http://ddns.oray.com/ph/update?hostname=%@&myip=%@",hostnames[0],ip];
    NSURL *updateUrl = [NSURL URLWithString:updateUrlStr];
    __weak ASIHTTPRequest *request = [[ASIHTTPRequest alloc]initWithURL:updateUrl];
    [request setUsername:_usernameTextField.text];
    [request setPassword:_passwordTextField.text];
    [request setTimeOutSeconds:30];
    [request setCompletionBlock:^{
        if (request.responseStatusCode == 200) {
            NSString *response = request.responseString;
            NSString *message;
            if ([response rangeOfString:@"good"].length > 0) {
                _lastIp = [response componentsSeparatedByString:@" "][1];
                message =  [response stringByReplacingOccurrencesOfString:@"good" withString:@"更新成功"];
                
            }else if ([response rangeOfString:@"nochg"].length > 0) {
                _lastIp = _currentIp;
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
            dispatch_queue_t loaderQ = dispatch_queue_create("queuesymbol", NULL);
            dispatch_async(loaderQ, ^{
                //do whatever you want here
                
                //go back to main thread (Required for updating UIViews)
                dispatch_async(dispatch_get_main_queue(), ^{
                    //do whatever you want here
                    _updateResponseLabel.text = message;
                    [_activityIndicator stopAnimating];
                });
            });
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                //do whatever you want here
                _updateResponseLabel.text = @"更新请求失败";
                [_activityIndicator stopAnimating];
            });
        }
    }];
    
    [request setFailedBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            _updateResponseLabel.text = @"Update Oray Request Failed.";
            [_activityIndicator stopAnimating];
        });
    }];
    
    [request startAsynchronous];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_activityIndicator startAnimating];
    });
}

#pragma mark - View Controller Life Cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    UITapGestureRecognizer *tapOnView = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTapOnView:)];
    [self.view addGestureRecognizer:tapOnView];
    
}
-(void)handleTapOnView:(id)sender{
    [_usernameTextField resignFirstResponder];
    [_passwordTextField resignFirstResponder];
    [_domainTextField resignFirstResponder];
}




#pragma mark - SimplePing Delegate methods
-(void)simplePing:(SimplePing *)pinger didStartWithAddress:(NSData *)address{
    [_ping stop];

    NSString *hostname = _domainTextField.text;
    NSString *hostIP = [_ping getIPFromData:address];
    if ([hostIP length] > 0) {
        if (![_currentIp isEqualToString:hostIP]) {
            NSLog(@"Host : %@ IP changed to %@",hostname,hostIP);
            _currentIp = hostIP;
            [self compareIPLocalToDomain];
        }else{
            NSLog(@"Host IP did not change.%@",hostIP);
        }
    }else{
        _currentIp = hostIP;
        [self compareIPLocalToDomain];
    }
    [_checkHostBtn setTitle:hostIP forState:UIControlStateNormal];
    [_activityIndicator stopAnimating];
}

-(void)simplePing:(SimplePing *)pinger didFailWithError:(NSError *)error{
    [_ping stop];
    
    NSString *hostname = _domainTextField.text;
    NSLog(@"Check IP For HOST : %@ Failed With Error : %@",hostname,error);
    [_activityIndicator stopAnimating];
}

///////////////////////////////////////////////////////////
- (IBAction)onCheckHostBtn:(id)sender {
    //    [self checkHost];
    [self pingHost];
}

@end
