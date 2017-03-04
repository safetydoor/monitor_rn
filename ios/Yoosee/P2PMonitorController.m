///
//  P2PMonitorController.m
//  Yoosee
//
//  Created by guojunyi on 14-3-26.
//  Copyright (c) 2014年 guojunyi. All rights reserved.
//

/***********UI逻辑**************
 1、ap模式和局域网机器使用rtsp连接
 2、画布：
 rtsp:根据opengl解码动态,因为一般ipc是16：9，960p的机器是4:3
 3、分辨率设置
 rtsp:不支持
 4、当前观看人数
 rtsp:不支持 （因为rtsp连接时不会收到通知，所以不用处理此处逻辑）
 ******************************/

#import "P2PMonitorController.h"
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "P2PClient.h"
#import "Toast+UIView.h"
#import "AppDelegate.h"
#import "PAIOUnit.h"
#import "UDManager.h"
#import "LoginResult.h"
#import "Utils.h"
#import "TouchButton.h"
#import "ContactDAO.h"
#import "FListManager.h"
#import "Contact.h"
#import "UDPManager.h"//rtsp监控界面弹出修改
#import "LocalDevice.h"//rtsp监控界面弹出修改
#import "CustomTopBar.h"

#define MAX_VIDEO_RES_SIZE ((1920+32)*1088)

@interface P2PMonitorController ()
{
    CGFloat _horizontalScreenH;
    CGFloat _monitorInterfaceW;//rtsp监控界面弹出修改
    CGFloat _monitorInterfaceH;//rtsp监控界面弹出修改
    
    UIButton* _btnDefence;
    
    BOOL _isPlaying;
    BOOL _isOkFirstRenderVideoFrame;//YES表示第一次成功渲染图像
    BOOL _isOkRenderVideoFrame;//YES表示图像渲染出来了
    
    BOOL _isCanAutoOrientation;//限制屏幕什么时候可以旋转
}
@end

@implementation P2PMonitorController

-(void)dealloc{
    [self.remoteView release];
    [self.bottomView release];//重新调整监控画面
    [self.pressView release];
    [self.controllerRight release];
    [self.controllerRightBg release];//重新调整监控画面
    [self.bottomBarView release];//重新调整监控画面
    [self.controllBar release];
    [self.customBorderButton release];
    [self.leftView release];
    [self.clickGPIO0_0Button release];
    [self.clickGPIO0_1Button release];
    [self.clickGPIO0_2Button release];
    [self.clickGPIO0_3Button release];
    [self.clickGPIO0_4Button release];
    [self.clickGPIO2_6Button release];
    [self.lightButton release];
    [self.progressView release];
    [self.yProgressView release];//rtsp监控界面弹出修改
    [self.focalLengthView release];
    [self.pinchGestureRecognizer release];
    
    [self.fullScreenBgView release];
    //竖屏
    [self.topBar release];
    [self.canvasView release];
    [self.promptButton release];
    [self.labelTip release];
    [self.midToolHView release];
    [self.defenceButtonH release];
    [self.bottomToolHView release];
    if (self.scrollView) {
        [self.scrollView release];
    }
    [super dealloc];
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _isPlaying = NO;
    }
    return self;
}

-(void)viewWillDisappear:(BOOL)animated{
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        [[UIDevice currentDevice] performSelector:@selector(setOrientation:)
                                       withObject:(id)UIDeviceOrientationPortrait];
    }
    self.isReject = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    if (self.isFullScreen){
        if (self.scrollView){
            [self.scrollView setZoomScale:1.0];
        }
    }
    [self.remoteView setCaptureFinishScreen:YES];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RECEIVE_REMOTE_MESSAGE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ACK_RECEIVE_REMOTE_MESSAGE object:nil];
    //rtsp监控界面弹出修改
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MONITOR_START_RENDER_MESSAGE object:nil];
    
    if ([AppDelegate sharedDefault].isDoorBellAlarm) {//透传连接
        NSString *contactId = [[P2PClient sharedClient] callId];
        NSString *contactPassword = [[P2PClient sharedClient] callPassword];
        [[P2PClient sharedClient] sendCustomCmdWithId:contactId password:contactPassword cmd:@"IPC1anerfa:disconnect"];
    }
    
    [AppDelegate sharedDefault].monitoredContactId = nil;
    if ([AppDelegate sharedDefault].isMonitoring) {
        [AppDelegate sharedDefault].isMonitoring = NO;//挂断，不处于监控状态
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveRemoteMessage:) name:RECEIVE_REMOTE_MESSAGE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ack_receiveRemoteMessage:) name:ACK_RECEIVE_REMOTE_MESSAGE object:nil];
    //rtsp监控界面弹出修改
    /*
     * 1. 注册监控渲染监听通知
     * 2. 在函数monitorStartRender里，开始渲染监控画面
     */
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(monitorStartRender:) name:MONITOR_START_RENDER_MESSAGE object:nil];
    _isCanAutoOrientation = YES;
    
    NSString *contactId = [[P2PClient sharedClient] callId];
    NSString *contactPassword = [[P2PClient sharedClient] callPassword];
    if ([AppDelegate sharedDefault].isDoorBellAlarm) {//透传连接
        
        [[P2PClient sharedClient] sendCustomCmdWithId:contactId password:contactPassword cmd:@"IPC1anerfa:connect"];
    }
    
    //过滤当前被监控帐号的推送显示
    [AppDelegate sharedDefault].monitoredContactId = contactId;
    
    [AppDelegate sharedDefault].isMonitoring = YES;//当前是监控、视频通话或呼叫状态下
}

#define MESG_SET_GPIO_PERMISSION_DENIED 86
#define MESG_GPIO_CTRL_QUEUE_IS_FULL 87
#define MESG_SET_DEVICE_NOT_SUPPORT 255

#define GPIO0_0 10
#define GPIO0_1 11
#define GPIO0_2 12
#define GPIO0_3 13
#define GPIO0_4 14
#define GPIO2_6 15
- (void)receiveRemoteMessage:(NSNotification *)notification{
    NSDictionary *parameter = [notification userInfo];
    int key   = [[parameter valueForKey:@"key"] intValue];
    switch(key){
        case RET_GET_FOCUS_ZOOM:
        {
            int value = [[parameter valueForKey:@"value"] intValue];
           
            if (value == 3) {//变倍变焦都有
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.isSupportFocalLength = YES;
                    [self.pinchGestureRecognizer addTarget:self action:@selector(localLengthPinchToZoom:)];
                });
            }else if (value == 2){//只有变焦
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.isSupportFocalLength = YES;
                });
                
            }else if (value == 1){//只有变倍
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.pinchGestureRecognizer addTarget:self action:@selector(localLengthPinchToZoom:)];
                });
                
            }
        }
            break;
        case RET_SET_GPIO_CTL:
        {
            int result = [[parameter valueForKey:@"result"] intValue];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.clickGPIO0_0Button.backgroundColor = [UIColor clearColor];
                self.clickGPIO0_1Button.backgroundColor = [UIColor clearColor];
                self.clickGPIO0_2Button.backgroundColor = [UIColor clearColor];
                self.clickGPIO0_3Button.backgroundColor = [UIColor clearColor];
                self.clickGPIO0_4Button.backgroundColor = [UIColor clearColor];
                self.clickGPIO2_6Button.backgroundColor = [UIColor clearColor];
            });
            if (result == 0) {
                //设置成功
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.view makeToast:NSLocalizedString(@"operator_success", nil)];
                });
            }else if (result == MESG_SET_GPIO_PERMISSION_DENIED){
                //该GPIO未开放
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [self.view makeToast:NSLocalizedString(@"not_open", nil)];
                });
            }else if (result == MESG_GPIO_CTRL_QUEUE_IS_FULL){
                //操作过于频繁，之前的操作未执行完
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [self.view makeToast:NSLocalizedString(@"too_frequent", nil)];
                });
            }else if(result == MESG_SET_DEVICE_NOT_SUPPORT){
                //设备不支持此操作
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [self.view makeToast:NSLocalizedString(@"not_support_operation", nil)];
                });
            }
        }
            break;
        case RET_GET_LIGHT_SWITCH_STATE:
        {
            int result = [[parameter valueForKey:@"result"] intValue];
            
            if (result == 0) {
                int state = [[parameter valueForKey:@"state"] intValue];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.isSupportLightSwitch = YES;
                    if (state == 1) {//灯是开状态
                        self.isLightSwitchOn = YES;
                        [self.lightButton setBackgroundImage:[UIImage imageNamed:@"lighton.png"] forState:UIControlStateNormal];
                    }else{
                        self.isLightSwitchOn = NO;
                        [self.lightButton setBackgroundImage:[UIImage imageNamed:@"lightoff.png"] forState:UIControlStateNormal];
                    }
                });
            }
        }
            break;
        case RET_SET_LIGHT_SWITCH_STATE:
        {
            int result = [[parameter valueForKey:@"result"] intValue];
            
            if (result == 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.lightButton setHidden:NO];
                    [self.progressView setHidden:YES];
                    [self.progressView stopAnimating];
                    if (self.isLightSwitchOn) {//灯正开着
                        self.isLightSwitchOn = NO;//关灯
                        [self.lightButton setBackgroundImage:[UIImage imageNamed:@"lightoff.png"] forState:UIControlStateNormal];
                    }else{//灯正关着
                        self.isLightSwitchOn = YES;//开灯
                        [self.lightButton setBackgroundImage:[UIImage imageNamed:@"lighton.png"] forState:UIControlStateNormal];
                    }
                });
            }
        }
            break;
        case RET_DEVICE_NOT_SUPPORT:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.clickGPIO0_0Button.backgroundColor = [UIColor clearColor];
                self.clickGPIO0_1Button.backgroundColor = [UIColor clearColor];
                self.clickGPIO0_2Button.backgroundColor = [UIColor clearColor];
                self.clickGPIO0_3Button.backgroundColor = [UIColor clearColor];
                self.clickGPIO0_4Button.backgroundColor = [UIColor clearColor];
                self.clickGPIO2_6Button.backgroundColor = [UIColor clearColor];
                
                //[self.view makeToast:NSLocalizedString(@"device_not_support", nil)];
            });
        }
            break;
        case RET_GET_NPCSETTINGS_REMOTE_DEFENCE:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSInteger state = [[parameter valueForKey:@"state"] intValue];
                if(state==SETTING_VALUE_REMOTE_DEFENCE_STATE_ON)
                {
                    //竖屏
                    [self.defenceButtonH setImage:[UIImage imageNamed:@"monitor_defence_on_h.png"] forState:UIControlStateNormal];
                    [self.defenceButtonH setImage:[UIImage imageNamed:@"monitor_defence_on_h_p.png"] forState:UIControlStateHighlighted];
                    //获取到布防状态，设置为可点且显示相应的图标
                    self.defenceButtonH.enabled = YES;
                    
                    
                    self.isDefenceOn = YES;
                    
                    //横屏
                    [_btnDefence setBackgroundImage:[UIImage imageNamed:@"ic_ctl_lock_on.png"] forState:UIControlStateNormal];
                }
                else
                {
                    //竖屏
                    [self.defenceButtonH setImage:[UIImage imageNamed:@"monitor_defence_off_h.png"] forState:UIControlStateNormal];
                    [self.defenceButtonH setImage:[UIImage imageNamed:@"monitor_defence_off_h_p.png"] forState:UIControlStateHighlighted];
                    //获取到布防状态，设置为可点且显示相应的图标
                    self.defenceButtonH.enabled = YES;
                    
                    
                    self.isDefenceOn = NO;
                    
                    //横屏
                    [_btnDefence setBackgroundImage:[UIImage imageNamed:@"ic_ctl_lock_off.png"] forState:UIControlStateNormal];
                }

                if (_btnDefence.hidden == YES) {
                    _btnDefence.hidden = NO;
                }
            });
        }
            break;
            
        case RET_SET_NPCSETTINGS_REMOTE_DEFENCE:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSInteger state = [[parameter valueForKey:@"state"] intValue];
                if(state==SETTING_VALUE_REMOTE_DEFENCE_STATE_ON){
                    //竖屏
                    [self.defenceButtonH setImage:[UIImage imageNamed:@"monitor_defence_on_h.png"] forState:UIControlStateNormal];
                    [self.defenceButtonH setImage:[UIImage imageNamed:@"monitor_defence_on_h_p.png"] forState:UIControlStateHighlighted];
                    
                    
                    self.isDefenceOn = YES;
                    
                    //横屏
                    [_btnDefence setBackgroundImage:[UIImage imageNamed:@"ic_ctl_lock_on.png"] forState:UIControlStateNormal];
                }else{
                    //竖屏
                    [self.defenceButtonH setImage:[UIImage imageNamed:@"monitor_defence_off_h.png"] forState:UIControlStateNormal];
                    [self.defenceButtonH setImage:[UIImage imageNamed:@"monitor_defence_off_h_p.png"] forState:UIControlStateHighlighted];
                    
                    
                    self.isDefenceOn = NO;
                    
                    //横屏
                    [_btnDefence setBackgroundImage:[UIImage imageNamed:@"ic_ctl_lock_off.png"] forState:UIControlStateNormal];
                }
            });
        }
            break;
    }
}

- (void)ack_receiveRemoteMessage:(NSNotification *)notification{
    NSDictionary *parameter = [notification userInfo];
    int key   = [[parameter valueForKey:@"key"] intValue];
    int result   = [[parameter valueForKey:@"result"] intValue];
    switch(key){
        case ACK_RET_SET_GPIO_CTL:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(result==1){
                    
                    [self.view makeToast:NSLocalizedString(@"device_password_error", nil)];
                }else if(result==2){
                    DLog(@"resend do device update");
                    NSString *contactId = [[P2PClient sharedClient] callId];
                    NSString *contactPassword = [[P2PClient sharedClient] callPassword];
                    
                    [[P2PClient sharedClient] setGpioCtrlWithId:contactId password:contactPassword group:self.lastGroup pin:self.lastPin value:self.lastValue time:self.lastTime];
                }
            });
        }
            break;
        case ACK_RET_GET_LIGHT_STATE:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(result==1){
                    
                    [self.view makeToast:NSLocalizedString(@"device_password_error", nil)];
                }else if(result==2){
                    DLog(@"resend do device update");
                    NSString *contactId = [[P2PClient sharedClient] callId];
                    NSString *contactPassword = [[P2PClient sharedClient] callPassword];
                    
                    [[P2PClient sharedClient] getLightStateWithDeviceId:contactId password:contactPassword];
                }
            });
        }
            break;
        case ACK_RET_SET_LIGHT_STATE:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(result==1){
                    
                    [self.view makeToast:NSLocalizedString(@"device_password_error", nil)];
                }else if(result==2){
                    DLog(@"resend do device update");
                    NSString *contactId = [[P2PClient sharedClient] callId];
                    NSString *contactPassword = [[P2PClient sharedClient] callPassword];
                    
                    if (self.isLightSwitchOn) {//灯正开着
                        [[P2PClient sharedClient] setLightStateWithDeviceId:contactId password:contactPassword switchState:0];//关灯
                    }else{
                        [[P2PClient sharedClient] setLightStateWithDeviceId:contactId password:contactPassword switchState:1];//开灯
                    }
                }
            });
        }
            break;
        case ACK_RET_GET_DEFENCE_STATE:
        {
            if(result==2){
                //超时
                NSString *callId = [[P2PClient sharedClient] callId];
                NSString *callPassword = [[P2PClient sharedClient] callPassword];
                [[P2PClient sharedClient]getDefenceState:callId password:callPassword];
            }
        }
            break;
            
        case ACK_RET_SET_NPCSETTINGS_REMOTE_DEFENCE:
        {
            if (result == 2)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.view makeToast:NSLocalizedString(@"net_exception", nil)];
                });
            }
        }
            break;
    }
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    self.isShowControllerBar = YES;
    self.isVideoModeHD = NO;
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    //监控竖屏时，各控件初始化(先)
    [self initComponentForPortrait];
    
    //监控横屏时，各控件初始化(后)
    [self initComponentForHorizontalScreen];
    
    
    //rtsp监控界面弹出修改
    [self monitorP2PCall];
    
    //设置代理
    [AppDelegate sharedDefault].mainController.mainControllerDelegate = self;
    [AppDelegate sharedDefault].gApplicationDelegate = self;
}

#pragma mark - 收到推送，点击观看时，代理回调
-(void)gApplicationWithId:(NSString *)contactId password:(NSString *)password callType:(P2PCallType)type{
    //过滤当前被监控帐号的推送显示
    [AppDelegate sharedDefault].monitoredContactId = contactId;
    
    [[P2PClient sharedClient] setIsBCalled:NO];
    [[P2PClient sharedClient] setCallId:contactId];
    [[P2PClient sharedClient] setP2pCallType:type];
    [[P2PClient sharedClient] setCallPassword:password];
    
    //视频监控连接中的标题
    NSString *deviceName = @"";
    if ([[AppDelegate sharedDefault] dwApContactID] == 0) {
        deviceName = [NSString stringWithFormat:@"Cam%@",contactId];
        
        ContactDAO *contactDAO = [[ContactDAO alloc] init];
        Contact *contact = [contactDAO isContact:contactId];
        NSString *contactName = contact.contactName;
        [contactDAO release];
        if (contactName) {
            deviceName = contactName;
        }
    }else{
        deviceName = [NSString stringWithFormat:@"Cam%d", [[AppDelegate sharedDefault] dwApContactID]];
    }
    [self.topBar setTitle:deviceName];
    
    
    self.isIntoMonitorFromMonitor = YES;
    
    
    //已经挂断了，此时再从推送中点击观看
    if (self.isReject) {
        self.isIntoMonitorFromMonitor = NO;
        [self hiddenMonitoringUI:NO callErrorInfo:nil isReCall:YES];
        [self monitorP2PCall];
    }
}

#pragma mark - 监控断开设备回调(代理)
-(void)mainControllerMonitorReject:(NSDictionary*)info{
    if(!self.isReject){
        self.isReject = !self.isReject;
        while (_isPlaying) {
            usleep(50*1000);
        }
    }
    _isOkRenderVideoFrame = NO;
    
    if (self.isIntoMonitorFromMonitor) {
        self.isIntoMonitorFromMonitor = NO;
        [self hiddenMonitoringUI:NO callErrorInfo:nil isReCall:YES];
        [self monitorP2PCall];
    }else{
        [self hiddenMonitoringUI:NO callErrorInfo:info isReCall:NO];
    }
}

#pragma mark - 隐藏监控连接中的UI
-(void)hiddenMonitoringUI:(BOOL)isHidden callErrorInfo:(NSDictionary*)info isReCall:(BOOL)isReCall{
    if (isHidden) {
        [self.yProgressView stop];
        [self.yProgressView setHidden:YES];
        
        [self.labelTip setHidden:YES];
        
        [self.promptButton setEnabled:NO];
        [self.promptButton setHidden:YES];
        
    }else{
        if (isReCall) {
            self.yProgressView.backgroundView.image = [UIImage imageNamed:@"monitor_press.png"];
            [self.yProgressView start];
            
            self.labelTip.text = [NSString stringWithFormat:@"%@",NSLocalizedString(@"monitor_out_prompt", nil)];
            
            [self.promptButton setEnabled:NO];
            
        }else{
            self.yProgressView.backgroundView.image = [UIImage imageNamed:@"monitor_recall.png"];
            [self.yProgressView stop];
            
            int errorFlag = [[info objectForKey:@"errorFlag"] intValue];
            self.labelTip.text = [self getCallErrorStringWith:errorFlag];
            
            [self.promptButton setEnabled:YES];
            
        }
        [self.yProgressView setHidden:NO];
        
        [self.labelTip setHidden:NO];
        
        [self.promptButton setHidden:NO];
        [self.canvasView bringSubviewToFront:self.promptButton];
    }
}

-(NSString *)getCallErrorStringWith:(int)errorFlag{
    switch(errorFlag)
    {
        case CALL_ERROR_NONE:
        {
            return NSLocalizedString(@"id_unknown_error", nil);
            
        }
            break;
        case CALL_ERROR_DESID_NOT_ENABLE:
        {
            return NSLocalizedString(@"id_disabled", nil);
        }
            break;
        case CALL_ERROR_DESID_OVERDATE:
        {
            return NSLocalizedString(@"id_overdate", nil);
        }
            break;
        case CALL_ERROR_DESID_NOT_ACTIVE:
        {
            return NSLocalizedString(@"id_inactived", nil);
        }
            break;
        case CALL_ERROR_DESID_OFFLINE:
        {
            return NSLocalizedString(@"id_offline", nil);
        }
            break;
        case CALL_ERROR_DESID_BUSY:
        {
            return NSLocalizedString(@"id_busy", nil);
        }
            break;
        case CALL_ERROR_DESID_POWERDOWN:
        {
            return NSLocalizedString(@"id_powerdown", nil);
        }
            break;
        case CALL_ERROR_NO_HELPER:
        {
            return NSLocalizedString(@"id_connect_failed", nil);
        }
            break;
        case CALL_ERROR_HANGUP:
        {
            return NSLocalizedString(@"id_hangup", nil);
            
            break;
        }
        case CALL_ERROR_TIMEOUT:
        {
            return NSLocalizedString(@"id_timeout", nil);
        }
            break;
        case CALL_ERROR_INTER_ERROR:
        {
            return NSLocalizedString(@"id_internal_error", nil);
        }
            break;
        case CALL_ERROR_RING_TIMEOUT:
        {
            return NSLocalizedString(@"id_no_accept", nil);
        }
            break;
        case CALL_ERROR_PW_WRONG:
        {
            return NSLocalizedString(@"id_password_error", nil);
        }
            break;
        case CALL_ERROR_CONN_FAIL:
        {
            return NSLocalizedString(@"id_connect_failed", nil);
        }
            break;
        case CALL_ERROR_NOT_SUPPORT:
        {
            return NSLocalizedString(@"id_not_support", nil);
        }
            break;
        default:
        {
            return NSLocalizedString(@"id_unknown_error", nil);
        }
            break;
    }
}

//rtsp监控界面弹出修改
-(void)monitorP2PCall{
    [[P2PClient sharedClient] setP2pCallState:P2PCALL_STATUS_CALLING];
    BOOL isBCalled = [[P2PClient sharedClient] isBCalled];
    P2PCallType type = [[P2PClient sharedClient] p2pCallType];
    NSString *callId = [[P2PClient sharedClient] callId];
    NSString *callPassword = [[P2PClient sharedClient] callPassword];
    
    if(!isBCalled){
        BOOL isApMode = ([[AppDelegate sharedDefault]dwApContactID] != 0);
        if (!isApMode)
        {
            [[P2PClient sharedClient] p2pCallWithId:callId password:callPassword callType:type];
        }
        else
        {
            [[P2PClient sharedClient] p2pCallWithId:@"1" password:callPassword callType:type];
        }
    }
}

- (void)renderView
{
    _isPlaying = YES;
    
    GAVFrame * m_pAVFrame ;
    while (!self.isReject)
    {
        if(fgGetVideoFrameToDisplay(&m_pAVFrame))
        {
            if (!_isOkRenderVideoFrame) {
                _isOkRenderVideoFrame = YES;
                _isOkFirstRenderVideoFrame = YES;
                dispatch_async(dispatch_get_main_queue(), ^{
                    //隐藏监控连接中的UI
                    [self hiddenMonitoringUI:YES callErrorInfo:nil isReCall:NO];
                    [self didHiddenMonitorUIWith:YES];
                });
            }
            [self.remoteView render:m_pAVFrame];
            vReleaseVideoFrame();
        }
        usleep(10000);
    }

    
    _isPlaying = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (TouchButton *)getControllerButton
{
    TouchButton *button = [TouchButton buttonWithType:UIButtonTypeCustom];
    
    [button setFrame:CGRectMake(0, 0, 50, 38)];
    [button setAlpha:0.5];
    [button setOpaque:YES];
    [button setBackgroundColor:[UIColor darkGrayColor]];
    [button.layer setBorderColor:[[UIColor blackColor] CGColor]];
    [button.layer setBorderWidth:2.0f];
    return button;
}

#define BOTTOM_BAR_HEIGHT (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 95.0:50.0)

#define PRESS_LAYOUT_WIDTH_AND_HEIGHT 38

#define CONTROLLER_BTN_COUNT 5
#define PUBLIC_WIDTH_OR_HEIGHT (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 95.0:50.0)
#define CONTROLLER_BTN_H_W (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 70.0:40.0)  //布防、声音...高度宽度
#define RESOLUTION_BTN_H (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 44.0:30.0)   //分辨率按钮高度

#define CONTROLLER_RIGHT_ITEM_WIDTH 70
#define CONTROLLER_RIGHT_ITEM_HEIGHT 40

#define CONTROLLER_BTN_TAG_HUNGUP 0
#define CONTROLLER_BTN_TAG_SOUND 1
#define CONTROLLER_BTN_TAG_SCREENSHOT 2
#define CONTROLLER_BTN_TAG_PRESS_TALK 3
#define CONTROLLER_BTN_TAG_DEFENCE_LOCK 4
#define CONTROLLER_BTN_TAG_HD 5
#define CONTROLLER_BTN_TAG_SD 6
#define CONTROLLER_BTN_TAG_LD 7
#define CONTROLLER_BTN_TAG_RESOLUTION 8
#define CONTROLLER_LABEL_TAG_HD 10
#define CONTROLLER_LABEL_TAG_SD 11
#define CONTROLLER_LABEL_TAG_LD 12

#define CONTROLLER_BTN_TAG_GPIO1_0 13  //lock

#define LEFTVIEW_WIDTH (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 88:88)
#define LEFTVIEW_HEIGHT (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 120:120)
#define CUSTOM_BORDER_BUTTON_WIDTH 20
#define CUSTOM_BORDER_BUTTON_HEIGHT 45
#define LEFT_BAR_BTN_WIDTH (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 90:60)
#define LEFT_BAR_BTN_MARGIN (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 15:10)

#pragma mark - 监控横屏时，各控件初始化
-(void)initComponentForHorizontalScreen{
    
    CGRect rect = [AppDelegate getScreenSize:NO isHorizontal:YES];
    CGFloat width = rect.size.width;
    _monitorInterfaceW = width;
    
    CGFloat height = rect.size.height;
    if(CURRENT_VERSION<7.0){
        height +=20;
    }
    _monitorInterfaceH = height;
    _horizontalScreenH = height;
    
    
    //横屏背景
    UIView *fullScreenBgView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, width, height)];
    fullScreenBgView.backgroundColor = XBlack;
    self.fullScreenBgView = fullScreenBgView;
    [fullScreenBgView release];
    
    
    //进入横屏时，响应onDoubleTap
    //退出横屏时，不响应onDoubleTap
    UITapGestureRecognizer *doubleTapG = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDoubleTap)];
    doubleTapG.delegate = self;
    [doubleTapG setNumberOfTapsRequired:2];
    [self.remoteView addGestureRecognizer:doubleTapG];
    [doubleTapG release];
    
    
    //进入横屏时，响应onSingleTap
    //退出横屏时，不响应onSingleTap
    UITapGestureRecognizer *singleTapG = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSingleTap)];
    singleTapG.delegate = self;
    [singleTapG setNumberOfTapsRequired:1];
    [singleTapG requireGestureRecognizerToFail:doubleTapG];
    [self.remoteView addGestureRecognizer:singleTapG];
    [singleTapG release];
    
    
    //进入横屏时，响应localLengthPinchToZoom
    //退出横屏时，不响应localLengthPinchToZoom
    NSString * plist = [[NSBundle mainBundle] pathForResource:@"Common-Configuration" ofType:@"plist"];
    NSDictionary * dic = [NSDictionary dictionaryWithContentsOfFile:plist];
    BOOL isSupportZoom = [dic[@"isSupportZoom"] boolValue];
    UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] init];
    if (!isSupportZoom) {//电子放大与焦距变倍不共存
        [_remoteView addGestureRecognizer:pinchGestureRecognizer];
    }
    self.pinchGestureRecognizer = pinchGestureRecognizer;
    [pinchGestureRecognizer release];
    
    
    
    //右边的画质图标
    //进入横屏时，显示
    //退出横屏时，隐藏
    int rightItemCount = 3;
    //半透明背景
    UIView *controllerRightBg = [[UIView alloc] initWithFrame:CGRectMake(5.0, height, CONTROLLER_RIGHT_ITEM_WIDTH, CONTROLLER_RIGHT_ITEM_HEIGHT*rightItemCount)];
    controllerRightBg.layer.cornerRadius = 1.0f;
    [controllerRightBg setAlpha:0.5];
    [controllerRightBg setBackgroundColor:XBlack];
    self.controllerRightBg = controllerRightBg;
    [self.view addSubview:controllerRightBg];
    [self.controllerRightBg setHidden:YES];
    [controllerRightBg release];
    
    UIView *controllerRight = [[UIView alloc] initWithFrame:CGRectMake(5.0, height, CONTROLLER_RIGHT_ITEM_WIDTH, CONTROLLER_RIGHT_ITEM_HEIGHT*rightItemCount)];
    self.controllerRight = controllerRight;
    [self.view addSubview:controllerRight];
    [self.controllerRight setHidden:YES];
    //分隔线
    for (int i=1; i < rightItemCount; i++) {
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0.0, i*CONTROLLER_RIGHT_ITEM_HEIGHT+1.0*(i-1), CONTROLLER_RIGHT_ITEM_WIDTH, 1.0)];
        lineView.backgroundColor = XWhite;
        [controllerRight addSubview:lineView];
        [lineView release];
    }
    
    for(int i=0;i<rightItemCount;i++){
        TouchButton *button = [self getBottomBarButton];
        button.frame = CGRectMake(0, (CONTROLLER_RIGHT_ITEM_HEIGHT+1.0)*i, CONTROLLER_RIGHT_ITEM_WIDTH, CONTROLLER_RIGHT_ITEM_HEIGHT);
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, button.frame.size.width, button.frame.size.height)];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = XWhite;
        label.font = [UIFont boldSystemFontOfSize:16.0];
        
        if(rightItemCount==2){//NPC
            if(i==0){
                label.text = NSLocalizedString(@"SD", nil);
                label.tag = CONTROLLER_LABEL_TAG_SD;
                button.tag = CONTROLLER_BTN_TAG_SD;
            }else if(i==1){
                label.text = NSLocalizedString(@"LD", nil);
                label.tag = CONTROLLER_LABEL_TAG_LD;
                label.textColor = XBlue;
                button.tag = CONTROLLER_BTN_TAG_LD;
            }
        }else if(rightItemCount==3){//IPC
            if(i==0){
                label.text = NSLocalizedString(@"HD", nil);
                label.tag = CONTROLLER_LABEL_TAG_HD;
                button.tag = CONTROLLER_BTN_TAG_HD;
            }else if(i==1){
                label.text = NSLocalizedString(@"SD", nil);
                label.tag = CONTROLLER_LABEL_TAG_SD;
                label.textColor = XBlue;
                button.tag = CONTROLLER_BTN_TAG_SD;
            }else if(i==2){
                label.text = NSLocalizedString(@"LD", nil);
                label.tag = CONTROLLER_LABEL_TAG_LD;
                button.tag = CONTROLLER_BTN_TAG_LD;
                //
                
            }
        }
        [button addSubview:label];
        [label release];
        [button addTarget:self action:@selector(onControllerBtnPress:) forControlEvents:UIControlEventTouchUpInside];
        [controllerRight addSubview:button];
    }
    
    [controllerRight release];
    
    
    
    //进入横屏时，显示
    //退出横屏时，隐藏
    //底部半透明块
    UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0.0, height-BOTTOM_BAR_HEIGHT, width, BOTTOM_BAR_HEIGHT)];
    [bottomView setAlpha:0.5];
    [bottomView setBackgroundColor:XBlack];
    self.bottomView = bottomView;
    [self.view addSubview:bottomView];
    [self.bottomView setHidden:YES];
    [bottomView release];
    
    UIView *bottomBarView = [[UIView alloc] initWithFrame:CGRectMake(0.0, height-BOTTOM_BAR_HEIGHT, width, BOTTOM_BAR_HEIGHT)];
    self.bottomBarView  = bottomBarView;
    [self.view addSubview:bottomBarView];
    [self.bottomBarView setHidden:YES];
    //左边的画质图标
    TouchButton *resolutionButton = [self getBottomBarButton];
    [resolutionButton setFrame:CGRectMake(5.0, (BOTTOM_BAR_HEIGHT-RESOLUTION_BTN_H)/2.0, CONTROLLER_RIGHT_ITEM_WIDTH, RESOLUTION_BTN_H)];
    resolutionButton.tag = CONTROLLER_BTN_TAG_RESOLUTION;
    if (rightItemCount == 2) {
        [resolutionButton setTitle:NSLocalizedString(@"LD", nil) forState:UIControlStateNormal];
    }else{
        [resolutionButton setTitle:NSLocalizedString(@"SD", nil) forState:UIControlStateNormal];
    }
    [resolutionButton setBackgroundImage:[UIImage imageNamed:@"ic_ctl_resolution.png"] forState:UIControlStateNormal];
    [resolutionButton addTarget:self action:@selector(selectResolutionClick:) forControlEvents:UIControlEventTouchUpInside];
    [bottomBarView addSubview:resolutionButton];
    
    //右边的切换屏幕图标
    TouchButton *switchScreenButton = [self getBottomBarButton];
    [switchScreenButton setFrame:CGRectMake(width-CONTROLLER_BTN_H_W-5.0, (BOTTOM_BAR_HEIGHT-CONTROLLER_BTN_H_W)/2.0, CONTROLLER_BTN_H_W, CONTROLLER_BTN_H_W)];
    switchScreenButton.tag = SWITCH_SCREEN_BUTTON_H_TAG;
    [switchScreenButton setBackgroundImage:[UIImage imageNamed:@"monitor_half_screen.png"] forState:UIControlStateNormal];
    [switchScreenButton addTarget:self action:@selector(onVerticalBtnPress:) forControlEvents:UIControlEventTouchUpInside];
    [bottomBarView addSubview:switchScreenButton];
    
    //右边的挂断图标
    TouchButton *hungUpButton = [self getBottomBarButton];
    [hungUpButton setFrame:CGRectMake(switchScreenButton.frame.origin.x-CONTROLLER_BTN_H_W-5.0, (BOTTOM_BAR_HEIGHT-CONTROLLER_BTN_H_W)/2.0, CONTROLLER_BTN_H_W, CONTROLLER_BTN_H_W)];
    hungUpButton.tag = CONTROLLER_BTN_TAG_HUNGUP;
    [hungUpButton setBackgroundImage:[UIImage imageNamed:@"ic_ctl_new_hungup.png"] forState:UIControlStateNormal];
    [hungUpButton addTarget:self action:@selector(onControllerBtnPress:) forControlEvents:UIControlEventTouchUpInside];
    [bottomBarView addSubview:hungUpButton];
    
    //布防撤防、声音开关、截图开关、按住说话开关、开门按钮
    UIView *controllBar = [[UIView alloc] initWithFrame:CGRectMake(CONTROLLER_RIGHT_ITEM_WIDTH+5.0, 0.0, width-CONTROLLER_RIGHT_ITEM_WIDTH-5.0-PUBLIC_WIDTH_OR_HEIGHT*2-5.0*2, PUBLIC_WIDTH_OR_HEIGHT)];
    controllBar.backgroundColor = [UIColor clearColor];
    self.controllBar = controllBar;
    
    int btnCount = CONTROLLER_BTN_COUNT;
    
    CGFloat firstControllerBtnX = (controllBar.frame.size.width-PUBLIC_WIDTH_OR_HEIGHT*btnCount)/2.0;
    for(int i=0;i<btnCount;i++){
        TouchButton *controllerBtn = [self getBottomBarButton];
        controllerBtn.frame = CGRectMake(PUBLIC_WIDTH_OR_HEIGHT*i+firstControllerBtnX, (BOTTOM_BAR_HEIGHT-CONTROLLER_BTN_H_W)/2.0, CONTROLLER_BTN_H_W,CONTROLLER_BTN_H_W);
        
        if(i==0){//布防撤防
            _btnDefence = controllerBtn;
            _btnDefence.hidden = YES;
            controllerBtn.tag = CONTROLLER_BTN_TAG_DEFENCE_LOCK;
            if ([AppDelegate sharedDefault].mainController.contact.defenceState == DEFENCE_STATE_ON || [AppDelegate sharedDefault].contact.defenceState == DEFENCE_STATE_ON) {
                [controllerBtn setBackgroundImage:[UIImage imageNamed:@"ic_ctl_lock_on.png"] forState:UIControlStateNormal];
                self.isDefenceOn = YES;
            }else if([AppDelegate sharedDefault].mainController.contact.defenceState == DEFENCE_STATE_OFF || [AppDelegate sharedDefault].contact.defenceState == DEFENCE_STATE_OFF){
                [controllerBtn setBackgroundImage:[UIImage imageNamed:@"ic_ctl_lock_off.png"] forState:UIControlStateNormal];
                self.isDefenceOn = NO;
            }
        }else if(i==1){//声音开关
            controllerBtn.tag = CONTROLLER_BTN_TAG_SOUND;
            [controllerBtn setBackgroundImage:[UIImage imageNamed:@"ic_ctl_new_sound_on.png"] forState:UIControlStateNormal];
        }else if(i==2){//按住说话开关
            controllerBtn.tag = CONTROLLER_BTN_TAG_PRESS_TALK;
            [controllerBtn setBackgroundImage:[UIImage imageNamed:@"ic_ctl_new_send_audio.png"] forState:UIControlStateNormal];
            [controllerBtn setBackgroundImage:[UIImage imageNamed:@"ic_ctl_new_send_audio_p.png"] forState:UIControlStateHighlighted];
        }else if(i==3){//截图开关
            controllerBtn.tag = CONTROLLER_BTN_TAG_SCREENSHOT;
            [controllerBtn setBackgroundImage:[UIImage imageNamed:@"ic_ctl_new_screenshot.png"] forState:UIControlStateNormal];
        }else if(i==4){//输出6秒高电平脉冲按钮
            controllerBtn.tag = CONTROLLER_BTN_TAG_GPIO1_0;
            [controllerBtn setBackgroundImage:[UIImage imageNamed:@"long_press_lock.png"] forState:UIControlStateNormal];
        }
        
        if(i==2){
            //对讲按钮
            
        }else{
            [controllerBtn addTarget:self action:@selector(onControllerBtnPress:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        [controllBar addSubview:controllerBtn];
    }
    [bottomBarView addSubview:controllBar];
    [controllBar release];
    
    [bottomBarView release];
    
    
    //button arrow
    //进入横屏时，显示
    //退出横屏时，隐藏
    CGFloat customBorderButtonY = (height - CUSTOM_BORDER_BUTTON_HEIGHT)/2.0;
    
    CustomBorderButton *customBorderButton=[CustomBorderButton buttonWithType:UIButtonTypeCustom];
    customBorderButton.frame = CGRectMake(0, customBorderButtonY, CUSTOM_BORDER_BUTTON_WIDTH, CUSTOM_BORDER_BUTTON_HEIGHT);
    
    [customBorderButton setNeedLineTop:true left:true bottom:true right:true];
    [customBorderButton setLineColorTop:[UIColor blackColor] left:[UIColor clearColor] bottom:[UIColor blackColor] right:[UIColor blackColor]];//用同一色边线
    [customBorderButton setLineWidthTop:2.0 left:2.0 bottom:2.0 right:2.0];//设置线的粗细，这里可以随意调整
    
    [customBorderButton setRadiusTopLeft:0 topRight:8.0 bottomLeft:0 bottomRight:8.0];//边线加弧度
    [customBorderButton setClipsToBoundsWithBorder:true];//裁剪掉边线外面的区域
    
    [customBorderButton setFillColor:[UIColor darkGrayColor]];//增加内部填充颜色
    [customBorderButton setAlpha:0.5];
    [customBorderButton setOpaque:YES];
    
    
    [customBorderButton setImage:[UIImage imageNamed:@"button_right"] forState:UIControlStateNormal];
    [customBorderButton setImage:[UIImage imageNamed:@"button_right_selected"] forState:UIControlStateHighlighted];
    [customBorderButton addTarget:self action:@selector(showLeftView:) forControlEvents:UIControlEventTouchUpInside];
    self.customBorderButton = customBorderButton;
    if ([AppDelegate sharedDefault].mainController.contact.defenceState == DEFENCE_STATE_NO_PERMISSION|| [AppDelegate sharedDefault].contact.defenceState == DEFENCE_STATE_NO_PERMISSION) {//访客密码
        
    }else{
        //[self.view addSubview:self.customBorderButton];//隐藏左侧按钮
        [self.customBorderButton setHidden:YES];
    }
    
    //左侧界面
    //进入横屏时，显示
    //退出横屏时，隐藏
    CGFloat leftViewY = (height - LEFTVIEW_HEIGHT)/2.0;
    CustomView *leftView = [[CustomView alloc] initWithFrame:CGRectMake(-LEFTVIEW_WIDTH, leftViewY, LEFTVIEW_WIDTH, LEFTVIEW_HEIGHT)];
    [leftView setNeedLineTop:true left:true bottom:true right:true];
    
    [leftView setLineColorTop:[UIColor blackColor] left:[UIColor blackColor] bottom:[UIColor blackColor] right:[UIColor blackColor]];//用同一色边线
    [leftView setLineWidthTop:2.0 left:2.0 bottom:2.0 right:2.0];//设置线的粗细，这里可以随意调整
    [leftView setRadiusTopLeft:8.0 topRight:8.0 bottomLeft:8.0 bottomRight:8.0];//边线加弧度
    [leftView setClipsToBoundsWithBorder:true];//裁剪掉边线外面的区域
    
    [leftView setFillColor:[UIColor darkGrayColor]];//增加内部填充颜色
    [leftView setAlpha:0.5];
    [leftView setOpaque:YES];
    self.leftView = leftView;
    [self.leftView setHidden:YES];
    if ([AppDelegate sharedDefault].mainController.contact.defenceState == DEFENCE_STATE_NO_PERMISSION|| [AppDelegate sharedDefault].contact.defenceState == DEFENCE_STATE_NO_PERMISSION) {//访客密码
        
    }else{
        //[self.view addSubview:self.leftView];//隐藏左侧按钮
        [self.leftView setHidden:YES];
    }
    [leftView release];
    CGFloat xSpace = 4.0;
    CGFloat ySpace = 4.0;
    CGFloat numLabelW = 12.0;
    CGFloat buttonW = (leftView.frame.size.width - numLabelW - xSpace*4)/2.0;
    CGFloat buttonH = (leftView.frame.size.height - ySpace*4)/3.0;
    int tag = 10;
    for (int i = 0; i < 3; i++) {
        
        UIButton *onButton = [UIButton buttonWithType:UIButtonTypeCustom];
        onButton.frame = CGRectMake(xSpace, (buttonH+ySpace)*i+ySpace, buttonW, buttonH);
        onButton.tag = tag++;
        [onButton setTitle:@"ON" forState:UIControlStateNormal];
        [onButton setTitleColor:XWhite forState:UIControlStateNormal];
        
        onButton.titleLabel.font = XFontBold_12;
        [onButton addTarget:self action:@selector(onOrOffButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.leftView addSubview:onButton];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(2*xSpace+buttonW, (buttonH+ySpace)*i+ySpace, numLabelW, buttonH)];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = XWhite;
        label.text = [NSString stringWithFormat:@"%d",i + 1];
        label.font = XFontBold_12;
        label.textAlignment = NSTextAlignmentCenter;
        [self.leftView addSubview:label];
        [label release];
        
        UIButton *offButton = [UIButton buttonWithType:UIButtonTypeCustom];
        offButton.frame = CGRectMake(3*xSpace+buttonW +numLabelW, (buttonH+ySpace)*i+ySpace, buttonW, buttonH);
        offButton.tag = tag++;
        [offButton setTitle:@"OFF" forState:UIControlStateNormal];
        [offButton setTitleColor:XWhite forState:UIControlStateNormal];
        
        offButton.titleLabel.font = XFontBold_12;
        [offButton addTarget:self action:@selector(onOrOffButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.leftView addSubview:offButton];
        
    }
    
    
    //右侧，灯控制按钮
    //进入横屏时，显示,并调整frame
    //退出横屏时，隐藏
    //提示器
    UIActivityIndicatorView *progressView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    progressView.frame = CGRectMake(self.remoteView.frame.size.width-30.0-20.0, (self.remoteView.frame.size.height-30.0)/2, 30.0, 30.0);
    [self.remoteView addSubview:progressView];
    self.progressView = progressView;
    [self.progressView setHidden:YES];
    [progressView release];
    //若设备支持灯设备时，则显示开关；若不支持，则隐藏
    UIButton *lightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    lightButton.frame = CGRectMake(self.remoteView.frame.size.width-30.0-20.0, (self.remoteView.frame.size.height-30.0)/2, 30.0, 30.0);
    lightButton.backgroundColor = [UIColor clearColor];
    [lightButton setBackgroundImage:[UIImage imageNamed:@"lighton.png"] forState:UIControlStateNormal];
    [lightButton addTarget:self action:@selector(btnClickToSetLightState:) forControlEvents:UIControlEventTouchUpInside];
    [self.remoteView addSubview:lightButton];
    [lightButton setHidden:YES];
    self.lightButton = lightButton;
    
    
    //进入横屏时，显示
    //退出横屏时，隐藏
    //焦距控件
    //宽、高
    CGFloat focalLengthView_w = 40.0;
    CGFloat focalLengthView_h = 180.0;
    //焦距控件与屏幕右边框的间距
    CGFloat space_FocalLView_Screen = (width - self.remoteView.frame.size.width)/2+20+focalLengthView_w;
    UIView *focalLengthView = [[UIView alloc] initWithFrame:CGRectMake(width-space_FocalLView_Screen, height-self.bottomBarView.frame.size.height-20.0-focalLengthView_h, focalLengthView_w, focalLengthView_h)];
    if (!isSupportZoom) {//电子放大与焦距变焦不共存
        [self.view addSubview:focalLengthView];
    }
    [focalLengthView setHidden:YES];
    self.focalLengthView = focalLengthView;
    [focalLengthView release];
    //焦距伸长按钮
    //宽、高
    CGFloat elongationButton_w = 34.0;
    CGFloat elongationButton_h = elongationButton_w*(46/43);
    UIButton *elongationButton = [UIButton buttonWithType:UIButtonTypeCustom];
    elongationButton.frame = CGRectMake((focalLengthView_w-elongationButton_w)/2, 0.0, elongationButton_w, elongationButton_h);
    [elongationButton setBackgroundImage:[UIImage imageNamed:@"monitor_localLenght_zoom_normal.png"] forState:UIControlStateNormal];
    [elongationButton setBackgroundImage:[UIImage imageNamed:@"monitor_localLenght_zoom_highlighted.png"] forState:UIControlStateHighlighted];
    elongationButton.tag = FocalLength_Elongation_btnTag;
    [elongationButton addTarget:self action:@selector(btnClickToChangeFocalLength:) forControlEvents:UIControlEventTouchUpInside];
    [self.focalLengthView addSubview:elongationButton];
    //拖动条
    UISlider *focalLengthSlider = [[UISlider alloc] initWithFrame:CGRectMake(0.0, 0.0, focalLengthView_h-elongationButton_h*2, 30.0)];
    focalLengthSlider.center = CGPointMake(self.focalLengthView.center.x-self.focalLengthView.frame.origin.x, self.focalLengthView.center.y-self.focalLengthView.frame.origin.y);
    //设置旋转90度
    focalLengthSlider.transform = CGAffineTransformMakeRotation(90*M_PI/180);
    focalLengthSlider.minimumValue = 1.0;
    focalLengthSlider.maximumValue = 15.0;
    focalLengthSlider.value = 7.5;
    focalLengthSlider.continuous = NO;//在手指离开的时候触发一次valueChange事件，而不是在拖动的过程中不断触发valueChange事件
    focalLengthSlider.tag = FocalLength_Change_sliderTag;
    [focalLengthSlider addTarget:self action:@selector(btnClickToChangeFocalLength:) forControlEvents:UIControlEventValueChanged];
    [self.focalLengthView addSubview:focalLengthSlider];
    [focalLengthSlider release];
    //焦距变短按钮
    //宽、高
    CGFloat shortenButton_w = elongationButton_w;
    CGFloat shortenButton_h = elongationButton_h;
    UIButton *shortenButton = [UIButton buttonWithType:UIButtonTypeCustom];
    shortenButton.frame = CGRectMake((focalLengthView_w-shortenButton_w)/2, focalLengthView_h-shortenButton_h, shortenButton_w, shortenButton_h);
    [shortenButton setBackgroundImage:[UIImage imageNamed:@"monitor_localLenght_narrow_normal.png"] forState:UIControlStateNormal];
    [shortenButton setBackgroundImage:[UIImage imageNamed:@"monitor_localLenght_narrow_highlighted.png"] forState:UIControlStateHighlighted];
    shortenButton.tag = FocalLength_Shorten_btnTag;
    [shortenButton addTarget:self action:@selector(btnClickToChangeFocalLength:) forControlEvents:UIControlEventTouchUpInside];
    [self.focalLengthView addSubview:shortenButton];
    
}

#pragma mark - 根据访客密码监控、门铃监控来重新布局controllBar上的按钮
-(void)reLayoutButtonInControlBar{
    
    int btnCount = 0;
    
    if ([AppDelegate sharedDefault].mainController.contact.defenceState == DEFENCE_STATE_NO_PERMISSION|| [AppDelegate sharedDefault].contact.defenceState == DEFENCE_STATE_NO_PERMISSION) {//访客密码
        
        btnCount = CONTROLLER_BTN_COUNT-2;//3个按钮
        
    }else if ([AppDelegate sharedDefault].isDoorBellAlarm) {
        btnCount = CONTROLLER_BTN_COUNT;//5个按钮
        
    }else{
        btnCount = CONTROLLER_BTN_COUNT-1;//4个按钮
    }
    
    CGFloat firstControllerBtnX = (self.controllBar.frame.size.width-PUBLIC_WIDTH_OR_HEIGHT*btnCount)/2.0;
    for(int i=0;i<btnCount;i++){
        
        if ([AppDelegate sharedDefault].mainController.contact.defenceState == DEFENCE_STATE_NO_PERMISSION|| [AppDelegate sharedDefault].contact.defenceState == DEFENCE_STATE_NO_PERMISSION) {//访客密码
           
            //布防撤防
            TouchButton *controllerDefenceBtn = (TouchButton *)[self.controllBar viewWithTag:CONTROLLER_BTN_TAG_DEFENCE_LOCK];
            [controllerDefenceBtn setHidden:YES];
            //输出6秒高电平脉冲按钮
            TouchButton *controllerDoorLockBtn = (TouchButton *)[self.controllBar viewWithTag:CONTROLLER_BTN_TAG_GPIO1_0];
            [controllerDoorLockBtn setHidden:YES];
            
            if(i==0){//声音开关
                TouchButton *controllerSoundBtn = (TouchButton *)[self.controllBar viewWithTag:CONTROLLER_BTN_TAG_SOUND];
                controllerSoundBtn.frame = CGRectMake(PUBLIC_WIDTH_OR_HEIGHT*i+firstControllerBtnX, (BOTTOM_BAR_HEIGHT-CONTROLLER_BTN_H_W)/2.0, CONTROLLER_BTN_H_W,CONTROLLER_BTN_H_W);
                
            }else if(i==1){//按住说话开关
                TouchButton *controllerTalkBtn = (TouchButton *)[self.controllBar viewWithTag:CONTROLLER_BTN_TAG_PRESS_TALK];
                controllerTalkBtn.frame = CGRectMake(PUBLIC_WIDTH_OR_HEIGHT*i+firstControllerBtnX, (BOTTOM_BAR_HEIGHT-CONTROLLER_BTN_H_W)/2.0, CONTROLLER_BTN_H_W,CONTROLLER_BTN_H_W);
                
            }else if(i==2){//截图开关
                TouchButton *controllerScreenshotBtn = (TouchButton *)[self.controllBar viewWithTag:CONTROLLER_BTN_TAG_SCREENSHOT];
                controllerScreenshotBtn.frame = CGRectMake(PUBLIC_WIDTH_OR_HEIGHT*i+firstControllerBtnX, (BOTTOM_BAR_HEIGHT-CONTROLLER_BTN_H_W)/2.0, CONTROLLER_BTN_H_W,CONTROLLER_BTN_H_W);
            }
            
        }else{
            
            if ([AppDelegate sharedDefault].isDoorBellAlarm) {
                //布防撤防
                TouchButton *controllerDefenceBtn = (TouchButton *)[self.controllBar viewWithTag:CONTROLLER_BTN_TAG_DEFENCE_LOCK];
                [controllerDefenceBtn setHidden:NO];
                //输出6秒高电平脉冲按钮
                TouchButton *controllerDoorLockBtn = (TouchButton *)[self.controllBar viewWithTag:CONTROLLER_BTN_TAG_GPIO1_0];
                [controllerDoorLockBtn setHidden:NO];
                
            }else{
                //布防撤防
                TouchButton *controllerDefenceBtn = (TouchButton *)[self.controllBar viewWithTag:CONTROLLER_BTN_TAG_DEFENCE_LOCK];
                [controllerDefenceBtn setHidden:NO];
                //输出6秒高电平脉冲按钮
                TouchButton *controllerDoorLockBtn = (TouchButton *)[self.controllBar viewWithTag:CONTROLLER_BTN_TAG_GPIO1_0];
                [controllerDoorLockBtn setHidden:YES];
            }
            
            
            if(i==0){//布防撤防
                TouchButton *controllerDefenceBtn = (TouchButton *)[self.controllBar viewWithTag:CONTROLLER_BTN_TAG_DEFENCE_LOCK];
                controllerDefenceBtn.frame = CGRectMake(PUBLIC_WIDTH_OR_HEIGHT*i+firstControllerBtnX, (BOTTOM_BAR_HEIGHT-CONTROLLER_BTN_H_W)/2.0, CONTROLLER_BTN_H_W,CONTROLLER_BTN_H_W);
                
            }else if(i==1){//声音开关
                TouchButton *controllerSoundBtn = (TouchButton *)[self.controllBar viewWithTag:CONTROLLER_BTN_TAG_SOUND];
                controllerSoundBtn.frame = CGRectMake(PUBLIC_WIDTH_OR_HEIGHT*i+firstControllerBtnX, (BOTTOM_BAR_HEIGHT-CONTROLLER_BTN_H_W)/2.0, CONTROLLER_BTN_H_W,CONTROLLER_BTN_H_W);
                
            }else if(i==2){//按住说话开关
                TouchButton *controllerTalkBtn = (TouchButton *)[self.controllBar viewWithTag:CONTROLLER_BTN_TAG_PRESS_TALK];
                controllerTalkBtn.frame = CGRectMake(PUBLIC_WIDTH_OR_HEIGHT*i+firstControllerBtnX, (BOTTOM_BAR_HEIGHT-CONTROLLER_BTN_H_W)/2.0, CONTROLLER_BTN_H_W,CONTROLLER_BTN_H_W);
                
            }else if(i==3){//截图开关
                TouchButton *controllerScreenshotBtn = (TouchButton *)[self.controllBar viewWithTag:CONTROLLER_BTN_TAG_SCREENSHOT];
                controllerScreenshotBtn.frame = CGRectMake(PUBLIC_WIDTH_OR_HEIGHT*i+firstControllerBtnX, (BOTTOM_BAR_HEIGHT-CONTROLLER_BTN_H_W)/2.0, CONTROLLER_BTN_H_W,CONTROLLER_BTN_H_W);
                
            }else if(i==4){//输出6秒高电平脉冲按钮
                TouchButton *controllerDoorLockBtn = (TouchButton *)[self.controllBar viewWithTag:CONTROLLER_BTN_TAG_GPIO1_0];
                controllerDoorLockBtn.frame = CGRectMake(PUBLIC_WIDTH_OR_HEIGHT*i+firstControllerBtnX, (BOTTOM_BAR_HEIGHT-CONTROLLER_BTN_H_W)/2.0, CONTROLLER_BTN_H_W,CONTROLLER_BTN_H_W);
                
            }
        }
    }
    
}

#pragma mark - 监控竖屏时，各控件初始化

#define LOADINGPRESSVIEW_WIDTH_HEIGHT (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 50:30)
-(void)initComponentForPortrait{
    
    //view的背景颜色
    [self.view setBackgroundColor:UIColorFromRGB(0xf6f7f8)];
    
    
    //显示状态栏
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
    
    //取得竖屏的rect
    CGRect rect = [AppDelegate getScreenSize:YES isHorizontal:NO];
    CGFloat width = rect.size.width;
    
    CGFloat height = rect.size.height;
    if(CURRENT_VERSION<7.0){
        height +=20;
    }
    
    
    
    //导航栏
    CustomTopBar *topBar = [[CustomTopBar alloc] initWithFrame:CGRectMake(0, 0, width, NAVIGATION_BAR_HEIGHT)];
    [topBar setBackgroundImageViewWith:[UIImage imageNamed:@"bg_navigation_bar.png"] withBackgroundColor:nil];
    //视频监控连接中的标题
    NSString *deviceName = @"";
    if ([[AppDelegate sharedDefault] dwApContactID] == 0) {
        NSString *contactId = [[P2PClient sharedClient] callId];
        deviceName = [NSString stringWithFormat:@"Cam%@",contactId];
        
        ContactDAO *contactDAO = [[ContactDAO alloc] init];
        Contact *contact = [contactDAO isContact:contactId];
        NSString *contactName = contact.contactName;
        [contactDAO release];
        if (contactName) {
            deviceName = contactName;
        }
    }else{
        deviceName = [NSString stringWithFormat:@"Cam%d", [[AppDelegate sharedDefault] dwApContactID]];
    }
    [topBar setTitle:deviceName];
    [topBar setBackButtonHidden:NO];
    [topBar setBackButtonIcon:[UIImage imageNamed:@"menuback.png"]];
    [topBar.backButton addTarget:self action:@selector(btnClickToBack:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:topBar];
    self.topBar = topBar;//全屏时，隐藏
    [topBar release];
    
    
    //显示监控画面的载体canvasView
    CGFloat canvasView_h = [UIScreen mainScreen].bounds.size.width * 9/16;
    UIView *canvasView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(topBar.frame), width, canvasView_h)];
    canvasView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:canvasView];
    self.canvasView = canvasView;
    self.canvasframe = canvasView.frame;
    [canvasView release];
    //视频监控连接中的背景图片
    NSString *filePath = [Utils getHeaderFilePathWithId:[[P2PClient sharedClient] callId]];
    UIImage *headImg = [UIImage imageWithContentsOfFile:filePath];
    if(headImg==nil){
        headImg = [UIImage imageNamed:@"ic_header.png"];
    }
    self.canvasView.layer.contents = (id)headImg.CGImage;
    
    
    //视频监控连接中或者连接失败的文字提示，以及旋转或者重连图片
    UIButton *promptButton = [UIButton buttonWithType:UIButtonTypeCustom];
    promptButton.frame = CGRectMake(0.0, 0.0, self.canvasView.frame.size.width, self.canvasView.frame.size.height);
    promptButton.backgroundColor = [UIColor clearColor];
    promptButton.tag = PROMPT_BUTTON_TAG;
    [promptButton addTarget:self action:@selector(onVerticalBtnPress:) forControlEvents:UIControlEventTouchUpInside];
    [self.canvasView addSubview:promptButton];
    self.promptButton = promptButton;
    //文字frame
    NSString *labelTipText = [NSString stringWithFormat:@"%@",NSLocalizedString(@"玩命加载中...", nil)];
    CGSize size = [labelTipText sizeWithFont:XFontBold_16];
    CGFloat labelTip_w = size.width+10.0;
    CGFloat labelTip_h = size.height;
    //图片frame
    CGFloat progressView_wh = LOADINGPRESSVIEW_WIDTH_HEIGHT;
    CGFloat progressView_y = (self.canvasView.frame.size.height-labelTip_h-progressView_wh)/2;
    //旋转或者重连图片
    ProgressImageView *progressView = [[ProgressImageView alloc] initWithFrame:CGRectMake((width-progressView_wh)/2, progressView_y, progressView_wh, progressView_wh)];
    progressView.backgroundView.image = [UIImage imageNamed:@"monitor_press.png"];
    [self.promptButton addSubview:progressView];
    [progressView start];
    self.yProgressView = progressView;
    [progressView release];
    //视频监控连接中或者连接失败的文字提示
    UILabel* labelTip = [[UILabel alloc] initWithFrame:CGRectMake((width-labelTip_w)/2, progressView_y+progressView_wh, labelTip_w, labelTip_h)];
    labelTip.backgroundColor = [UIColor clearColor];
    labelTip.text = [NSString stringWithFormat:@"%@",NSLocalizedString(@"monitor_out_prompt", nil)];
    labelTip.textAlignment = NSTextAlignmentCenter;
    labelTip.font = XFontBold_16;
    labelTip.textColor = XWhite;
    [self.promptButton addSubview:labelTip];
    self.labelTip = labelTip;
    [labelTip release];
    
    
    
    //显示监控的画布OpenGLView
    OpenGLView *glView = [[OpenGLView alloc] init];
    glView.frame = CGRectMake(0.0, 0.0, self.canvasView.frame.size.width, self.canvasView.frame.size.height);
    self.remoteView = glView;
    self.remoteView.delegate = self;
    [self.remoteView.layer setMasksToBounds:YES];
    [self.canvasView addSubview:self.remoteView];
    [glView release];
    
    //上划手势
    UISwipeGestureRecognizer *swipeGestureUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeUp:)];
    [swipeGestureUp setDirection:UISwipeGestureRecognizerDirectionUp];
    [swipeGestureUp setCancelsTouchesInView:YES];
    [swipeGestureUp setDelaysTouchesEnded:YES];
    [_remoteView addGestureRecognizer:swipeGestureUp];
    
    //下划手势
    UISwipeGestureRecognizer *swipeGestureDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeDown:)];
    [swipeGestureDown setDirection:UISwipeGestureRecognizerDirectionDown];
    
    [swipeGestureDown setCancelsTouchesInView:YES];
    [swipeGestureDown setDelaysTouchesEnded:YES];
    [_remoteView addGestureRecognizer:swipeGestureDown];
    
    //左划手势
    UISwipeGestureRecognizer *swipeGestureLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
    [swipeGestureLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
    [swipeGestureLeft setCancelsTouchesInView:YES];
    [swipeGestureLeft setDelaysTouchesEnded:YES];
    [_remoteView addGestureRecognizer:swipeGestureLeft];
    
    //右划手势
    UISwipeGestureRecognizer *swipeGestureRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
    [swipeGestureRight setDirection:UISwipeGestureRecognizerDirectionRight];
    [swipeGestureRight setCancelsTouchesInView:YES];
    [swipeGestureRight setDelaysTouchesEnded:YES];
    [_remoteView addGestureRecognizer:swipeGestureRight];
    
    [swipeGestureUp release];
    [swipeGestureDown release];
    [swipeGestureLeft release];
    [swipeGestureRight release];
    
    //左边的按住说话弹出的声音图标
    //进入横屏时，调整frame
    //退出横屏时，也调整frame
    UIView *pressView = [[UIView alloc] initWithFrame:CGRectMake(10, self.canvasframe.size.height+NAVIGATION_BAR_HEIGHT-PRESS_LAYOUT_WIDTH_AND_HEIGHT, PRESS_LAYOUT_WIDTH_AND_HEIGHT/2, PRESS_LAYOUT_WIDTH_AND_HEIGHT)];
    
    UIImageView *pressLeftView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, PRESS_LAYOUT_WIDTH_AND_HEIGHT/2, PRESS_LAYOUT_WIDTH_AND_HEIGHT)];
    pressLeftView.image = [UIImage imageNamed:@"ic_voice.png"];
    [pressView addSubview:pressLeftView];
    [pressLeftView release];
    
    UIImageView *pressRightView = [[UIImageView alloc] initWithFrame:CGRectMake(PRESS_LAYOUT_WIDTH_AND_HEIGHT/2, 0, PRESS_LAYOUT_WIDTH_AND_HEIGHT/2, PRESS_LAYOUT_WIDTH_AND_HEIGHT)];
    NSArray *imagesArray = [NSArray arrayWithObjects:[UIImage imageNamed:@"amp1.png"],[UIImage imageNamed:@"amp2.png"],[UIImage imageNamed:@"amp3.png"],[UIImage imageNamed:@"amp4.png"],[UIImage imageNamed:@"amp5.png"],[UIImage imageNamed:@"amp6.png"],[UIImage imageNamed:@"amp7.png"],[UIImage imageNamed:@"amp4.png"],[UIImage imageNamed:@"amp5.png"],[UIImage imageNamed:@"amp6.png"],[UIImage imageNamed:@"amp3.png"],[UIImage imageNamed:@"amp5.png"],[UIImage imageNamed:@"amp6.png"],[UIImage imageNamed:@"amp6.png"],[UIImage imageNamed:@"amp3.png"],[UIImage imageNamed:@"amp4.png"],[UIImage imageNamed:@"amp5.png"],[UIImage imageNamed:@"amp5.png"],nil];
    pressRightView.animationImages = imagesArray;
    pressRightView.animationDuration = ((CGFloat)[imagesArray count])*200.0f/1000.0f;
    pressRightView.animationRepeatCount = 0;
    [pressRightView startAnimating];
    [pressView addSubview:pressRightView];
    [pressRightView release];
    
    [self.view addSubview:pressView];
    [pressView setHidden:YES];
    self.pressView = pressView;
    [pressView release];
    
    
    
    //声音、横屏工具栏
    UIView *midToolHView = [[UIView alloc] initWithFrame:CGRectMake(0.0, CGRectGetMaxY(self.canvasView.frame), width, 79.0/SCREEN_SCALE)];
    midToolHView.backgroundColor = XWhite;
    [self.view addSubview:midToolHView];
    self.midToolHView = midToolHView;//全屏时，隐藏
    [midToolHView release];
    //2个像素点的线
    UIView *bottomLineView = [[UIView alloc] initWithFrame:CGRectMake(0.0,self.midToolHView.frame.size.height-ONE_PIXEL_SIZE*2, width, ONE_PIXEL_SIZE*2)];
    bottomLineView.backgroundColor = UIColorFromRGB(0x000000);
    [bottomLineView setAlpha:0.2];
    [self.midToolHView addSubview:bottomLineView];
    [bottomLineView release];
    //声音按钮
    UIButton *soundButtonH = [UIButton buttonWithType:UIButtonTypeCustom];
    soundButtonH.frame = CGRectMake(101.0/SCREEN_SCALE, (self.midToolHView.frame.size.height-22.0)/2, 22.0, 22.0);
    soundButtonH.tag = SOUND_BUTTON_H_TAG;
    [soundButtonH addTarget:self action:@selector(onVerticalBtnPress:) forControlEvents:UIControlEventTouchUpInside];
    [self.midToolHView addSubview:soundButtonH];
    //self.soundButtonH = soundButtonH;
    //声音按钮图片
    UIImage *soundImageH = [UIImage imageNamed:@"monitor_sound_on_h.png"];
    UIImageView *soundImageViewH = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, (soundButtonH.frame.size.height-soundImageH.size.height/SCREEN_SCALE)/2, soundImageH.size.width/SCREEN_SCALE, soundImageH.size.height/SCREEN_SCALE)];
    soundImageViewH.image = soundImageH;
    [soundButtonH addSubview:soundImageViewH];
    [soundImageViewH release];
    //横屏按钮
    UIButton *switchScreenButtonH = [UIButton buttonWithType:UIButtonTypeCustom];
    switchScreenButtonH.frame = CGRectMake(self.midToolHView.frame.size.width-101.0/SCREEN_SCALE-22.0, (self.midToolHView.frame.size.height-22.0)/2, 22.0, 22.0);
    switchScreenButtonH.tag = SWITCH_SCREEN_BUTTON_H_TAG;
    [switchScreenButtonH addTarget:self action:@selector(onVerticalBtnPress:) forControlEvents:UIControlEventTouchUpInside];
    [self.midToolHView addSubview:switchScreenButtonH];
    //self.switchScreenButtonH = switchScreenButtonH;
    //横屏按钮图片
    UIImage *switchScreenImageH = [UIImage imageNamed:@"monitor_switch_screen_img_h.png"];
    UIImageView *switchScreenImageViewH = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, (switchScreenButtonH.frame.size.height-switchScreenImageH.size.height/SCREEN_SCALE)/2, switchScreenImageH.size.width/SCREEN_SCALE, switchScreenImageH.size.height/SCREEN_SCALE)];
    switchScreenImageViewH.image = switchScreenImageH;
    [switchScreenButtonH addSubview:switchScreenImageViewH];
    [switchScreenImageViewH release];
    
    
    //布防撤防、对讲、截图工具栏
    UIView *bottomToolHView = [[UIView alloc] initWithFrame:CGRectMake(0.0, CGRectGetMaxY(self.midToolHView.frame), width, height-CGRectGetMaxY(self.midToolHView.frame))];
    bottomToolHView.backgroundColor = UIColorFromRGB(0xf6f7f8);
    [self.view addSubview:bottomToolHView];
    self.bottomToolHView = bottomToolHView;//全屏时，隐藏
    [bottomToolHView release];
    
    //布防撤防、载图按钮宽高
    CGFloat defenceScreenshotBtnH_wh = 70.0;
    //对讲按钮的宽高
    CGFloat talkBtnH_wh = 110.0;
    //按钮之间的间隔
    CGFloat spacing_btn_button = 20.0/SCREEN_SCALE;
    //左右的边距
    CGFloat left_right_margin = (width-defenceScreenshotBtnH_wh*2-talkBtnH_wh-spacing_btn_button*2)/2;
    //布防撤防按钮
    UIButton *defenceButtonH = [UIButton buttonWithType:UIButtonTypeCustom];
    defenceButtonH.frame = CGRectMake(left_right_margin, (self.bottomToolHView.frame.size.height-defenceScreenshotBtnH_wh)/2, defenceScreenshotBtnH_wh, defenceScreenshotBtnH_wh);
    defenceButtonH.tag = DEFENCE_BUTTON_H_TAG;
    [defenceButtonH setImage:[UIImage imageNamed:@"monitor_defence_off_h.png"] forState:UIControlStateNormal];
    [defenceButtonH setImage:[UIImage imageNamed:@"monitor_defence_off_h_p.png"] forState:UIControlStateHighlighted];
    //不可以点击，等到获取到布防状态，设置为可点且显示相应的图标
    defenceButtonH.enabled = NO;
    [defenceButtonH addTarget:self action:@selector(onVerticalBtnPress:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomToolHView addSubview:defenceButtonH];
    self.defenceButtonH = defenceButtonH;
    //对讲按钮
    UIButton *talkButtonH = [UIButton buttonWithType:UIButtonTypeCustom];
    talkButtonH.frame = CGRectMake(left_right_margin+defenceScreenshotBtnH_wh+spacing_btn_button, (self.bottomToolHView.frame.size.height-talkBtnH_wh)/2, talkBtnH_wh, talkBtnH_wh);
    talkButtonH.tag = TALK_BUTTON_H_TAG;
    [talkButtonH setImage:[UIImage imageNamed:@"monitor_speak_img_h.png"] forState:UIControlStateNormal];
    [talkButtonH setImage:[UIImage imageNamed:@"monitor_speak_img_h_p.png"] forState:UIControlStateHighlighted];
    [talkButtonH setImage:[UIImage imageNamed:@"monitor_speak_img_h_p.png"] forState:UIControlStateSelected];
    
    [talkButtonH addTarget:self action:@selector(onVerticalBtnPress:) forControlEvents:UIControlEventTouchUpInside];
    [talkButtonH addTarget:self action:@selector(onVerticalBtnTouchDown:) forControlEvents:UIControlEventTouchDown];
    [talkButtonH addTarget:self action:@selector(onVerticalBtnTouchCancel:) forControlEvents:UIControlEventTouchCancel];
    [talkButtonH addTarget:self action:@selector(onVerticalBtnTouchCancel:) forControlEvents:UIControlEventTouchDragExit];
    [self.bottomToolHView addSubview:talkButtonH];
    //载图按钮
    UIButton *screenshotBtnH = [UIButton buttonWithType:UIButtonTypeCustom];
    screenshotBtnH.frame = CGRectMake(CGRectGetMaxX(talkButtonH.frame)+spacing_btn_button, (self.bottomToolHView.frame.size.height-defenceScreenshotBtnH_wh)/2, defenceScreenshotBtnH_wh, defenceScreenshotBtnH_wh);
    screenshotBtnH.tag = SCREENSHOT_BUTTON_H_TAG;
    [screenshotBtnH setImage:[UIImage imageNamed:@"monitor_screenshot_h.png"] forState:UIControlStateNormal];
    [screenshotBtnH setImage:[UIImage imageNamed:@"monitor_screenshot_h_p.png"] forState:UIControlStateHighlighted];
    
    [screenshotBtnH addTarget:self action:@selector(onVerticalBtnPress:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomToolHView addSubview:screenshotBtnH];
}

#pragma mark 按下按钮时，响应
-(void)onVerticalBtnTouchCancel:(UIButton *)button{
    switch(button.tag){
        case SOUND_BUTTON_H_TAG://声音
        {
            
        }
            break;
        case SWITCH_SCREEN_BUTTON_H_TAG://横屏
        {
            
        }
            break;
        case DEFENCE_BUTTON_H_TAG://布防撤防
        {
            
        }
            break;
        case TALK_BUTTON_H_TAG:
        {
            [self.pressView setHidden:YES];
            [[PAIOUnit sharedUnit] setSpeckState:YES];
            
        }
            break;
        case SCREENSHOT_BUTTON_H_TAG://载图
        {
            
        }
            break;
        case PROMPT_BUTTON_TAG://重新连接监控
        {
            
        }
            break;
    }
}

#pragma mark 按下按钮时，响应
-(void)onVerticalBtnTouchDown:(UIButton *)button{
    switch(button.tag){
        case SOUND_BUTTON_H_TAG://声音
        {
            
        }
            break;
        case SWITCH_SCREEN_BUTTON_H_TAG://横屏
        {
            
        }
            break;
        case DEFENCE_BUTTON_H_TAG://布防撤防
        {
            
        }
            break;
        case TALK_BUTTON_H_TAG://按下开始对讲
        {
            //非本地设备
            NSInteger deviceType1 = [AppDelegate sharedDefault].contact.contactType;
            //本地设备
            NSInteger deviceType2 = [[FListManager sharedFList] getType:[[P2PClient sharedClient] callId]];
            if (deviceType1 != CONTACT_TYPE_DOORBELL && deviceType2 != CONTACT_TYPE_DOORBELL) {//不支持门铃，按下开始对讲
                [self.pressView setHidden:NO];
                [[PAIOUnit sharedUnit] setSpeckState:NO];
            }
            
        }
            break;
        case SCREENSHOT_BUTTON_H_TAG://载图
        {
            
        }
            break;
        case PROMPT_BUTTON_TAG://重新连接监控
        {
            
        }
            break;
    }
}

#pragma mark 点击竖屏上的按钮时，响应
-(void)onVerticalBtnPress:(UIButton *)button{
    switch(button.tag){
        case SOUND_BUTTON_H_TAG://声音
        {
            if (!_isOkRenderVideoFrame) {
                //图像渲染出来前，不可以控制声音
                return;
            }
            
            UIImageView *soundImageViewH = (UIImageView *)button.subviews[0];
            BOOL isMute = [[PAIOUnit sharedUnit] muteAudio];
            if(isMute){
                [[PAIOUnit sharedUnit] setMuteAudio:NO];
                soundImageViewH.image = [UIImage imageNamed:@"monitor_sound_on_h.png"];
                //横屏，声音打开
                UIButton *controllerSoundBtn = (UIButton *)[self.controllBar viewWithTag:CONTROLLER_BTN_TAG_SOUND];
                [controllerSoundBtn setBackgroundImage:[UIImage imageNamed:@"ic_ctl_new_sound_on.png"] forState:UIControlStateNormal];
            }else{
                
                [[PAIOUnit sharedUnit] setMuteAudio:YES];
                soundImageViewH.image = [UIImage imageNamed:@"monitor_sound_off_h.png"];
                //横屏，声音关闭
                UIButton *controllerSoundBtn = (UIButton *)[self.controllBar viewWithTag:CONTROLLER_BTN_TAG_SOUND];
                [controllerSoundBtn setBackgroundImage:[UIImage imageNamed:@"ic_ctl_new_sound_off.png"] forState:UIControlStateNormal];
            }
        }
            break;
        case SWITCH_SCREEN_BUTTON_H_TAG://切换至横屏或者竖屏
        {
            if (!_isOkFirstRenderVideoFrame) {
                //第一次成功渲染图像前，不可以切换至横屏
                return;
            }
            if (!self.isFullScreen)
            {
                if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)])
                {
                    [[UIDevice currentDevice] performSelector:@selector(setOrientation:)
                                                   withObject:(id)UIInterfaceOrientationLandscapeRight];
                }
            }
            else
            {
                if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)])
                {
                    [[UIDevice currentDevice] performSelector:@selector(setOrientation:)
                                                   withObject:(id)UIDeviceOrientationPortrait];
                }
            }
        }
            break;
        case DEFENCE_BUTTON_H_TAG://布防撤防
        {
            NSString *contactId = [[P2PClient sharedClient] callId];
            NSString *contactPassword = [[P2PClient sharedClient] callPassword];
            
            if (self.isDefenceOn) {
                [[P2PClient sharedClient] setRemoteDefenceWithId:contactId password:contactPassword state:SETTING_VALUE_REMOTE_DEFENCE_STATE_OFF];
            }else{
                [[P2PClient sharedClient] setRemoteDefenceWithId:contactId password:contactPassword state:SETTING_VALUE_REMOTE_DEFENCE_STATE_ON];
            }
        }
            break;
        case TALK_BUTTON_H_TAG://对讲
        {
            //非本地设备
            NSInteger deviceType1 = [AppDelegate sharedDefault].contact.contactType;
            //本地设备
            NSInteger deviceType2 = [[FListManager sharedFList] getType:[[P2PClient sharedClient] callId]];
            if (deviceType1 == CONTACT_TYPE_DOORBELL || deviceType2 == CONTACT_TYPE_DOORBELL) {//支持门铃,点按开关说话
                if (self.isTalking) {
                    
                    self.isTalking = NO;
                    [self.pressView setHidden:YES];
                    [[PAIOUnit sharedUnit] setSpeckState:YES];
                    
                    //竖屏，对讲关闭
                    button.selected = NO;
                    //横屏，对讲关闭
                    UIButton *controllerTalkBtn = (UIButton *)[self.controllBar viewWithTag:CONTROLLER_BTN_TAG_PRESS_TALK];
                    [controllerTalkBtn setBackgroundImage:[UIImage imageNamed:@"ic_ctl_new_send_audio.png"] forState:UIControlStateNormal];
                }else{
                    
                    self.isTalking = YES;
                    [self.pressView setHidden:NO];
                    [[PAIOUnit sharedUnit] setSpeckState:NO];
                    
                    //竖屏，对讲打开
                    button.selected = YES;
                    //横屏，对讲打开
                    UIButton *controllerTalkBtn = (UIButton *)[self.controllBar viewWithTag:CONTROLLER_BTN_TAG_PRESS_TALK];
                    [controllerTalkBtn setBackgroundImage:[UIImage imageNamed:@"ic_ctl_new_send_audio_p.png"] forState:UIControlStateNormal];
                }
                
            }else{
                //不支持门铃，松开结束对讲
                [self.pressView setHidden:YES];
                [[PAIOUnit sharedUnit] setSpeckState:YES];
            }
        }
            break;
        case SCREENSHOT_BUTTON_H_TAG://载图
        {
            [self.remoteView setIsScreenShotting:YES];
        }
            break;
        case PROMPT_BUTTON_TAG://重新连接监控
        {
            [self hiddenMonitoringUI:NO callErrorInfo:nil isReCall:YES];
            [self monitorP2PCall];
        }
            break;
    }
}

#pragma mark - 开灯或关灯
-(void)btnClickToSetLightState:(UIButton *)button{
    NSString *contactId = [[P2PClient sharedClient] callId];
    NSString *contactPassword = [[P2PClient sharedClient] callPassword];
    if (self.isLightSwitchOn) {//灯正开着
        
        [self.lightButton setHidden:YES];
        [self.progressView setHidden:NO];
        [self.progressView startAnimating];
        
        [[P2PClient sharedClient] setLightStateWithDeviceId:contactId password:contactPassword switchState:0];//关灯
    }else{
        
        [self.lightButton setHidden:YES];
        [self.progressView setHidden:NO];
        [self.progressView startAnimating];
        
        [[P2PClient sharedClient] setLightStateWithDeviceId:contactId password:contactPassword switchState:1];//开灯
    }
    
}

#pragma mark - 返回
-(void)btnClickToBack:(UIButton *)button{
    if(!self.isReject){
        self.isReject = !self.isReject;
        while (_isPlaying) {
            usleep(50*1000);
        }
        
        [[P2PClient sharedClient] p2pHungUp];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)showLeftView:(UIButton *)button{
    
    if (!self.isShowLeftView) {
        self.isShowLeftView = YES;
        [self.leftView setHidden:NO];
        [UIView animateWithDuration:0.2 animations:^{
            CGRect leftViewRect = self.leftView.frame;
            leftViewRect.origin.x = 0;
            self.leftView.frame = leftViewRect;
            
            CGRect customBorderButtoRect = self.customBorderButton.frame;
            customBorderButtoRect.origin.x = LEFTVIEW_WIDTH;
            self.customBorderButton.frame = customBorderButtoRect;
            
            [self.customBorderButton setImage:[UIImage imageNamed:@"button_left"] forState:UIControlStateNormal];
            [self.customBorderButton setImage:[UIImage imageNamed:@"button_left_selected"] forState:UIControlStateHighlighted];
        } completion:^(BOOL finished) {
            
        }];
    }else{
        self.isShowLeftView = NO;
        [UIView animateWithDuration:0.2 animations:^{
            CGRect leftViewRect = self.leftView.frame;
            leftViewRect.origin.x = -LEFTVIEW_WIDTH;
            self.leftView.frame = leftViewRect;
            
            CGRect customBorderButtoRect = self.customBorderButton.frame;
            customBorderButtoRect.origin.x = 0;
            self.customBorderButton.frame = customBorderButtoRect;
            
            [self.customBorderButton setImage:[UIImage imageNamed:@"button_right"] forState:UIControlStateNormal];
            [self.customBorderButton setImage:[UIImage imageNamed:@"button_right_selected"] forState:UIControlStateHighlighted];
        } completion:^(BOOL finished) {
            [self.leftView setHidden:YES];
        }];
    }
    
}

-(void)onOrOffButtonClick:(UIButton *)button{
    
    //
    int group, pin;
    int value = 5;
    int time[8] = {0};
    time[0] = -1000;
    time[1] = 1000;
    time[2] = -1000;
    time[3] = 1000;
    time[4] = -1000;
    switch (button.tag) {
        case GPIO0_0:
        {
            group = 0;
            pin = 0;
            self.clickGPIO0_0Button = button;
            self.clickGPIO0_0Button.backgroundColor = XBlue;
        }
            break;
        case GPIO0_1:
        {
            group = 0;
            pin = 1;
            self.clickGPIO0_1Button = button;
            self.clickGPIO0_1Button.backgroundColor = XBlue;
        }
            break;
        case GPIO0_2:
        {
            group = 0;
            pin = 2;
            self.clickGPIO0_2Button = button;
            self.clickGPIO0_2Button.backgroundColor = XBlue;
        }
            break;
        case GPIO0_3:
        {
            group = 0;
            pin = 3;
            self.clickGPIO0_3Button = button;
            self.clickGPIO0_3Button.backgroundColor = XBlue;
        }
            break;
        case GPIO0_4:
        {
            group = 0;
            pin = 4;
            self.clickGPIO0_4Button = button;
            self.clickGPIO0_4Button.backgroundColor = XBlue;
        }
            break;
        case GPIO2_6:
        {
            group = 2;
            pin = 6;
            self.clickGPIO2_6Button = button;
            self.clickGPIO2_6Button.backgroundColor = XBlue;
        }
            break;
    }
    
    //记录当前的GPIO设置参数
    self.lastGroup = group;
    self.lastPin = pin;
    self.lastValue = value;
    self.lastTime = time;
    
    NSString *contactId = [[P2PClient sharedClient] callId];
    NSString *contactPassword = [[P2PClient sharedClient] callPassword];
    [[P2PClient sharedClient] setGpioCtrlWithId:contactId password:contactPassword group:group pin:pin value:value time:time];
}

- (TouchButton *)getBottomBarButton//重新调整监控画面
{
    TouchButton *button = [TouchButton buttonWithType:UIButtonTypeCustom];
    [button setFrame:CGRectMake(0.0, 0.0, 50.0, 50.0)];
    return button;
}

-(void)didShowResolutionInterface{
    BOOL is16B9 = [[P2PClient sharedClient] is16B9];
    BOOL is960P = [[P2PClient sharedClient] is960P];
    //右边的画质图标
    int rightItemCount = 0;
    if(is16B9 || is960P){
        rightItemCount = 3;
    }else{
        rightItemCount = 2;
    }
    
    [UIView animateWithDuration:0.2 animations:^{
        CGRect controllerRight = self.controllerRight.frame;
        controllerRight.origin.y = _horizontalScreenH-BOTTOM_BAR_HEIGHT-CONTROLLER_RIGHT_ITEM_HEIGHT*3-1.0;
        self.controllerRight.frame = controllerRight;
        
        CGRect controllerRightBgRect = self.controllerRightBg.frame;
        controllerRightBgRect.origin.y = _horizontalScreenH-BOTTOM_BAR_HEIGHT-CONTROLLER_RIGHT_ITEM_HEIGHT*rightItemCount-1.0;
        self.controllerRightBg.frame = controllerRightBgRect;
        
    } completion:^(BOOL finished) {
        self.isAlreadyShowResolution = YES;
    }];
    
}

-(void)didHiddenResolutionInterface{
    [UIView animateWithDuration:0.2 animations:^{
        CGRect controllerRight = self.controllerRight.frame;
        controllerRight.origin.y = _horizontalScreenH;
        self.controllerRight.frame = controllerRight;
        self.controllerRightBg.frame = controllerRight;
        
    } completion:^(BOOL finished) {
        self.isAlreadyShowResolution = NO;
    }];
}

-(void)selectResolutionClick:(UIButton *)button{//重新调整监控画面
    
    
    if (self.isAlreadyShowResolution) {
        [self didHiddenResolutionInterface];
    }else{
        [self didShowResolutionInterface];
    }
    
}

#pragma mark - 电子放大
//监控界面缩放
-(UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    //进入全屏时，方可允许操作缩放功能
    if (self.isFullScreen) {
        return self.remoteView;
    }
    
    return nil;
}

//监控界面缩放
-(void)scrollViewDidZoom:(UIScrollView *)scrollView{
    if (self.isFullScreen) {
        CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width)?(scrollView.bounds.size.width - scrollView.contentSize.width)/2 : 0.0;
        CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height)?(scrollView.bounds.size.height - scrollView.contentSize.height)/2 : 0.0;
        self.remoteView.center = CGPointMake(scrollView.contentSize.width/2 + offsetX,scrollView.contentSize.height/2 + offsetY);
    }
}

//监控界面缩放
-(void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale{
    
    if(scale>1.0){
        if (self.isShowControllerBar) {
            self.isShowControllerBar = !self.isShowControllerBar;
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.2];
            [self.controllerRightBg setAlpha:0.0];
            [self.controllerRight setAlpha:0.0];
            [self.bottomView setAlpha:0.0];
            [self.bottomBarView setAlpha:0.0];
            [self.customBorderButton setAlpha:0.0];
            [self.leftView setAlpha:0.0];
            [UIView commitAnimations];
        }
        
    }
    
    
    if (self.isFullScreen) {
        if(scale>1.0){
            self.isScale = YES;
        }else{
            self.isScale = NO;
        }
    }
}

#pragma mark - 对讲
-(void)onBegin:(TouchButton *)touchButton widthTouches:(NSSet *)touches withEvent:(UIEvent *)event{
    DLog(@"onBegin");
    [self.pressView setHidden:NO];
    [[PAIOUnit sharedUnit] setSpeckState:NO];
}

-(void)onCancelled:(TouchButton *)touchButton widthTouches:(NSSet *)touches withEvent:(UIEvent *)event{
    DLog(@"onCancelled");
    [self.pressView setHidden:YES];
    [[PAIOUnit sharedUnit] setSpeckState:YES];
}

-(void)onEnded:(TouchButton *)touchButton widthTouches:(NSSet *)touches withEvent:(UIEvent *)event{
    DLog(@"onEnded");
    [self.pressView setHidden:YES];
    [[PAIOUnit sharedUnit] setSpeckState:YES];
}

-(void)onMoved:(TouchButton *)touchButton widthTouches:(NSSet *)touches withEvent:(UIEvent *)event{
    DLog(@"onMoved");
}

#pragma mark - 横屏时的按钮（画质、声音...）
-(void)onControllerBtnPress:(id)sender{
    UIButton *button = (UIButton*)sender;
    switch(button.tag){
        case CONTROLLER_BTN_TAG_HUNGUP:
        {
            if(!self.isReject){
                self.isReject = !self.isReject;
                while (_isPlaying) {
                    usleep(50*1000);
                }
                [[P2PClient sharedClient] p2pHungUp];
                
                self.remoteView.isQuitMonitorInterface = YES;//rtsp监控界面弹出修改
            }
            [self dismissViewControllerAnimated:YES completion:nil];
        }
            break;
        case CONTROLLER_BTN_TAG_SOUND:
        {
            
            BOOL isMute = [[PAIOUnit sharedUnit] muteAudio];
            
            
            DLog(@"onControllerBtnPress:CONTROLLER_BTN_TAG_SOUND");
            if(isMute){
                [[PAIOUnit sharedUnit] setMuteAudio:NO];
                [sender setBackgroundImage:[UIImage imageNamed:@"ic_ctl_new_sound_on.png"] forState:UIControlStateNormal];
                //竖屏，声音打开
                UIButton *soundButtonH = (UIButton *)[self.midToolHView viewWithTag:SOUND_BUTTON_H_TAG];
                UIImageView *soundImageViewH = (UIImageView *)soundButtonH.subviews[0];
                soundImageViewH.image = [UIImage imageNamed:@"monitor_sound_on_h.png"];
            }else{
                
                [[PAIOUnit sharedUnit] setMuteAudio:YES];
                [sender setBackgroundImage:[UIImage imageNamed:@"ic_ctl_new_sound_off.png"] forState:UIControlStateNormal];
                //竖屏，声音关闭
                UIButton *soundButtonH = (UIButton *)[self.midToolHView viewWithTag:SOUND_BUTTON_H_TAG];
                UIImageView *soundImageViewH = (UIImageView *)soundButtonH.subviews[0];
                soundImageViewH.image = [UIImage imageNamed:@"monitor_sound_off_h.png"];
            }
        }
            break;
        case CONTROLLER_BTN_TAG_SCREENSHOT:
        {
            
            [self.remoteView setIsScreenShotting:YES];
        }
            break;
        case CONTROLLER_BTN_TAG_GPIO1_0:
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"door_bell", nil) message:NSLocalizedString(@"confirm_open", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:NSLocalizedString(@"ok", nil), nil];
            [alertView show];
            [alertView release];
            
        }
            break;
        case CONTROLLER_BTN_TAG_PRESS_TALK://支持门铃,点按开关说话
        {
            if (self.isTalking) {
                //竖屏，对讲关闭
                UIButton *talkButtonH = (UIButton *)[self.bottomToolHView viewWithTag:TALK_BUTTON_H_TAG];
                talkButtonH.selected = NO;
                //横屏，对讲关闭
                [sender setBackgroundImage:[UIImage imageNamed:@"ic_ctl_new_send_audio.png"] forState:UIControlStateNormal];
                
                self.isTalking = NO;
                [self.pressView setHidden:YES];
                [[PAIOUnit sharedUnit] setSpeckState:YES];
            }else{
                UIButton *talkButtonH = (UIButton *)[self.bottomToolHView viewWithTag:TALK_BUTTON_H_TAG];
                //竖屏，对讲打开
                talkButtonH.selected = YES;
                //横屏，对讲打开
                [sender setBackgroundImage:[UIImage imageNamed:@"ic_ctl_new_send_audio_p.png"] forState:UIControlStateNormal];
                
                self.isTalking = YES;
                [self.pressView setHidden:NO];
                [[PAIOUnit sharedUnit] setSpeckState:NO];
            }
        }
            break;
        case CONTROLLER_BTN_TAG_DEFENCE_LOCK://重新调整监控画面
        {
            NSString *contactId = [[P2PClient sharedClient] callId];
            NSString *contactPassword = [[P2PClient sharedClient] callPassword];
            
            if (self.isDefenceOn) {
                [[P2PClient sharedClient] setRemoteDefenceWithId:contactId password:contactPassword state:SETTING_VALUE_REMOTE_DEFENCE_STATE_OFF];
            }else{
                [[P2PClient sharedClient] setRemoteDefenceWithId:contactId password:contactPassword state:SETTING_VALUE_REMOTE_DEFENCE_STATE_ON];
            }
        }
            break;
        case CONTROLLER_BTN_TAG_HD:
        {
            [[P2PClient sharedClient] sendCommandType:USR_CMD_VIDEO_CTL andOption:7];
            [self updateRightButtonState:CONTROLLER_BTN_TAG_HD];
            
        }
            break;
        case CONTROLLER_BTN_TAG_SD:
        {
            [[P2PClient sharedClient] sendCommandType:USR_CMD_VIDEO_CTL andOption:5];
            [self updateRightButtonState:CONTROLLER_BTN_TAG_SD];
        }
            break;
        case CONTROLLER_BTN_TAG_LD:
        {
            [[P2PClient sharedClient] sendCommandType:USR_CMD_VIDEO_CTL andOption:6];
            [self updateRightButtonState:CONTROLLER_BTN_TAG_LD];
        }
            break;
    }
}

#pragma mark - UIAlertViewDelegate（开门）
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex==1) {
        
        //GPIO口开锁
        int time[8] = {0};
        time[0] = -15;
        time[1] = 6000;
        time[2] = -1;
        //记录当前的GPIO设置参数
        self.lastGroup = 1;
        self.lastPin = 0;
        self.lastValue = 3;
        self.lastTime = time;
        NSString *contactId = [[P2PClient sharedClient] callId];
        NSString *contactPassword = [[P2PClient sharedClient] callPassword];
        [[P2PClient sharedClient] setGpioCtrlWithId:contactId password:contactPassword group:1 pin:0 value:3 time:time];
        
        
        //透传开锁
        [[P2PClient sharedClient] sendCustomCmdWithId:contactId password:contactPassword cmd:@"IPC1anerfa:unlock"];
        
    }
}

-(void)onScreenShotted:(UIImage *)image{
    UIImage *tempImage = [[UIImage alloc] initWithCGImage:image.CGImage];
    NSData *imgData = [NSData dataWithData:UIImagePNGRepresentation(tempImage)];
    [Utils saveScreenshotFile:imgData];
    [tempImage release];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view makeToast:NSLocalizedString(@"screenshot_success", nil)];
    });
    
}

#pragma mark - 设置高清、标清选中
-(void)updateRightButtonState:(NSInteger)tag{
    for(UIView *view in self.controllerRight.subviews){
        UILabel *labelHD = (UILabel *)[view viewWithTag:CONTROLLER_LABEL_TAG_HD];
        if (labelHD) {
            labelHD.textColor = XWhite;
        }
        UILabel *labelSD = (UILabel *)[view viewWithTag:CONTROLLER_LABEL_TAG_SD];
        if (labelSD) {
            labelSD.textColor = XWhite;
        }
        UILabel *labelLD = (UILabel *)[view viewWithTag:CONTROLLER_LABEL_TAG_LD];
        if (labelLD) {
            labelLD.textColor = XWhite;
        }
    }
    UIButton *button = (UIButton*)[self.controllerRight viewWithTag:tag];
    
    
    //重新调整监控画面
    UIButton *rButton = (UIButton *)[self.bottomBarView viewWithTag:CONTROLLER_BTN_TAG_RESOLUTION];
    if (tag == CONTROLLER_BTN_TAG_HD) {
        UILabel *label = (UILabel *)[button viewWithTag:CONTROLLER_LABEL_TAG_HD];
        label.textColor = XBlue;
        [rButton setTitle:NSLocalizedString(@"HD", nil) forState:UIControlStateNormal];
    }else if(tag == CONTROLLER_BTN_TAG_SD){
        UILabel *label = (UILabel *)[button viewWithTag:CONTROLLER_LABEL_TAG_SD];
        label.textColor = XBlue;
        [rButton setTitle:NSLocalizedString(@"SD", nil) forState:UIControlStateNormal];
    }else if (tag == CONTROLLER_BTN_TAG_LD){
        UILabel *label = (UILabel *)[button viewWithTag:CONTROLLER_LABEL_TAG_LD];
        label.textColor = XBlue;
        [rButton setTitle:NSLocalizedString(@"LD", nil) forState:UIControlStateNormal];
    }
    
    [self didHiddenResolutionInterface];
}

- (void)swipeUp:(id)sender {
    [[P2PClient sharedClient] sendCommandType:USR_CMD_PTZ_CTL
                                    andOption:USR_CMD_OPTION_PTZ_TURN_DOWN];
}

- (void)swipeDown:(id)sender {
    [[P2PClient sharedClient] sendCommandType:USR_CMD_PTZ_CTL
                                    andOption:USR_CMD_OPTION_PTZ_TURN_UP];
}

- (void)swipeLeft:(id)sender {
    [[P2PClient sharedClient] sendCommandType:USR_CMD_PTZ_CTL
                                    andOption:USR_CMD_OPTION_PTZ_TURN_LEFT];
}

- (void)swipeRight:(id)sender {
    [[P2PClient sharedClient] sendCommandType:USR_CMD_PTZ_CTL
                                    andOption:USR_CMD_OPTION_PTZ_TURN_RIGHT];
}

-(void)onSingleTap{
    if (!self.isFullScreen) {
        return;
    }
    
    if (self.isShowControllerBar) {
        self.isShowControllerBar = !self.isShowControllerBar;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.2];
        [self.controllerRightBg setAlpha:0.0];//重新调整监控画面
        [self.controllerRight setAlpha:0.0];
        [self.bottomView setAlpha:0.0];//重新调整监控画面
        [self.bottomBarView setAlpha:0.0];//重新调整监控画面
        [self.customBorderButton setAlpha:0.0];
        [self.leftView setAlpha:0.0];
        [self.focalLengthView setAlpha:0.0];
        [UIView commitAnimations];
    }else{
        self.isShowControllerBar = !self.isShowControllerBar;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.2];
        [self.controllerRightBg setAlpha:0.5];//重新调整监控画面
        [self.controllerRight setAlpha:1.0];//重新调整监控画面
        [self.bottomView setAlpha:0.5];//重新调整监控画面
        [self.bottomBarView setAlpha:1.0];//重新调整监控画面
        [self.customBorderButton setAlpha:0.5];
        [self.leftView setAlpha:0.5];
        [self.focalLengthView setAlpha:1.0];
        [UIView commitAnimations];
    }
    
    //重新调整监控画面
    [self didHiddenResolutionInterface];
}

-(void)onDoubleTap{
    if (!self.isFullScreen) {
        return;
    }
    if (self.isScale) {
        //处于电子放大时，不往下执行
        return;
    }
    
    BOOL is16B9 = [[P2PClient sharedClient] is16B9];
    if(!is16B9){
        CGRect rect = [AppDelegate getScreenSize:NO isHorizontal:YES];
        CGFloat width = rect.size.width;
        CGFloat height = rect.size.height;
        if(CURRENT_VERSION<7.0){
            height +=20;
        }
        
        if (self.isFullScreen4B3) {
            self.isFullScreen4B3 = !self.isFullScreen4B3;
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.2];
            CGAffineTransform transform;
            transform = CGAffineTransformMakeScale(1.0, 1.0f);
            self.remoteView.transform = transform;
            [UIView commitAnimations];
        }else{
            self.isFullScreen4B3 = !self.isFullScreen4B3;
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.2];
            if (CURRENT_VERSION>=8.0) {
                CGAffineTransform transform = CGAffineTransformMakeScale(height/(width*4/3),1.0f);
                self.remoteView.transform = transform;
            }else{
                CGAffineTransform transform = CGAffineTransformMakeScale(width/(height*4/3),1.0f);
                self.remoteView.transform = transform;
            }
            [UIView commitAnimations];
        }
    }
}

-(void)didHiddenMonitorUIWith:(BOOL)isAfterRender{
    if (!isAfterRender) {
        [self.controllerRightBg setAlpha:0.0];
        [self.controllerRight setAlpha:0.0];
        [self.bottomView setAlpha:0.0];
        [self.bottomBarView setAlpha:0.0];
        [self.customBorderButton setAlpha:0.0];
        [self.leftView setAlpha:0.0];
        [self.focalLengthView setAlpha:0.0];
        [self.pressView setAlpha:0.0];
    }else{
        [self.controllerRightBg setAlpha:0.5];
        [self.controllerRight setAlpha:1.0];
        [self.bottomView setAlpha:0.5];
        [self.bottomBarView setAlpha:1.0];
        [self.customBorderButton setAlpha:0.5];
        [self.leftView setAlpha:0.5];
        [self.focalLengthView setAlpha:1.0];
        [self.pressView setAlpha:1.0];
    }
}

#pragma mark - 计算文本的尺寸
-(CGSize)sizeWithString:(NSString*)string font:(UIFont*)font maxWidth:(CGFloat)maxWidth{
    if ([UIDevice currentDevice].systemVersion.floatValue < 7.0) {
        CGSize sizeToFit = [string sizeWithFont:font constrainedToSize:CGSizeMake(maxWidth, MAXFLOAT)];
        
        return sizeToFit;
    }else{
        NSDictionary *dict = @{NSFontAttributeName : font};
        CGRect rectToFit = [string boundingRectWithSize:CGSizeMake(maxWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:dict context:nil];
        return rectToFit.size;
    }
}

//rtsp监控界面弹出修改
#pragma mark - 渲染监控界面
-(void)monitorStartRender:(NSNotification*)notification{
    
    //监控横屏rect
    CGFloat height = _monitorInterfaceH;

    BOOL is16B9 = [[P2PClient sharedClient] is16B9];
    BOOL is960P = [[P2PClient sharedClient] is960P];
    //右边的画质图标
    //进入横屏时，显示
    //退出横屏时，隐藏
    UIView *lineView1 = self.controllerRight.subviews[0];
    UIButton *buttonHD = (UIButton *)[self.controllerRight viewWithTag:CONTROLLER_BTN_TAG_HD];
    
    UIButton *buttonSD = (UIButton *)[self.controllerRight viewWithTag:CONTROLLER_BTN_TAG_SD];
    UILabel *labelSD = (UILabel *)[buttonSD viewWithTag:CONTROLLER_LABEL_TAG_SD];
    
    UIButton *buttonLD = (UIButton *)[self.controllerRight viewWithTag:CONTROLLER_BTN_TAG_LD];
    UILabel *labelLD = (UILabel *)[buttonLD viewWithTag:CONTROLLER_LABEL_TAG_LD];
    if(is16B9 || is960P){//支持高清
        //半透明背景
        self.controllerRightBg.frame = CGRectMake(5.0, height, CONTROLLER_RIGHT_ITEM_WIDTH, CONTROLLER_RIGHT_ITEM_HEIGHT*3);
        //分隔线
        [lineView1 setHidden:NO];
        //高清按钮
        [buttonHD setHidden:NO];
        //标清文本
        labelSD.textColor = XBlue;
        //流畅文本
        labelLD.textColor = XWhite;
        
    }else{//不支持高清
        self.controllerRightBg.frame = CGRectMake(5.0, height, CONTROLLER_RIGHT_ITEM_WIDTH, CONTROLLER_RIGHT_ITEM_HEIGHT*2);
        //分隔线
        [lineView1 setHidden:YES];
        //高清按钮
        [buttonHD setHidden:YES];
        //标清文本
        labelSD.textColor = XWhite;
        //流畅文本
        labelLD.textColor = XBlue;
    }
    UIButton *resolutionButton = (UIButton *)[self.bottomBarView viewWithTag:CONTROLLER_BTN_TAG_RESOLUTION];
    if(is16B9 || is960P){//支持高清
        [resolutionButton setTitle:NSLocalizedString(@"SD", nil) forState:UIControlStateNormal];
        
    }else{//不支持高清
        [resolutionButton setTitle:NSLocalizedString(@"LD", nil) forState:UIControlStateNormal];
    }
    
    
    
    //开始渲染
    self.isReject = NO;
    [NSThread detachNewThreadSelector:@selector(renderView) toTarget:self withObject:nil];
    
    //根据访客密码监控、门铃监控来重新布局controllBar上的按钮
    [self reLayoutButtonInControlBar];
    
    [self doOperationsAfterMonitorStartRender];
    
}

#pragma mark - 改变焦距
-(void)btnClickToChangeFocalLength:(id)sender{
    UIView *view = (UIView *)sender;
    if (view.tag == FocalLength_Elongation_btnTag) {
        //焦距变长
        BYTE cmdData[5] = {0};
        cmdData[0] = 0x05;
        fgSendUserData(9, 1, cmdData, sizeof(cmdData));
    }else if (view.tag == FocalLength_Shorten_btnTag){
        //焦距变短
        BYTE cmdData[5] = {0};
        cmdData[0] = 0x15;
        fgSendUserData(9, 1, cmdData, sizeof(cmdData));
    }else{
        UISlider *focalLengthSlider = (UISlider *)view;
        if (focalLengthSlider.value < 7.5) {
            //焦距变长
            BYTE cmdData[5] = {0};
            cmdData[0] = 0x05;
            fgSendUserData(9, 1, cmdData, sizeof(cmdData));
        }else{
            //焦距变短
            BYTE cmdData[5] = {0};
            cmdData[0] = 0x15;
            fgSendUserData(9, 1, cmdData, sizeof(cmdData));
        }
        focalLengthSlider.value = 7.5;
    }
}

#pragma mark - 焦距变倍
-(void)localLengthPinchToZoom:(id)sender {
    if (!self.isFullScreen) {
        return;
    }
    
    if([(UIPinchGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
        if ([(UIPinchGestureRecognizer*)sender scale] > 1.0) {
            BYTE cmdData[5] = {0};
            cmdData[0] = 0x05;
            fgSendUserData(9, 2, cmdData, sizeof(cmdData));
        }else{
            BYTE cmdData[5] = {0};
            cmdData[0] = 0x15;
            fgSendUserData(9, 2, cmdData, sizeof(cmdData));
        }
    }
}

#pragma mark - 监控开始渲染后，此处执行相关操作
-(void)doOperationsAfterMonitorStartRender{//rtsp监控界面弹出修改
    
    /*
     *1. 应该放在监控准备就绪之后（即渲染之后）
     */
    [[PAIOUnit sharedUnit] setMuteAudio:NO];
    [[PAIOUnit sharedUnit] setSpeckState:YES];
    
    
    //放在渲染之后
    if([AppDelegate sharedDefault].isDoorBellAlarm){//门铃推送,点按开关说话
        self.isTalking = YES;
        [self.pressView setHidden:NO];
        [[PAIOUnit sharedUnit] setSpeckState:NO];
    }else{
        self.isTalking = NO;
        [self.pressView setHidden:YES];
        [[PAIOUnit sharedUnit] setSpeckState:YES];
    }
    //竖屏对讲按钮
    UIButton *talkButtonH = (UIButton *)[self.bottomToolHView viewWithTag:TALK_BUTTON_H_TAG];
    if([AppDelegate sharedDefault].isDoorBellAlarm){//门铃推送
        talkButtonH.selected = YES;
    }else{
        talkButtonH.selected = NO;
    }
    //横屏对讲按钮
    TouchButton *controllerTalkBtn = (TouchButton *)[self.controllBar viewWithTag:CONTROLLER_BTN_TAG_PRESS_TALK];
    //非本地设备
    NSInteger deviceType1 = [AppDelegate sharedDefault].contact.contactType;
    //本地设备
    NSInteger deviceType2 = [[FListManager sharedFList] getType:[[P2PClient sharedClient] callId]];
    if (deviceType1 == CONTACT_TYPE_DOORBELL || deviceType2 == CONTACT_TYPE_DOORBELL) {//支持门铃,点按开关说话
        if([AppDelegate sharedDefault].isDoorBellAlarm){//门铃推送
            
            [controllerTalkBtn setBackgroundImage:[UIImage imageNamed:@"ic_ctl_new_send_audio_p.png"] forState:UIControlStateNormal];
        }
        if (controllerTalkBtn.delegate) {
            controllerTalkBtn.delegate = nil;
        }
        [controllerTalkBtn addTarget:self action:@selector(onControllerBtnPress:) forControlEvents:UIControlEventTouchUpInside];
    }else{
        //不是门铃，则按住说话
        [controllerTalkBtn setBackgroundImage:[UIImage imageNamed:@"ic_ctl_new_send_audio.png"] forState:UIControlStateNormal];
        [controllerTalkBtn removeTarget:self action:@selector(onControllerBtnPress:) forControlEvents:UIControlEventTouchUpInside];
        controllerTalkBtn.delegate = self;
    }
    
    
    //放在渲染之后
    //获取当前被监控帐号的灯状态
    //若设备支持灯设备时，则显示开关按钮；若不支持，则隐藏
    //    NSString *contactId = [[P2PClient sharedClient] callId];
    //    NSString *contactPassword = [[P2PClient sharedClient] callPassword];
    //    [[P2PClient sharedClient] getLightStateWithDeviceId:contactId password:contactPassword];
    
    
    NSString *callId = [[P2PClient sharedClient] callId];
    NSString *callPassword = [[P2PClient sharedClient] callPassword];
    [[P2PClient sharedClient]getDefenceState:callId password:callPassword];
    
    
    //判断设备是否支持变倍变焦(38)
    [[P2PClient sharedClient] getNpcSettingsWithId:callId password:callPassword];
}

#pragma mark - 竖屏时，显示状态栏
//-(BOOL)prefersStatusBarHidden{
//    return NO;
//}

#pragma mark - 屏幕Autorotate
-(BOOL)shouldAutorotate{
    return YES;
}

#pragma mark 屏幕支持的旋转方向
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interface {
    return (interface == UIInterfaceOrientationPortrait || interface == UIInterfaceOrientationLandscapeRight);
}

#ifdef IOS6

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationLandscapeRight;
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeRight;
}
#endif

#pragma mark 支持哪些方向
-(UIInterfaceOrientationMask)supportedInterfaceOrientations{
    if (_isCanAutoOrientation) {
        return UIInterfaceOrientationMaskPortrait|UIInterfaceOrientationMaskLandscapeRight;
    }
    
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark 一开始希望的屏幕方向
-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return UIInterfaceOrientationPortrait;
}

#pragma mark - 屏幕旋转
-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (toInterfaceOrientation == UIInterfaceOrientationPortrait)
    {
        [self quitFullController];
    }
    else if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
        
    }
    else if (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {
        [self enterFullController];
    }
}

#pragma mark 屏幕旋转（退出全屏）
-(void)quitFullController{
    if (self.scrollView){
        [self.scrollView setZoomScale:1.0];
    }
    
    self.isFullScreen = NO;
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
    //隐藏横屏里的控件
    [self.controllerRightBg setHidden:YES];
    [self.controllerRight setHidden:YES];
    [self.bottomView setHidden:YES];
    [self.bottomBarView setHidden:YES];
    [self.customBorderButton setHidden:YES];
    [self.leftView setHidden:YES];
    if (self.isSupportLightSwitch) {
        [self.lightButton setHidden:YES];
    }
    if (self.isSupportFocalLength) {
        [self.focalLengthView setHidden:YES];
    }
    //显示竖屏里的控件
    [self.topBar setHidden:NO];
    [self.midToolHView setHidden:NO];
    [self.bottomToolHView setHidden:NO];
    
    
    
    //视频监控连接中的背景图片
    //进入竖屏时，调整frame
    self.canvasView.frame = self.canvasframe;
    //视频监控连接中的背景图片
    NSString *filePath = [Utils getHeaderFilePathWithId:[[P2PClient sharedClient] callId]];
    UIImage *headImg = [UIImage imageWithContentsOfFile:filePath];
    if(headImg==nil){
        headImg = [UIImage imageNamed:@"ic_header.png"];
    }
    self.canvasView.layer.contents = (id)headImg.CGImage;
    
    self.remoteView.frame = CGRectMake(0.0, 0.0, self.canvasframe.size.width, self.canvasframe.size.height);
    
    
    NSString * plist = [[NSBundle mainBundle] pathForResource:@"Common-Configuration" ofType:@"plist"];
    NSDictionary * dic = [NSDictionary dictionaryWithContentsOfFile:plist];
    BOOL isSupportZoom = [dic[@"isSupportZoom"] boolValue];
    if (isSupportZoom) {
        //退出全屏时，要将remoteView添加回到canvasView
        if (self.remoteView.superview) {
            [self.remoteView removeFromSuperview];
        }
        //监控界面缩放
        if (self.scrollView){
            if (self.scrollView.superview) {
                [self.scrollView removeFromSuperview];
            }
            [self.scrollView release];
            _scrollView = nil;
        }
        [self.canvasView addSubview:self.remoteView];
    }
    
    
    //视频监控连接中的文字提示，以及旋转
    //进入横屏时，调整frame
    self.promptButton.frame = CGRectMake(0.0, 0.0, self.canvasView.frame.size.width, self.canvasView.frame.size.height);
    //上面的canvasView重新add了remoteView
    [self.canvasView bringSubviewToFront:self.promptButton];
    NSString *labelTipText = [NSString stringWithFormat:@"%@",NSLocalizedString(@"玩命加载中...", nil)];
    CGSize size = [labelTipText sizeWithFont:XFontBold_16];
    //旋转图片
    CGFloat tipHeight = size.height + LOADINGPRESSVIEW_WIDTH_HEIGHT;
    self.yProgressView.frame = CGRectMake((self.canvasView.frame.size.width-LOADINGPRESSVIEW_WIDTH_HEIGHT)/2, (self.canvasView.frame.size.height-tipHeight)/2, LOADINGPRESSVIEW_WIDTH_HEIGHT, LOADINGPRESSVIEW_WIDTH_HEIGHT);
    //文字
    self.labelTip.frame = CGRectMake((self.canvasView.frame.size.width-size.width)/2, CGRectGetMaxY(self.yProgressView.frame), size.width+10.0, size.height);
    
    
    //左边的按住说话弹出的声音图标
    //退出横屏时，调整frame
    self.pressView.frame = CGRectMake(10, self.canvasframe.size.height+NAVIGATION_BAR_HEIGHT-PRESS_LAYOUT_WIDTH_AND_HEIGHT, PRESS_LAYOUT_WIDTH_AND_HEIGHT/2, PRESS_LAYOUT_WIDTH_AND_HEIGHT);
}

#pragma mark - 屏幕旋转（进入全屏）
-(void)enterFullController{
    
    self.isFullScreen = YES;
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    //隐藏竖屏里的控件
    [self.topBar setHidden:YES];
    [self.midToolHView setHidden:YES];
    [self.bottomToolHView setHidden:YES];
    //显示横屏里的控件
    [self.controllerRightBg setHidden:NO];
    [self.controllerRight setHidden:NO];
    [self.bottomView setHidden:NO];
    [self.bottomBarView setHidden:NO];
    [self.customBorderButton setHidden:NO];
    [self.leftView setHidden:NO];
    if (self.isSupportLightSwitch) {
        [self.lightButton setHidden:NO];
    }
    if (self.isSupportFocalLength) {
        [self.focalLengthView setHidden:YES];//横屏也隐藏变焦控件
    }
    
    
    //监控横屏rect
    CGFloat width = _monitorInterfaceW;
    CGFloat height = _monitorInterfaceH;
    
    
    //视频监控连接中的背景图片
    //进入横屏时，调整frame
    self.canvasView.frame = CGRectMake(0.0, 0.0, width, height);
    self.canvasView.layer.contents = (id)self.fullScreenBgView;
    
    
    //视频监控连接中的文字提示，以及旋转
    //进入横屏时，调整frame
    self.promptButton.frame = self.canvasView.frame;
    NSString *labelTipText = [NSString stringWithFormat:@"%@",NSLocalizedString(@"玩命加载中...", nil)];
    CGSize size = [labelTipText sizeWithFont:XFontBold_16];
    //旋转图片
    CGFloat tipHeight = size.height + LOADINGPRESSVIEW_WIDTH_HEIGHT;
    self.yProgressView.frame = CGRectMake((width-LOADINGPRESSVIEW_WIDTH_HEIGHT)/2, (height-tipHeight)/2, LOADINGPRESSVIEW_WIDTH_HEIGHT, LOADINGPRESSVIEW_WIDTH_HEIGHT);
    //文字
    self.labelTip.frame = CGRectMake((width-size.width)/2, CGRectGetMaxY(self.yProgressView.frame), size.width+10.0, size.height);
    
    
    //进入横屏，修改remoteView的frame
    BOOL is16B9 = [[P2PClient sharedClient] is16B9];
    if(is16B9){
        CGFloat finalWidth = height*16/9;
        CGFloat finalHeight = height;
        if(finalWidth>width){
            finalWidth = width;
            finalHeight = width*9/16;
        }else{
            finalWidth = height*16/9;
            finalHeight = height;
        }
        self.remoteView.frame = CGRectMake((width-finalWidth)/2, (height-finalHeight)/2, finalWidth, finalHeight);
        
    }else{
        self.remoteView.frame = CGRectMake((width-height*4/3)/2, 0, height*4/3, height);
    }
    
    /*
     *1. 进入全屏时，创建一个缩放控件
     *2. 将remoteView添加到scrollView上面（注意，退出全屏时，要将remoteView添加回到canvasView）
     */
    NSString * plist = [[NSBundle mainBundle] pathForResource:@"Common-Configuration" ofType:@"plist"];
    NSDictionary * dic = [NSDictionary dictionaryWithContentsOfFile:plist];
    BOOL isSupportZoom = [dic[@"isSupportZoom"] boolValue];
    if (isSupportZoom) {
        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        scrollView.multipleTouchEnabled = YES;
        scrollView.minimumZoomScale = 1.0;
        scrollView.maximumZoomScale = 4.0;
        scrollView.delegate = self;
        scrollView.backgroundColor = [UIColor clearColor];
        
        if (self.remoteView.superview) {
            [self.remoteView removeFromSuperview];
        }
        [scrollView addSubview:self.remoteView];
        [self.canvasView addSubview:scrollView];
        self.scrollView = scrollView;
        [scrollView release];
    }
    
    
    //进入横屏，修改lightButton和progressView的frame
    self.progressView.frame = CGRectMake(self.remoteView.frame.size.width-30.0-20.0, (self.remoteView.frame.size.height-30.0)/2, 30.0, 30.0);
    self.lightButton.frame = CGRectMake(self.remoteView.frame.size.width-30.0-20.0, (self.remoteView.frame.size.height-30.0)/2, 30.0, 30.0);
    
    
    //进入横屏，修改焦距控件的frame
    //宽、高
    CGFloat focalLengthView_w = 40.0;
    CGFloat focalLengthView_h = 180.0;
    //焦距控件与屏幕右边框的间距
    CGFloat space_FocalLView_Screen = (width - self.remoteView.frame.size.width)/2+20+focalLengthView_w;
    self.focalLengthView.frame = CGRectMake(width-space_FocalLView_Screen, height-self.bottomBarView.frame.size.height-20.0-focalLengthView_h, focalLengthView_w, focalLengthView_h);
    
    
    //左边的按住说话弹出的声音图标
    //进入横屏时，调整frame
    self.pressView.frame = CGRectMake(10, height-PRESS_LAYOUT_WIDTH_AND_HEIGHT-BOTTOM_BAR_HEIGHT, PRESS_LAYOUT_WIDTH_AND_HEIGHT/2, PRESS_LAYOUT_WIDTH_AND_HEIGHT);
}

@end
