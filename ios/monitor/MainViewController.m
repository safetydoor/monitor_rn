//
//  MainViewController.m
//  monitor
//
//  Created by laps on 9/24/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import "MainViewController.h"
#import "RCTBundleURLProvider.h"
#import "RCTRootView.h"
#import "MainController.h"

@implementation MainViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.view.backgroundColor = [UIColor whiteColor];
  UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
  btn.backgroundColor = [UIColor redColor];
  [btn setTitle:@"fsdfsdf" forState:UIControlStateNormal];
  [btn addTarget:self action:@selector(onClick:) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:btn];
  
  
  UIButton *btn2 = [[UIButton alloc] initWithFrame:CGRectMake(100, 300, 100, 100)];
  btn2.backgroundColor = [UIColor redColor];
  [btn2 setTitle:@"222222" forState:UIControlStateNormal];
  [btn2 addTarget:self action:@selector(onClick2:) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:btn2];
  
  UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
  [imageView setImage:[UIImage imageNamed:@"bankcard_yellow"]];
  [self.view addSubview:imageView];
  
}

- (void)onClick:(id)sender{
  MainController *mainController = [[MainController alloc] init];
  UINavigationController *navigationController = self.navigationController;
  [self presentViewController:mainController animated:YES completion:nil];
//  [navigationController pushViewController:mainController animated:YES];
}

- (void)onClick2:(id)sender{
  NSURL *jsCodeLocation;
  
  jsCodeLocation = [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index.ios" fallbackResource:nil];
  
  RCTRootView *rootView = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
                                                      moduleName:@"monitor"
                                               initialProperties:nil
                                                   launchOptions:nil];
  rootView.backgroundColor = [[UIColor alloc] initWithRed:1.0f green:1.0f blue:1.0f alpha:1];
  
  UIViewController *viewController = [UIViewController new];
  viewController.view = rootView;
  [self presentViewController:viewController animated:YES completion:nil];
  
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

@end
