//
//  NativeInterface.m
//  Yoosee
//
//  Created by laps on 12/10/16.
//  Copyright © 2016 guojunyi. All rights reserved.
//

#import "NativeInterface.h"
#import "UDManager.h"
#import "AppDelegate.h"

#import "NetManager.h"
#import "LoginResult.h"
#import "RegisterResult.h"

@implementation NativeInterface

RCT_EXPORT_MODULE(NativeInterface);

RCT_EXPORT_METHOD(showLoading)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.hud) {
            [self.hud hide:YES];
            self.hud = nil;
        }
        
        UIViewController *controller = [self getCurrentVC];
        if (controller == nil) {
            return;
        }
        UIView *rootView = controller.view;
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:rootView animated:YES];
        self.hud = hud;
        // 隐藏时候从父控件中移除
        hud.removeFromSuperViewOnHide = YES;
        // YES代表需要蒙版效果
        hud.dimBackground = YES;
    });
    
}

RCT_EXPORT_METHOD(hideLoading)
{
    dispatch_async(dispatch_get_main_queue(), ^{
//        UIViewController *controller = [self getCurrentVC];
//        UIView *rootView = controller.view;
//        [MBProgressHUD hideHUDForView:rootView animated:YES];
        if (self.hud) {
            [self.hud hide:YES];
            self.hud = nil;
        }
    });
}

RCT_EXPORT_METHOD(showToast:(NSString *)message)
{
    [self toast:message];
}


RCT_EXPORT_METHOD(isLogin:(RCTResponseSenderBlock)callback)
{
    BOOL islogin = [UDManager isLogin];
    if (islogin) {
        callback(@[@YES]);
    } else {
        callback(@[@NO]);
    }
}

RCT_EXPORT_METHOD(getUserInfo:(RCTResponseSenderBlock)callback)
{
    LoginResult *loginResult = [UDManager getLoginInfo];
    callback(@[@{@"code":@"00",@"phone":loginResult.phone, @"message":@"登陆成功"}]);
}

RCT_EXPORT_METHOD(login:(NSDictionary *)params resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSString *phone = [params objectForKey:@"phone"];
    NSString *pwd = [params objectForKey:@"pwd"];
    NSString *username = [NSString stringWithFormat:@"+86-%@",phone];
    [[NetManager sharedManager] loginWithUserName:username password:pwd token:[AppDelegate sharedDefault].token callBack:^(id result){
        
        LoginResult *loginResult = (LoginResult*)result;
        //用户登录时，则记下用户的登录密码；用于下次登录时，不用再输入PWD
        [[NSUserDefaults standardUserDefaults] setObject:pwd forKey:@"PHONE_PWD"];
        
        switch(loginResult.error_code){
            case NET_RET_LOGIN_SUCCESS:
            {
                //re-registerForRemoteNotifications
                if (CURRENT_VERSION<9.3) {
                    if(CURRENT_VERSION>=8.0){//8.0以后使用这种方法来注册推送通知
                        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge|UIUserNotificationTypeSound|UIUserNotificationTypeAlert categories:nil];
                        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
                        [[UIApplication sharedApplication] registerForRemoteNotifications];
                        
                    }else{
                        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeBadge)];
                    }
                }
                
                DLog(@"contactId:%@",loginResult.contactId);
                DLog(@"Email:%@",loginResult.email);
                DLog(@"Phone:%@",loginResult.phone);
                DLog(@"CountryCode:%@",loginResult.countryCode);
                [UDManager setIsLogin:YES];
                [UDManager setLoginInfo:loginResult];
                [[NSUserDefaults standardUserDefaults] setObject:phone forKey:@"PHONE_NUMBER"];
                [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"LOGIN_TYPE"];
                resolve(@{@"code":@"00",@"message":@"登陆成功"});
            }
                break;
            case NET_RET_LOGIN_USER_UNEXIST:
            {
                NSString *message = NSLocalizedString(@"user_unexist", nil);
                reject(@"01",message, nil);
            }
                break;
            case NET_RET_LOGIN_PWD_ERROR:
            {
                NSString *message = NSLocalizedString(@"password_error", nil);
                reject(@"01",message, nil);
            }
                break;
            case NET_RET_UNKNOWN_ERROR:
            {
                NSString *message = NSLocalizedString(@"login_failure", nil);
                reject(@"01",message, nil);
            }
                break;
            case NET_RET_SYSTEM_MAINTENANCE_ERROR:
            {
                NSString *message = NSLocalizedString(@"system_maintenance", nil);
                reject(@"01",message, nil);
            }
                break;
            default:
            {
                NSString *message = NSLocalizedString(@"login_failure", nil);
                reject(@"01",message, nil);
            }
                break;
        }
        
    }];
}

RCT_EXPORT_METHOD(getCode:(NSString *)phone)
{
    [[NetManager sharedManager] getPhoneCodeWithPhone:phone countryCode:@"86" callBack:^(id JSON) {
        NSInteger error_code = (NSInteger)JSON;
        switch(error_code){
            case NET_RET_GET_PHONE_CODE_SUCCESS:
            {
                
            }
                break;
            case NET_RET_GET_PHONE_CODE_PHONE_USED:
            {
                [self toast:NSLocalizedString(@"phone_used", nil)];
            }
                break;
            case NET_RET_GET_PHONE_CODE_TOO_TIMES:
            {
                [self toast:NSLocalizedString(@"get_phone_code_too_times", nil)];
            }
                break;
            case NET_RET_SYSTEM_MAINTENANCE_ERROR:
            {
                [self toast:NSLocalizedString(@"system_maintenance", nil)];
            }
                break;
            default:
            {
                [self toast:[NSString stringWithFormat:@"%@:%i",NSLocalizedString(@"unknown_error", nil),error_code]];
            }
                break;
        }
    }];
}

RCT_EXPORT_METHOD(register:(NSDictionary *)params resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSString *phone = [params objectForKey:@"phone"];
    NSString *pwd = [params objectForKey:@"pwd"];
    NSString *code = [params objectForKey:@"code"];
    
    [[NetManager sharedManager] registerWithVersionFlag:@"1" email:@"" countryCode:@"86" phone:phone password:pwd repassword:pwd phoneCode:code callBack:^(id JSON) {
        
        RegisterResult *registerResult = (RegisterResult*)JSON;
        switch(registerResult.error_code){
            case NET_RET_REGISTER_SUCCESS:
            {
                resolve(@{@"code":@"00",@"message":@"注册成功"});
            }
                break;
            case NET_RET_REGISTER_EMAIL_FORMAT_ERROR:
            {
                NSString * message = NSLocalizedString(@"email_format_error", nil);
                reject(@"01",message, nil);
            }
                break;
            case NET_RET_REGISTER_EMAIL_USED:
            {
                NSString * message = NSLocalizedString(@"email_used", nil);
                reject(@"01",message, nil);
            }
                break;
            case NET_RET_SYSTEM_MAINTENANCE_ERROR:
            {
                NSString * message = NSLocalizedString(@"system_maintenance", nil);
                reject(@"01",message, nil);
            }
                break;
            default:
            {
                NSString * message = [NSString stringWithFormat:@"%@:%i",NSLocalizedString(@"unknown_error", nil),registerResult.error_code];
                reject(@"01",message, nil);
            }
        }
    }];
}

- (void)toast:(NSString *)message
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *controller = [self getCurrentVC];
        if (controller == nil) {
            return;
        }
        UIView *rootView = controller.view;
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:rootView animated:YES];
        hud.labelText = message;
        hud.mode = MBProgressHUDModeText;
        // 隐藏时候从父控件中移除
        hud.removeFromSuperViewOnHide = YES;
        [hud hide:YES afterDelay:1.5];
    });
}

- (UIViewController *)getCurrentVC
{
    @try {
        UIViewController *result = nil;
        
        UIWindow * window = [[UIApplication sharedApplication] keyWindow];
        if (window.windowLevel != UIWindowLevelNormal)
        {
            NSArray *windows = [[UIApplication sharedApplication] windows];
            for(UIWindow * tmpWin in windows)
            {
                if (tmpWin.windowLevel == UIWindowLevelNormal)
                {
                    window = tmpWin;
                    break;
                }
            }
        }
        
        NSArray *subviews = [window subviews];
        
        UIView *frontView = [subviews objectAtIndex:0];
        id nextResponder = [frontView nextResponder];
        
        if ([nextResponder isKindOfClass:[UIViewController class]])
            result = nextResponder;
        else
            result = window.rootViewController;
        
        return result;
    } @catch (NSException *exception) {
        return nil;
    } @finally {
    
    }
    
}


@end
