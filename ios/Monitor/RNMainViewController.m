//
//  RNMainViewController.m
//  Yoosee
//
//  Created by laps on 12/19/16.
//  Copyright © 2016 guojunyi. All rights reserved.
//

#import "RNMainViewController.h"
#import "RCTRootView.h"

@interface RNMainViewController ()

@end

@implementation RNMainViewController

static RNMainViewController *_instance = nil;

+(instancetype) shareInstance
{
    static dispatch_once_t onceToken ;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init] ;
    }) ;
    return _instance ;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    NSURL *jsCodeLocation = [[NSBundle mainBundle] URLForResource:@"index.ios" withExtension:@"jsbundle"];
//    NSURL *jsCodeLocation = [NSURL
//                             URLWithString:@"http://192.168.1.105:8081/index.ios.bundle?platform=ios"];
    RCTRootView *rootView = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
                                                        moduleName:@"monitor"
                                                 initialProperties:nil
                                                     launchOptions:nil];
    rootView.backgroundColor = [[UIColor alloc] initWithRed:1.0f green:1.0f blue:1.0f alpha:1];
    self.view = rootView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate {
    
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    
    return UIInterfaceOrientationMaskPortrait;
}


@end
