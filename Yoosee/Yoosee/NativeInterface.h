//
//  NativeInterface.h
//  Yoosee
//
//  Created by laps on 12/10/16.
//  Copyright © 2016 guojunyi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCTBridgeModule.h"
#import "MBProgressHUD.h"

@interface NativeInterface : NSObject<RCTBridgeModule>

@property (nonatomic, strong) MBProgressHUD *hud;

@end
