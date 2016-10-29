//
//  ContactController_ap.m
//  Yoosee
//
//  Created by wutong on 15/9/30.
//  Copyright (c) 2015年 guojunyi. All rights reserved.
//
#import "ContactController_ap.h"
#import "P2PPlaybackController.h"
#import "Contact.h"
#import "AppDelegate.h"
#import "MainSettingController.h"
#import "ContactController_password_ap.h"
#import "TopBarX.h"
#import "Constants.h"
#import "Utils.h"
#import "ContactDAO.h"
#import "Toast+UIView.h"
#import "YProgressView.h"
#import "SDWebImageRootViewController.h"

#define CONTACT_ITEM_HEIGHT_AP (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 300:180)
#define HEADER_ICON_VIEW_HEIGHT_WIDTH 70
#define EMPTY_LABEL_WIDTH 260
#define EMPTY_LABEL_HEIGHT 50

enum
{
    ap_btn_tag_preview = 100,
    ap_btn_tag_photoalbum,
    ap_btn_tag_defence,
    ap_btn_tag_playback,
    ap_btn_tag_quit,
    ap_btn_tag_setting,
};

@interface ContactController_ap ()
{
    Contact* _contacet;
    UIImageView *_buttonImageView;  //预览图
    
    YProgressView* _progressView;   //布防转动动画
    UIButton* _btnDefence;          //布防按钮
    
    TopBarX* _topBar;               //导航条
    
    int  _dwApDefenceStatus;        //布防状态
}

@end

@implementation ContactController_ap

-(void)dealloc
{
    if (_contacet) {
        [_contacet release];
        _contacet = nil;
    }
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = XBgColor;
    [self initComponent];
    
    NSString* contactid = [NSString stringWithFormat:@"%d", [[AppDelegate sharedDefault]dwApContactID]];

    _contacet = [[Contact alloc]init];
    _contacet.contactId = ap_p2p_id;
    _contacet.contactName = contactid;
    _contacet.contactPassword = ap_p2p_password;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveRemoteMessage:) name:RECEIVE_REMOTE_MESSAGE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ack_receiveRemoteMessage:) name:ACK_RECEIVE_REMOTE_MESSAGE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ap_enter_message:) name:AP_ENTER_FORCEGROUND_MESSAGE object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateHeadPicture) name: @"update head image" object:nil];
    
    [self startGetDenfenceStatus];
}

-(void)viewWillAppear:(BOOL)animated{
    MainController *mainController = [AppDelegate sharedDefault].mainController_ap;
    [mainController setBottomBarHidden:YES];
    
    self.navigationController.navigationBarHidden = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void)initComponent
{
    CGRect rect = [AppDelegate getScreenSize:YES isHorizontal:NO];
    CGFloat width = rect.size.width;
    CGFloat height = rect.size.height;
    
    _topBar = [[TopBarX alloc] initWithFrame:CGRectMake(0, 0, width, NAVIGATION_BAR_HEIGHT)];
    [_topBar setBackButtonHidden:NO];
    [_topBar.backButton addTarget:self action:@selector(onBackPress) forControlEvents:UIControlEventTouchUpInside];
    NSString* contactid = [NSString stringWithFormat:@"%d", [[AppDelegate sharedDefault] dwApContactID]];
    [_topBar setTitle:[NSString stringWithFormat:@"%@   %@", NSLocalizedString(@"ap_mode_text", nil), contactid]];
    [self.view addSubview:_topBar];
    [_topBar release];
    
    UIButton *monitorButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [monitorButton addTarget:self action:@selector(onBtnAp:) forControlEvents:UIControlEventTouchUpInside];
    monitorButton.tag = ap_btn_tag_preview;
    monitorButton.frame = CGRectMake(0, NAVIGATION_BAR_HEIGHT, width, CONTACT_ITEM_HEIGHT_AP);
    UIImageView *buttonImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, monitorButton.frame.size.width, monitorButton.frame.size.height)];
    _buttonImageView = buttonImageView;
    
    NSString *filePath = [Utils getHeaderFilePathWithId:contactid];
    UIImage *headerViewImg = [UIImage imageWithContentsOfFile:filePath];
    if(headerViewImg==nil){
        buttonImageView.image = [UIImage imageNamed:@"ic_header_ap.png"];
    }
    else
    {
        buttonImageView.image = headerViewImg;
    }

    
    
    UIImageView *addButtonView = [[UIImageView alloc] initWithFrame:CGRectMake((monitorButton.frame.size.width-HEADER_ICON_VIEW_HEIGHT_WIDTH)/2, (monitorButton.frame.size.height-HEADER_ICON_VIEW_HEIGHT_WIDTH)/2, HEADER_ICON_VIEW_HEIGHT_WIDTH, HEADER_ICON_VIEW_HEIGHT_WIDTH)];
    addButtonView.image = [UIImage imageNamed:@"ic_header_play_ap.png"];
    
    [monitorButton addSubview:buttonImageView];
    [monitorButton addSubview:addButtonView];
    [addButtonView release];
    [buttonImageView release];
    
    [self.view addSubview:monitorButton];


    //5个按钮
    CGFloat circleTop = CONTACT_ITEM_HEIGHT_AP + NAVIGATION_BAR_HEIGHT + 35;
    CGFloat circleBottom = 30;
    
    
    //长方形的宽和高
    CGFloat sqwidth = width/3;
    CGFloat sqheigth = (height-circleTop-circleBottom)/2;
    
    //边长
    CGFloat squareSize = (sqwidth <= sqheigth) ? sqwidth : sqheigth;
    

    UIImage* arrayImgage[5] =
    {
        [UIImage imageNamed:@"ap_photoalbum.png"],
        [UIImage imageNamed:@"ap_defence_on.png"],
        [UIImage imageNamed:@"ap_playback.png"],
        [UIImage imageNamed:@"ap_help.png"],
        [UIImage imageNamed:@"ap_setting.png"],
    };
    
    UIImage* arrayImgage_p[5] =
    {
        [UIImage imageNamed:@"ap_photoalbum_p.png"],
        [UIImage imageNamed:@"ap_defence_on_p.png"],
        [UIImage imageNamed:@"ap_playback_p.png"],
        [UIImage imageNamed:@"ap_help_p.png"],
        [UIImage imageNamed:@"ap_setting_p.png"],
    };
    
    NSString* arrayLabText[5] =
    {
        NSLocalizedString(@"ap_mode_btn_photoalbum", nil),
        NSLocalizedString(@"ap_mode_btn_defence", nil),
        NSLocalizedString(@"ap_mode_btn_playback", nil),
        NSLocalizedString(@"ap_mode_btn_help", nil),
        NSLocalizedString(@"ap_mode_btn_setting", nil)
    };
    
    for (int i=0; i<5; i++) {
        CGFloat xPos = 0, yPos = 0;     //圆的外切矩形的左上角
        if (i<=2) {
            xPos = ((CGFloat)i+0.5)*sqwidth - squareSize/2;
            yPos = circleTop;
        }
        else
        {
            xPos = ((CGFloat)i-3+1)*sqwidth - squareSize/2;
            yPos = circleTop+sqheigth;
        }
        
        UIButton* btn = [[UIButton alloc] initWithFrame:CGRectMake(xPos+15, yPos+20, squareSize-30, squareSize-40)];
        if (arrayImgage[i]) {
            [btn setBackgroundImage:arrayImgage[i] forState:UIControlStateNormal];
        }
        if (arrayImgage_p[i]) {
            [btn setBackgroundImage:arrayImgage_p[i] forState:UIControlStateHighlighted];
        }
        btn.tag = ap_btn_tag_photoalbum+i;
        [btn addTarget:self action:@selector(onBtnAp:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
        [btn release];
        
        UILabel* lable = [[UILabel alloc] initWithFrame:CGRectMake(xPos+15, yPos+20+squareSize-40, squareSize-30, 30)];
        [lable setText:arrayLabText[i]];
        [lable setTextAlignment:NSTextAlignmentCenter];
        [lable setFont:XFontBold_16];
        [self.view addSubview:lable];
        [lable release];
        
        if (i == 1) {
            _progressView = [[YProgressView alloc] initWithFrame:CGRectMake(xPos+25, yPos+30, squareSize-50, squareSize-60)];
            _progressView.backgroundView.image = [UIImage imageNamed:@"ap_defence_ing.png"];
            [self.view addSubview:_progressView];
            [_progressView release];

            _btnDefence = btn;
        }
    }
}

-(void)onBtnAp:(id)sender
{
    UIButton *button = (UIButton*)sender;
    switch (button.tag) {
        case ap_btn_tag_preview:
        {
            if ([self isWifiChanged]) {
                [self.view makeToast:NSLocalizedString(@"ap_reconnect_tip", nil)];
            }
            else
            {
                MainController *mainController_ap = [AppDelegate sharedDefault].mainController_ap;
                [mainController_ap setUpCallWithId:ap_p2p_id password:ap_p2p_password callType:P2PCALL_TYPE_MONITOR];
            }
        }
            break;
            
        case ap_btn_tag_photoalbum:
        {
            SDWebImageRootViewController *screenshotController = [[SDWebImageRootViewController alloc] init];
            [self.navigationController pushViewController:screenshotController animated:YES];
            [screenshotController release];
        }
            break;

            
        case ap_btn_tag_playback:
        {
            if ([self isWifiChanged]) {
                [self.view makeToast:NSLocalizedString(@"ap_reconnect_tip", nil)];
            }
            else
            {
                P2PPlaybackController *playbackController = [[P2PPlaybackController alloc] init];
                playbackController.contact = _contacet;
                [self.navigationController pushViewController:playbackController animated:YES];
                [playbackController release];
            }

        }
            break;
            
        case ap_btn_tag_setting:
        {
            if ([self isWifiChanged]) {
                [self.view makeToast:NSLocalizedString(@"ap_reconnect_tip", nil)];
            }
            else
            {
                MainSettingController *mainSettingController = [[MainSettingController alloc] init];
                mainSettingController.contact = _contacet;
                [self.navigationController pushViewController:mainSettingController animated:YES];
                [mainSettingController release];
            }
        }
            break;
            
        case ap_btn_tag_defence:
        {
            if ([self isWifiChanged]) {
                [self.view makeToast:NSLocalizedString(@"ap_reconnect_tip", nil)];
            }
            else
            {
                if (_dwApDefenceStatus == DEFENCE_STATE_OFF) {
                    [self startSetDenfenceStatus:DEFENCE_STATE_ON];
                }
                else if (_dwApDefenceStatus == DEFENCE_STATE_ON)
                {
                    [self startSetDenfenceStatus:DEFENCE_STATE_OFF];
                }
                else
                {
                    [self startGetDenfenceStatus];
                }
            }
        }
            break;
            
        case ap_btn_tag_quit:
        {
            [self.view makeToast:NSLocalizedString(@"ap_mode_quit", nil)];
        }
            break;

        default:
            break;
    }
}

#pragma mark -
-(BOOL)shouldAutorotate{
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interface {
    return (interface == UIInterfaceOrientationPortrait );
}

#ifdef IOS6

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}
#endif

-(NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return UIInterfaceOrientationPortrait;
}

-(void)updateHeadPicture
{
    NSString* contactid = [NSString stringWithFormat:@"%d", [[AppDelegate sharedDefault]dwApContactID]];
    NSString *filePath = [Utils getHeaderFilePathWithId:contactid];
    UIImage *headerViewImg = [UIImage imageWithContentsOfFile:filePath];
    if(headerViewImg!=nil && _buttonImageView){
        _buttonImageView.image = headerViewImg;
    }
}

/*
 该函数4种情况会被调用:
 1、程序启动时-viewdidload调用startGetDenfenceStatus函数
 2、程序进入时 a.ap->ap 发AP_ENTER_FORCEGROUND_MESSAGE消息
             b.id->ap a1.需要创建新的控制器,viewdidload调用startGetDenfenceStatus函数
                      b1.不需要，发AP_ENTER_FORCEGROUND_MESSAGE消息
*/
-(void)startGetDenfenceStatus
{
    [_btnDefence setHidden:YES];
    [_progressView setHidden:NO];
    [_progressView start];
    _dwApDefenceStatus = DEFENCE_STATE_LOADING;
    [[P2PClient sharedClient]getDefenceState:ap_p2p_id password:ap_p2p_password];
}

-(void)startSetDenfenceStatus:(NSInteger)status
{
    [_btnDefence setHidden:YES];
    [_progressView setHidden:NO];
    [_progressView start];
    [[P2PClient sharedClient]setRemoteDefenceWithId:ap_p2p_id password:ap_p2p_password state:status];
    
}

- (void)ack_receiveRemoteMessage:(NSNotification *)notification{
    NSDictionary *parameter = [notification userInfo];
    int key   = [[parameter valueForKey:@"key"] intValue];
    if (key != RET_GET_NPCSETTINGS_REMOTE_DEFENCE &&
        key != RET_SET_NPCSETTINGS_REMOTE_DEFENCE) {
        return;
    }
    
    int result = [[parameter valueForKey:@"result"] intValue];
    dispatch_async(dispatch_get_main_queue(), ^{
        if(result==2)  //网络异常
        {
            if ([self isWifiChanged]) {
                [self.view makeToast:NSLocalizedString(@"ap_reconnect_tip", nil)];
            }
            [_progressView stop];
            [_progressView setHidden:YES];
            [_btnDefence setHidden:NO];
            _dwApDefenceStatus = DEFENCE_STATE_WARNING_NET;
            [self.view makeToast:NSLocalizedString(@"net_exception", nil)];
        }
    });
}

- (void)receiveRemoteMessage:(NSNotification *)notification{
    NSDictionary *parameter = [notification userInfo];
    int key   = [[parameter valueForKey:@"key"] intValue];
    
    if (key != RET_GET_NPCSETTINGS_REMOTE_DEFENCE &&
        key != RET_SET_NPCSETTINGS_REMOTE_DEFENCE) {
        return;
    }
    
//    NSString *contactId = [parameter valueForKey:@"contactId"];
//    if ([contactId intValue] != 1)
//        return;
    
    switch(key){
        case RET_GET_NPCSETTINGS_REMOTE_DEFENCE:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_progressView stop];
                [_progressView setHidden:YES];
                [_btnDefence setHidden:NO];

                NSInteger state = [[parameter valueForKey:@"state"] intValue];
                if(state==SETTING_VALUE_REMOTE_DEFENCE_STATE_ON)
                {
                    _dwApDefenceStatus = DEFENCE_STATE_ON;
                    if (_btnDefence) {
                        [_btnDefence setBackgroundImage:[UIImage imageNamed:@"ap_defence_on.png"] forState:UIControlStateNormal];
                        [_btnDefence setBackgroundImage:[UIImage imageNamed:@"ap_defence_on_p.png"] forState:UIControlStateHighlighted];
                    }

                }
                else
                {
                    _dwApDefenceStatus = DEFENCE_STATE_OFF;
                    if (_btnDefence) {
                        [_btnDefence setBackgroundImage:[UIImage imageNamed:@"ap_defence_off.png"] forState:UIControlStateNormal];
                        [_btnDefence setBackgroundImage:[UIImage imageNamed:@"ap_defence_off_p.png"] forState:UIControlStateHighlighted];
                    }
                }

            });
        }
            break;
            
        case RET_SET_NPCSETTINGS_REMOTE_DEFENCE:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_progressView stop];
                [_progressView setHidden:YES];
                [_btnDefence setHidden:NO];

                NSInteger state = [[parameter valueForKey:@"state"] intValue];
                if(state==SETTING_VALUE_REMOTE_DEFENCE_STATE_ON)
                {
                    _dwApDefenceStatus = DEFENCE_STATE_ON;
                    if (_btnDefence) {
                        [_btnDefence setBackgroundImage:[UIImage imageNamed:@"ap_defence_on.png"] forState:UIControlStateNormal];
                        [_btnDefence setBackgroundImage:[UIImage imageNamed:@"ap_defence_on_p.png"] forState:UIControlStateHighlighted];
                    }
                }
                else
                {
                    _dwApDefenceStatus = DEFENCE_STATE_OFF;
                    if (_btnDefence) {
                        [_btnDefence setBackgroundImage:[UIImage imageNamed:@"ap_defence_off.png"] forState:UIControlStateNormal];
                        [_btnDefence setBackgroundImage:[UIImage imageNamed:@"ap_defence_off_p.png"] forState:UIControlStateHighlighted];
                    }
                }
            });
        }
            break;
    }
}

-(void)ap_enter_message:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* contactid = [NSString stringWithFormat:@"%d", [[AppDelegate sharedDefault] dwApContactID]];
        [_topBar setTitle:[NSString stringWithFormat:@"%@   %@", NSLocalizedString(@"ap_mode_text", nil), contactid]];
        
        [self.navigationController popToRootViewControllerAnimated:NO];

        _contacet.contactName = contactid;

        [self updateHeadPicture];
        
        [self startGetDenfenceStatus];
    });
}

-(void)onBackPress
{
    [self.view makeToast:NSLocalizedString(@"ap_mode_quit", nil)];
}

-(BOOL)isWifiChanged
{
    NSString* sWifi1 = [Utils currentWifiSSID];
    NSString* sWifi2 = [[AppDelegate sharedDefault] sWifi];

    if (sWifi1 == nil || sWifi2 == nil) {
        return YES;
    }

    BOOL isEqual = [sWifi1 isEqualToString:sWifi2];
    return !isEqual;
}
@end
