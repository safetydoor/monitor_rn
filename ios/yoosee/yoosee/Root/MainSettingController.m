//
//  MainSettingController.m
//  Yoosee
//
//  Created by guojunyi on 14-5-12.
//  Copyright (c) 2014年 guojunyi. All rights reserved.
//

#import "MainSettingController.h"
#import "AppDelegate.h"
#import "TopBar.h"
#import "Constants.h"
#import "MainController.h"
#import "Utils.h"
#import "Contact.h"
#import "CustomCell.h"
#import "TimeSettingController.h"
#import "SecuritySettingController.h"
#import "VideoSettingController.h"
#import "AutoNavigation.h"
#import "AlarmSettingController.h"
#import "RemoteSettingController.h"
#import "NetSettingController.h"
#import "RecordSettingController.h"
#import "DefenceAreaSettingController.h"
#import "LanguageSettingController.h"
#import "MBProgressHUD.h"
#import "Toast+UIView.h"
#import "FListManager.h"//设备检查更新
#import "UDManager.h"
#import "ContactController_password_ap.h"

@interface MainSettingController ()
{
    BOOL _isCancelUpdateDeviceOk;
    
    int _iDevUpdateRow;
    int _iApStaSwitchRow;
}
@end

@implementation MainSettingController

-(void)dealloc{
    [self.progressAlert release];
    [self.contact release];
    [self.progressView release];
    [self.progressMaskView release];
    [self.progressLabel release];
    [self.tableView release];
    [self.timer release];
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated{
    MainController *mainController = [AppDelegate sharedDefault].mainController;
    if ([[AppDelegate sharedDefault]dwApContactID] != 0) {
        mainController = [AppDelegate sharedDefault].mainController_ap;
    }
    [mainController setBottomBarHidden:YES];
    
    self.isSendRomoteMessageInCurrentInterface = NO;
}

-(void)viewDidAppear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveRemoteMessage:) name:RECEIVE_REMOTE_MESSAGE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ack_receiveRemoteMessage:) name:ACK_RECEIVE_REMOTE_MESSAGE object:nil];
    
}

-(void)viewWillDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RECEIVE_REMOTE_MESSAGE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ACK_RECEIVE_REMOTE_MESSAGE object:nil];
}

- (void)receiveRemoteMessage:(NSNotification *)notification{
    NSDictionary *parameter = [notification userInfo];
    int key   = [[parameter valueForKey:@"key"] intValue];
    if (!self.isSendRomoteMessageInCurrentInterface) {//设备检查更新
        //YES表示当前界面发送远程消息，才可以继续往下执行
        //因为在ContactController里下拉发送这设备检查更新的请求
        return;
    }
    switch(key){
            
        case RET_CHECK_DEVICE_UPDATE:
        {
            NSInteger result = [[parameter valueForKey:@"result"] intValue];
            NSString *curVersion = [parameter valueForKey:@"curVersion"];
            NSString *upgVersion = [parameter valueForKey:@"upgVersion"];
            if(result==1){
                //读取到了服务器升级文件
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [self.progressAlert hide:YES];
                    NSString *title = [NSString stringWithFormat:@"%@:%@,%@:%@",NSLocalizedString(@"cur_version_is", nil),curVersion,NSLocalizedString(@"can_update_to", nil),upgVersion];
                    UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:title message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:NSLocalizedString(@"ok", nil),nil];
                    deleteAlert.tag = ALERT_TAG_UPDATE;
                    [deleteAlert show];
                    [deleteAlert release];
                    
                });
                
                
            }else if(result==72){//sd卡升级文件
                //读取到了sd卡升级文件
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [self.progressAlert hide:YES];
                    NSString *title = [NSString stringWithFormat:@"%@:%@,%@",NSLocalizedString(@"cur_version_is", nil),curVersion,NSLocalizedString(@"can_update_sd", nil)];
                    UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:title message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:NSLocalizedString(@"ok", nil),nil];
                    deleteAlert.tag = ALERT_TAG_UPDATE;
                    [deleteAlert show];
                    [deleteAlert release];
                });
            }else if(result==54){
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [self.progressAlert hide:YES];
                    [self.view makeToast:[NSString stringWithFormat:@"%@:%@",NSLocalizedString(@"now_version_is_latest", nil),curVersion]];
                });
            }else if(result==58){
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [self.progressAlert hide:YES];
                    [self.view makeToast:NSLocalizedString(@"other_was_check_device_update", nil)];
                });
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [self.progressAlert hide:YES];
                    [self.view makeToast:NSLocalizedString(@"update_failed", nil)];
                });
            }
        }
            break;
        case RET_DO_DEVICE_UPDATE:
        {
            NSInteger result = [[parameter valueForKey:@"result"] intValue];
            NSInteger value = [[parameter valueForKey:@"value"] intValue];

            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self.progressAlert hide:YES];
                
                if(result==1){
                    self.progressLabel.text = [NSString stringWithFormat:@"%i%%",value];//device update
                    [self.progressMaskView setHidden:NO];
                    DLog(@"%i",value);
                }else if(result==65){
                    [self.progressMaskView setHidden:YES];
                    [self.view makeToast:NSLocalizedString(@"start_update", nil)];
                    //设备检查更新
                    //设备升级成功，将设备的isNewVersionDevice设置为NO，刷新表格，去除红色角标
                    for (Contact *contact in [[NSMutableArray alloc] initWithArray:[[FListManager sharedFList] getContacts]]) {
                        if ([self.contact.contactId isEqualToString:contact.contactId]) {
                            contact.isNewVersionDevice = NO;
                        }
                    }
                    [self.tableView reloadData];
                    
                }else{
                    _isCancelUpdateDeviceOk = YES;
                    [self.progressMaskView setHidden:YES];
                    [self.view makeToast:NSLocalizedString(@"update_failed", nil)];
                }
            });
           
        }
            break;
        case RET_DEVICE_NOT_SUPPORT:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self.progressAlert hide:YES];
                [self.view makeToast:NSLocalizedString(@"device_not_support", nil)];
            });
        }
            break;
        case RET_GET_DEVICE_INFO:
        {
            NSInteger result = [[parameter valueForKey:@"result"] intValue];
            NSString *curVersion = [parameter valueForKey:@"curVersion"];
            NSString *kernelVersion = [parameter valueForKey:@"kernelVersion"];
            NSString *rootfsVersion = [parameter valueForKey:@"rootfsVersion"];
            NSString *ubootVersion = [parameter valueForKey:@"ubootVersion"];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self.progressAlert hide:YES];
                
                if(result==1){
                    [self showDeviceInfoViewWithCurVersion:curVersion kernelVersion:kernelVersion rootfsVersion:rootfsVersion ubootVersion:ubootVersion];
                }
            });
        }
            break;
            
        case RET_SWITCH_APSTA_MODE:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressAlert hide:YES];

                NSInteger result = [[parameter valueForKey:@"result"] intValue];
                if (result == 0)
                {
                    [self.view makeToast:NSLocalizedString(@"apsta_switch_ok", nil)];
                }
                else
                {
                    [self.view makeToast:NSLocalizedString(@"operator_failure", nil)];
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
    if (!self.isSendRomoteMessageInCurrentInterface) {//设备检查更新
        //YES表示当前界面发送远程消息，才可以继续往下执行
        //因为在ContactController里下拉发送这设备检查更新的请求
        return;
    }
    switch(key){
        case ACK_RET_CHECK_DEVICE_UPDATE:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(result==1){
                    [self.progressAlert hide:YES];
                    [self.view makeToast:NSLocalizedString(@"device_password_error", nil)];
                    
                }else if(result==2){
                    DLog(@"resend check device update");
                    [[P2PClient sharedClient] checkDeviceUpdateWithId:self.contact.contactId password:self.contact.contactPassword];
                }
                
                
            });
            
        }
            break;
        case ACK_RET_DO_DEVICE_UPDATE:{
            dispatch_async(dispatch_get_main_queue(), ^{
                if(result==1){
                    [self.progressAlert hide:YES];
                    [self.view makeToast:NSLocalizedString(@"device_password_error", nil)];
                    
                }else if(result==2){
                    DLog(@"resend do device update");
                    [[P2PClient sharedClient] doDeviceUpdateWithId:self.contact.contactId password:self.contact.contactPassword];
                }
                
                
            });
            
            DLog(@"ACK_RET_DO_DEVICE_UPDATE:%i",result);
        }
            break;
        case ACK_RET_GET_DEVICE_INFO:{
            dispatch_async(dispatch_get_main_queue(), ^{
                if(result==1){
                    [self.progressAlert hide:YES];
                    [self.view makeToast:NSLocalizedString(@"device_password_error", nil)];
                    
                }else if(result==2){
                    DLog(@"resend do device update");
                    [[P2PClient sharedClient] getDeviceInfoWithId:self.contact.contactId password:self.contact.contactPassword];
                }
                
                
            });
            
            DLog(@"ACK_RET_GET_DEVICE_INFO:%i",result);
        }
            break;
            
        case ACK_RET_SWITCH_APSTA_MODE:{
            dispatch_async(dispatch_get_main_queue(), ^{
                if(result==1){
                    [self.progressAlert hide:YES];
                    [self.view makeToast:NSLocalizedString(@"device_password_error", nil)];
                    
                }
            });
        }
            break;
    }
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initComponent];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#define TOP_INFO_BAR_HEIGHT 80

#define TOP_HEAD_MARGIN 10
#define PROGRESS_VIEW_WIDTH 160
#define PROGRESS_VIEW_HEIGHT 140

#define INDECATOR_LABEL_HEIGHT 100
#define VIEW_DEVICE_BUTTON_WIDTH 80
#define VIEW_DEVICE_BUTTON_HEIGHT 34

-(void)initComponent{
    [self.view setBackgroundColor:XBgColor];
    CGRect rect = [AppDelegate getScreenSize:YES isHorizontal:NO];
    CGFloat width = rect.size.width;
    CGFloat height = rect.size.height;
    
    TopBar *topBar = [[TopBar alloc] initWithFrame:CGRectMake(0, 0, width, NAVIGATION_BAR_HEIGHT)];
    [topBar setTitle:NSLocalizedString(@"device_control",nil)];
    [topBar setBackButtonHidden:NO];
    [topBar.backButton addTarget:self action:@selector(onBackPress) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:topBar];
    [topBar release];
    
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, NAVIGATION_BAR_HEIGHT, width, height-NAVIGATION_BAR_HEIGHT)];
    
    
    UIView *topInfoBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, TOP_INFO_BAR_HEIGHT)];
    [topInfoBarView setBackgroundColor:XWhite];
    UIImageView *headImgView = [[UIImageView alloc] initWithFrame:CGRectMake(TOP_HEAD_MARGIN, TOP_HEAD_MARGIN, (TOP_INFO_BAR_HEIGHT-TOP_HEAD_MARGIN*2)*4/3, TOP_INFO_BAR_HEIGHT-TOP_HEAD_MARGIN*2)];
    
    NSString *filePath = [Utils getHeaderFilePathWithId:self.contact.contactId];
    
    UIImage *headImg = [UIImage imageWithContentsOfFile:filePath];
    if(headImg==nil){
        headImg = [UIImage imageNamed:@"ic_header.png"];
    }
    headImgView.image = headImg;
    
    [topInfoBarView addSubview:headImgView];
    [headImgView release];
    
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(TOP_HEAD_MARGIN+(TOP_INFO_BAR_HEIGHT-TOP_HEAD_MARGIN*2)*4/3+TOP_HEAD_MARGIN,0,width-(TOP_HEAD_MARGIN+(TOP_INFO_BAR_HEIGHT-TOP_HEAD_MARGIN*2)*4/3+TOP_HEAD_MARGIN),TOP_INFO_BAR_HEIGHT)];
    
    nameLabel.textAlignment = NSTextAlignmentLeft;
    nameLabel.textColor = XBlack;
    nameLabel.backgroundColor = XBGAlpha;
    [nameLabel setFont:XFontBold_18];
    
    nameLabel.text = self.contact.contactName;
    [topInfoBarView addSubview:nameLabel];
    [nameLabel release];
    
    //设备信息（IPC）
    if(self.contact.contactType==CONTACT_TYPE_IPC || self.contact.contactType==CONTACT_TYPE_DOORBELL || self.contact.contactId.intValue<256){//IP添加设备
        UIButton *viewDeviceInfoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        viewDeviceInfoButton.frame = CGRectMake(width-5-VIEW_DEVICE_BUTTON_WIDTH, (TOP_INFO_BAR_HEIGHT/2-VIEW_DEVICE_BUTTON_HEIGHT)/2+TOP_INFO_BAR_HEIGHT/2, VIEW_DEVICE_BUTTON_WIDTH, VIEW_DEVICE_BUTTON_HEIGHT);
        viewDeviceInfoButton.layer.borderColor = [XBlack CGColor];
        viewDeviceInfoButton.layer.cornerRadius = 1.0;
        viewDeviceInfoButton.backgroundColor = UIColorFromRGB(0xcccccc);
        [viewDeviceInfoButton addTarget:self action:@selector(onViewDeviceInfoButtonPress:) forControlEvents:UIControlEventTouchUpInside];
        
        UILabel *deviceInfoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, viewDeviceInfoButton.frame.size.width, viewDeviceInfoButton.frame.size.height)];
        deviceInfoLabel.backgroundColor = [UIColor clearColor];
        deviceInfoLabel.textAlignment = NSTextAlignmentCenter;
        deviceInfoLabel.textColor = UIColorFromRGB(0x000000);
        deviceInfoLabel.font = XFontBold_14;
        deviceInfoLabel.text = NSLocalizedString(@"device_info", nil);
        [viewDeviceInfoButton addSubview:deviceInfoLabel];
        [deviceInfoLabel release];
        
        [topInfoBarView addSubview:viewDeviceInfoButton];
    }
    
    
    [contentView addSubview:topInfoBarView];
    [topInfoBarView release];
    
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0,TOP_INFO_BAR_HEIGHT, width, height-(NAVIGATION_BAR_HEIGHT+TOP_INFO_BAR_HEIGHT)) style:UITableViewStyleGrouped];
    [tableView setBackgroundColor:XBGAlpha];
    tableView.backgroundView = nil;
    [tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    tableView.delegate = self;
    tableView.dataSource = self;
    [contentView addSubview:tableView];
    self.tableView = tableView;
    [tableView release];
    
    
    self.progressAlert = [[[MBProgressHUD alloc] initWithView:contentView] autorelease];
    [contentView addSubview:self.progressAlert];
    
    
    //
    UIView *progressMaskView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, contentView.frame.size.width, contentView.frame.size.height)];
    [contentView addSubview:progressMaskView];
    self.progressMaskView = progressMaskView;
    [progressMaskView release];
    
    [self.view addSubview:contentView];
    
    [contentView release];
    
    //设备更新进度
    UIView *progressView = [[UIView alloc] initWithFrame:CGRectMake((width-PROGRESS_VIEW_WIDTH)/2, (height-PROGRESS_VIEW_HEIGHT)/2, PROGRESS_VIEW_WIDTH, PROGRESS_VIEW_HEIGHT)];
    progressView.layer.borderColor = [XBlack CGColor];
    progressView.layer.cornerRadius = 2.0;
    progressView.layer.borderWidth = 1.0;
    progressView.backgroundColor = XBlack_128;
    progressView.layer.masksToBounds = YES;
    
    //标题
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, PROGRESS_VIEW_WIDTH, 30.0)];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = XWhite;
    titleLabel.font = XFontBold_16;
    titleLabel.text = NSLocalizedString(@"update", nil);
    [progressView addSubview:titleLabel];
    [titleLabel release];//update
    
    //百分比进度
    UILabel *indicatorLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, PROGRESS_VIEW_WIDTH, INDECATOR_LABEL_HEIGHT)];
    indicatorLabel.backgroundColor = [UIColor clearColor];
    indicatorLabel.textAlignment = NSTextAlignmentCenter;
    indicatorLabel.textColor = XWhite;
    indicatorLabel.font = XFontBold_18;
    indicatorLabel.text = @"%0";
    [progressView addSubview:indicatorLabel];
    self.progressLabel = indicatorLabel;
    
    //取消更新按钮
    UIButton *indicatorButton = [UIButton buttonWithType:UIButtonTypeCustom];
    indicatorButton.frame = CGRectMake(0, indicatorLabel.frame.origin.y+indicatorLabel.frame.size.height, PROGRESS_VIEW_WIDTH, PROGRESS_VIEW_HEIGHT-(indicatorLabel.frame.origin.y+indicatorLabel.frame.size.height));
    indicatorButton.layer.borderWidth = 1.0;
    indicatorButton.layer.borderColor = [XBlack CGColor];
    UILabel *buttonLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, indicatorButton.frame.size.width, indicatorButton.frame.size.height)];
    buttonLabel.backgroundColor = [UIColor clearColor];
    buttonLabel.textAlignment = NSTextAlignmentCenter;
    buttonLabel.textColor = XWhite;
    buttonLabel.font = XFontBold_16;
    buttonLabel.text = NSLocalizedString(@"cancel_update", nil);
    [indicatorButton addSubview:buttonLabel];
    [buttonLabel release];
    [indicatorButton addTarget:self action:@selector(onCancelUpdateButtonPress:) forControlEvents:UIControlEventTouchUpInside];
    [indicatorButton addTarget:self action:@selector(lightButton:) forControlEvents:UIControlEventTouchDown];
    [indicatorButton addTarget:self action:@selector(normalButton:) forControlEvents:UIControlEventTouchCancel];
    [indicatorButton addTarget:self action:@selector(normalButton:) forControlEvents:UIControlEventTouchDragOutside];
    [indicatorButton addTarget:self action:@selector(normalButton:) forControlEvents:UIControlEventTouchUpOutside];
    [progressView addSubview:indicatorButton];
    
    
    [self.progressMaskView addSubview:progressView];
    
    
    self.progressView = progressView;

    [indicatorLabel release];
    [progressView release];
    
    [self.progressMaskView setHidden:YES];
    
}

-(void)onBackPress{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)lightButton:(UIView*)view{
    view.backgroundColor = XBlue;
}

-(void)normalButton:(UIView*)view{
    view.backgroundColor = [UIColor clearColor];
}

-(void)onViewDeviceInfoButtonPress:(UIButton*)button{
    self.progressAlert.dimBackground = YES;
    [self.progressAlert show:YES];
    self.isSendRomoteMessageInCurrentInterface = YES;//设备检查更新
    [[P2PClient sharedClient] getDeviceInfoWithId:self.contact.contactId password:self.contact.contactPassword];
}

-(void)onCancelUpdateButtonPress:(UIButton*)button{
    [self normalButton:button];
    self.isSendRomoteMessageInCurrentInterface = YES;//设备检查更新
    [[P2PClient sharedClient] cancelDeviceUpdateWithId:self.contact.contactId password:self.contact.contactPassword];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:5.0f target:self selector:@selector(didHiddenProgressMaskView) userInfo:nil repeats:NO];
}

-(void)didHiddenProgressMaskView{
    if (!_isCancelUpdateDeviceOk) {
        [self.progressMaskView setHidden:YES];
        [self.view makeToast:NSLocalizedString(@"device_update_timeout", nil)];
    }
    [self.timer setFireDate:[NSDate distantFuture]];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    BOOL isApMode = ([[AppDelegate sharedDefault] dwApContactID] != 0);
    if (isApMode) {
        return 7;                   //-时间设置-媒体设置-报警设置-录像设置-防区设置-wifi密码设置-模式切换

    }
    else
    {
        int iRowCount = 8;          //-时间设置-媒体设置-安全设置-网络设置-报警设置-录像设置-防区设置-语言设置-<设备更新>-<模式切换>
        if ([self isShowDevUpdate])
        {
            iRowCount ++;
        }

        if ([self isShowApStaSwitch]) {
            iRowCount++;
        }
        return iRowCount;
    }
 }

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"SettingCell";
    static NSString *identifier2 = @"DevUpdateCell";
    
    [self getRowInfo];
    
    CustomCell *cell = nil;
    if(indexPath.row == _iDevUpdateRow){
        cell = [tableView dequeueReusableCellWithIdentifier:identifier2];
        if(cell==nil){
            cell = [[[CustomCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier2] autorelease];
            [cell setBackgroundColor:XBGAlpha];
        }
        
    }else{
        cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if(cell==nil){
            cell = [[[CustomCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
            [cell setBackgroundColor:XBGAlpha];
        }
    }
    
    
    int section = (int)indexPath.section;
    int row = (int)indexPath.row;
    UIImage *backImg = nil;
    UIImage *backImg_p = nil;
    
    
    
    
    
    [cell setRightIcon:@"ic_arrow.png"];
    
    
    switch (section) {
        case 0:
        {
            if ([[AppDelegate sharedDefault] dwApContactID] == 0) {
                if(row==0){
                    backImg = [UIImage imageNamed:@"bg_bar_btn_top.png"];
                    backImg_p = [UIImage imageNamed:@"bg_bar_btn_top_p.png"];
                    [cell setLeftIcon:@"ic_ctl_time.png"];
                    [cell setLabelText:NSLocalizedString(@"time_set", nil)];
                    
                }else if(row==1){
                    backImg = [UIImage imageNamed:@"bg_bar_btn_center.png"];
                    backImg_p = [UIImage imageNamed:@"bg_bar_btn_center_p.png"];
                    [cell setLeftIcon:@"ic_ctl_media.png"];
                    [cell setLabelText:NSLocalizedString(@"media_set", nil)];
                }else if(row==2){
                    backImg = [UIImage imageNamed:@"bg_bar_btn_center.png"];
                    backImg_p = [UIImage imageNamed:@"bg_bar_btn_center_p.png"];
                    [cell setLeftIcon:@"ic_ctl_security.png"];
                    [cell setLabelText:NSLocalizedString(@"security_set", nil)];
                }else if(row==3){
                    backImg = [UIImage imageNamed:@"bg_bar_btn_center.png"];
                    backImg_p = [UIImage imageNamed:@"bg_bar_btn_center_p.png"];
                    [cell setLeftIcon:@"ic_ctl_net.png"];
                    [cell setLabelText:NSLocalizedString(@"network_set", nil)];
                }else if(row==4){
                    backImg = [UIImage imageNamed:@"bg_bar_btn_center.png"];
                    backImg_p = [UIImage imageNamed:@"bg_bar_btn_center_p.png"];
                    [cell setLeftIcon:@"ic_ctl_alarm.png"];
                    [cell setLabelText:NSLocalizedString(@"alarm_set", nil)];
                }else if(row==5){
                    backImg = [UIImage imageNamed:@"bg_bar_btn_center.png"];
                    backImg_p = [UIImage imageNamed:@"bg_bar_btn_center_p.png"];
                    [cell setLeftIcon:@"ic_ctl_record.png"];
                    [cell setLabelText:NSLocalizedString(@"record_set", nil)];
                }else if(row==6){
                    backImg = [UIImage imageNamed:@"bg_bar_btn_center.png"];
                    backImg_p = [UIImage imageNamed:@"bg_bar_btn_center_p.png"];
                    [cell setLeftIcon:@"ic_ctl_defence_area.png"];
                    [cell setLabelText:NSLocalizedString(@"defenceArea_set", nil)];
                }else if(row==7){//推送语言设置
                    if ([self isShowDevUpdate] || [self isShowApStaSwitch]) {
                        backImg = [UIImage imageNamed:@"bg_bar_btn_center.png"];
                        backImg_p = [UIImage imageNamed:@"bg_bar_btn_center_p.png"];
                    }
                    else
                    {
                        backImg = [UIImage imageNamed:@"bg_bar_btn_bottom.png"];
                        backImg_p = [UIImage imageNamed:@"bg_bar_btn_bottom_p.png"];
                    }
                    [cell setLeftIcon:@"ic_ctl_set_device_language.png"];
                    [cell setLabelText:NSLocalizedString(@"push_language", nil)];
                }
                else if(row==_iDevUpdateRow){//设备更新
                    if ([self isShowApStaSwitch]) {
                        backImg = [UIImage imageNamed:@"bg_bar_btn_center.png"];
                        backImg_p = [UIImage imageNamed:@"bg_bar_btn_center_p.png"];
                    }
                    else
                    {
                        backImg = [UIImage imageNamed:@"bg_bar_btn_bottom.png"];
                        backImg_p = [UIImage imageNamed:@"bg_bar_btn_bottom_p.png"];
                    }
                    [cell setLeftIcon:@"ic_ctl_update_device.png"];
                    [cell setLabelText:NSLocalizedString(@"device_update", nil)];
                    if (self.contact.isNewVersionDevice) {
                        [cell setNewDeviceIcon:@"ic_ctl_new_version_device.png"];//设备检查更新
                    }else{
                        [cell setNewDeviceIcon:@""];
                    }
                }
                else if(row == _iApStaSwitchRow)//模式切换
                {
                    backImg = [UIImage imageNamed:@"bg_bar_btn_bottom.png"];
                    backImg_p = [UIImage imageNamed:@"bg_bar_btn_bottom_p.png"];
                    [cell setLeftIcon:@"ic_ctl_modeswitch.png"];
                    [cell setLabelText:NSLocalizedString(@"apsta_switch_to_ap", nil)];
                }
            }
            else
            {
                if(row==0){
                    backImg = [UIImage imageNamed:@"bg_bar_btn_top.png"];
                    backImg_p = [UIImage imageNamed:@"bg_bar_btn_top_p.png"];
                    [cell setLeftIcon:@"ic_ctl_time.png"];
                    [cell setLabelText:NSLocalizedString(@"time_set", nil)];
                    
                }else if(row==1){
                    backImg = [UIImage imageNamed:@"bg_bar_btn_center.png"];
                    backImg_p = [UIImage imageNamed:@"bg_bar_btn_center_p.png"];
                    [cell setLeftIcon:@"ic_ctl_media.png"];
                    [cell setLabelText:NSLocalizedString(@"media_set", nil)];
                }else if(row==2){
                    backImg = [UIImage imageNamed:@"bg_bar_btn_center.png"];
                    backImg_p = [UIImage imageNamed:@"bg_bar_btn_center_p.png"];
                    [cell setLeftIcon:@"ic_ctl_alarm.png"];
                    [cell setLabelText:NSLocalizedString(@"alarm_set", nil)];
                }else if(row==3){
                    backImg = [UIImage imageNamed:@"bg_bar_btn_center.png"];
                    backImg_p = [UIImage imageNamed:@"bg_bar_btn_center_p.png"];
                    [cell setLeftIcon:@"ic_ctl_record.png"];
                    [cell setLabelText:NSLocalizedString(@"record_set", nil)];
                }else if(row==4){
                    backImg = [UIImage imageNamed:@"bg_bar_btn_center.png"];
                    backImg_p = [UIImage imageNamed:@"bg_bar_btn_center_p.png"];
                    [cell setLeftIcon:@"ic_ctl_defence_area.png"];
                    [cell setLabelText:NSLocalizedString(@"defenceArea_set", nil)];
                }else if(row == 5){
                    backImg = [UIImage imageNamed:@"bg_bar_btn_center.png"];
                    backImg_p = [UIImage imageNamed:@"bg_bar_btn_center_p.png"];
                    [cell setLeftIcon:@"ic_ctl_ap_wifi_password.png"];
                    [cell setLabelText:NSLocalizedString(@"ap_mode_set_password", nil)];
                }
                else if(row == 6)//模式切换
                {
                    backImg = [UIImage imageNamed:@"bg_bar_btn_bottom.png"];
                    backImg_p = [UIImage imageNamed:@"bg_bar_btn_bottom_p.png"];
                    [cell setLeftIcon:@"ic_ctl_modeswitch.png"];
                    [cell setLabelText:NSLocalizedString(@"apsta_switch_to_sta", nil)];
                }
            }
            
        }
            break;
    }
    
    UIImageView *backImageView = [[UIImageView alloc] init];
    
    
    
    backImg = [backImg stretchableImageWithLeftCapWidth:backImg.size.width*0.5 topCapHeight:backImg.size.height*0.5];
    backImageView.image = backImg;
    [cell setBackgroundView:backImageView];
    [backImageView release];
    
    UIImageView *backImageView_p = [[UIImageView alloc] init];
    
    backImg_p = [backImg_p stretchableImageWithLeftCapWidth:backImg_p.size.width*0.5 topCapHeight:backImg_p.size.height*0.5];
    backImageView_p.image = backImg_p;
    [cell setSelectedBackgroundView:backImageView_p];
    [backImageView_p release];
    
    
    
    return cell;
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return BAR_BUTTON_HEIGHT;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    int section = (int)indexPath.section;
    int row = (int)indexPath.row;
    
    [self getRowInfo];
    switch(section){
        case 0:
        {
            if ([[AppDelegate sharedDefault] dwApContactID] == 0) {
                if(row==0){
                    TimeSettingController *timeSettingController = [[TimeSettingController alloc] init];
                    timeSettingController.contact = self.contact;
                    [self.navigationController pushViewController:timeSettingController animated:YES];
                    [timeSettingController release];
                }else if(row==1){
                    VideoSettingController *videoSettingController = [[VideoSettingController alloc] init];
                    videoSettingController.contact = self.contact;
                    [self.navigationController pushViewController:videoSettingController animated:YES];
                    [videoSettingController release];
                }else if(row==2){
                    
                    SecuritySettingController *securitySettingController = [[SecuritySettingController alloc] init];
                    securitySettingController.contact = self.contact;
                    [self.navigationController pushViewController:securitySettingController animated:YES];
                    [securitySettingController release];
                }else if(row==3){
                    NetSettingController *netSettingController = [[NetSettingController alloc] init];
                    netSettingController.contact = self.contact;
                    [self.navigationController pushViewController:netSettingController animated:YES];
                    [netSettingController release];
                }else if(row==4){
                    AlarmSettingController *alarmSettingController = [[AlarmSettingController alloc] init];
                    alarmSettingController.contact = self.contact;
                    [self.navigationController pushViewController:alarmSettingController animated:YES];
                    [alarmSettingController release];
                }else if(row==5){
                    RecordSettingController *recordSettingController = [[RecordSettingController alloc] init];
                    recordSettingController.contact = self.contact;
                    [self.navigationController pushViewController:recordSettingController animated:YES];
                    [recordSettingController release];
                }else if(row==6){
                    DefenceAreaSettingController *defenceAreaSettingController = [[DefenceAreaSettingController alloc] init];
                    defenceAreaSettingController.contact = self.contact;
                    [self.navigationController pushViewController:defenceAreaSettingController animated:YES];
                    [defenceAreaSettingController release];
                }else if(row==7){//语言设置
                    //跳到语言设置界面
                    LanguageSettingController *languageSettingController = [[LanguageSettingController alloc] init];
                    languageSettingController.contact = self.contact;
                    [self.navigationController pushViewController:languageSettingController animated:YES];
                    [languageSettingController release];
                }
                else if(row==_iDevUpdateRow){//设备检查更新
                    self.progressAlert.dimBackground = YES;
                    [self.progressAlert show:YES];
                    self.isSendRomoteMessageInCurrentInterface = YES;
                    [[P2PClient sharedClient] checkDeviceUpdateWithId:self.contact.contactId password:self.contact.contactPassword];
                }
                else if (row == _iApStaSwitchRow)
                {
                    UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"apsta_switch_sure", nil)
                                                                          message:@""
                                                                         delegate:self
                                                                cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                                                                otherButtonTitles:NSLocalizedString(@"ok", nil),nil];
                    deleteAlert.tag = SWITH_APSTA_MODE;
                    [deleteAlert show];
                    [deleteAlert release];
                }
            }
            else
            {
                if(row==0){
                    TimeSettingController *timeSettingController = [[TimeSettingController alloc] init];
                    timeSettingController.contact = self.contact;
                    [self.navigationController pushViewController:timeSettingController animated:YES];
                    [timeSettingController release];
                }else if(row==1){
                    VideoSettingController *videoSettingController = [[VideoSettingController alloc] init];
                    videoSettingController.contact = self.contact;
                    [self.navigationController pushViewController:videoSettingController animated:YES];
                    [videoSettingController release];
                }else if(row==2){
                    AlarmSettingController *alarmSettingController = [[AlarmSettingController alloc] init];
                    alarmSettingController.contact = self.contact;
                    [self.navigationController pushViewController:alarmSettingController animated:YES];
                    [alarmSettingController release];
                }else if(row==3){
                    RecordSettingController *recordSettingController = [[RecordSettingController alloc] init];
                    recordSettingController.contact = self.contact;
                    [self.navigationController pushViewController:recordSettingController animated:YES];
                    [recordSettingController release];
                }else if(row==4){
                    DefenceAreaSettingController *defenceAreaSettingController = [[DefenceAreaSettingController alloc] init];
                    defenceAreaSettingController.contact = self.contact;
                    [self.navigationController pushViewController:defenceAreaSettingController animated:YES];
                    [defenceAreaSettingController release];
                }else if(row==5){
                    ContactController_password_ap *apPwdController = [[ContactController_password_ap alloc] init];
                    [self.navigationController pushViewController:apPwdController animated:YES];
                    [apPwdController release];
                }
                else if (row == 6)
                {
                    UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"apsta_switch_sure", nil)
                                                                          message:@""
                                                                         delegate:self
                                                                cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                                                                otherButtonTitles:NSLocalizedString(@"ok", nil),nil];
                    deleteAlert.tag = SWITH_APSTA_MODE;
                    [deleteAlert show];
                    [deleteAlert release];
                }
            }
            
        }
            break;
        
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch(alertView.tag){
        case ALERT_TAG_UPDATE:
        {
            if(buttonIndex==1){
                self.progressAlert.dimBackground = YES;
                [self.progressAlert show:YES];
                self.isSendRomoteMessageInCurrentInterface = YES;//设备检查更新
                [[P2PClient sharedClient] doDeviceUpdateWithId:self.contact.contactId password:self.contact.contactPassword];
            }else{
                self.isSendRomoteMessageInCurrentInterface = YES;//设备检查更新
                [[P2PClient sharedClient] cancelDeviceUpdateWithId:self.contact.contactId password:self.contact.contactPassword];
            }
        }
            break;
            
        case SWITH_APSTA_MODE:
            if(buttonIndex==1){
                self.progressAlert.dimBackground = YES;
                [self.progressAlert show:YES];
                self.isSendRomoteMessageInCurrentInterface = YES;
                [[P2PClient sharedClient] switchApStaModeWithId:self.contact.contactId password:self.contact.contactPassword];
            }
            break;
            
        default:
            break;
    }
}


#define INFO_VIEW_WIDTH 240
#define INFO_VIEW_HEIGHT 200
#define TITLE_LABEL_HEIGHT 40
-(void)showDeviceInfoViewWithCurVersion:(NSString*)curVersion kernelVersion:(NSString*)kernelVersion rootfsVersion:(NSString*)rootfsVersion ubootVersion:(NSString*)ubootVersion{
    UIButton *parent = [UIButton buttonWithType:UIButtonTypeCustom];
    parent.tag = 800;
    parent.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    parent.backgroundColor = XBlack_128;
    [parent addTarget:self action:@selector(hideDeviceInfoView:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *infoView = [UIButton buttonWithType:UIButtonTypeCustom];
    infoView.layer.borderWidth = 2;
    infoView.layer.borderColor = [XBlack CGColor];
    infoView.backgroundColor = XBlack_128;
    infoView.frame = CGRectMake((parent.frame.size.width-INFO_VIEW_WIDTH)/2, (parent.frame.size.height-INFO_VIEW_HEIGHT)/2, INFO_VIEW_WIDTH, INFO_VIEW_HEIGHT);
    [infoView addTarget:self action:@selector(hideDeviceInfoView:) forControlEvents:UIControlEventTouchUpInside];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, infoView.frame.size.width, TITLE_LABEL_HEIGHT)];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = UIColorFromRGB(0xa4979b);
    titleLabel.font = XFontBold_16;
    titleLabel.text = NSLocalizedString(@"device_info", nil);
    [infoView addSubview:titleLabel];
    for(int i=0;i<8;i++){
        int x = i%2;
        int y = i/2;
        CGFloat itemWidth = INFO_VIEW_WIDTH/2-20.0;//device info
        CGFloat itemHeight = (INFO_VIEW_HEIGHT-TITLE_LABEL_HEIGHT)/4;
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake((INFO_VIEW_WIDTH-itemWidth*2)/2+itemWidth*x, titleLabel.frame.origin.y+titleLabel.frame.size.height+y*itemHeight, itemWidth, itemHeight)];//device info
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentLeft;//device info
        label.textColor = UIColorFromRGB(0xffffff);
        label.font = XFontBold_16;
        
        [infoView addSubview:label];
        [label release];
        
        switch (i) {
            case 0:
                label.text = NSLocalizedString(@"cur_version", nil);
                break;
            case 1:
                label.text = curVersion;
                break;
            case 2:
                label.text = NSLocalizedString(@"kernel_version", nil);
                break;
            case 3:
                label.text = kernelVersion;
                break;
            case 4:
                label.text = NSLocalizedString(@"rootfs_version", nil);
                break;
            case 5:
                label.text = rootfsVersion;
                break;
            case 6:
                label.text = NSLocalizedString(@"uboot_version", nil);
                break;
            case 7:
                label.text = ubootVersion;
                break;
            
        }
    }
    
    [titleLabel release];
    [parent addSubview:infoView];
    [self.view addSubview:parent];
    parent.alpha = 0.3;
    [UIView transitionWithView:parent duration:0.3 options:UIViewAnimationOptionCurveEaseInOut
                    animations:^{
                        parent.alpha = 1.0;
                    }
     
                    completion:^(BOOL Finished){
                        
                    }
     ];
    
    infoView.transform = CGAffineTransformMakeScale(0.6,0.6);
    [UIView transitionWithView:infoView duration:0.3 options:UIViewAnimationOptionCurveEaseInOut
                    animations:^{
                        infoView.transform = CGAffineTransformMakeScale(1.0,1.0);
                    }
     
                    completion:^(BOOL Finished){
                        
                    }
     ];
}

-(void)hideDeviceInfoView:(UIButton*)button{
    
    UIButton *parent = (UIButton*)[self.view viewWithTag:800];
    [UIView transitionWithView:parent duration:0.2 options:UIViewAnimationOptionCurveEaseInOut
                    animations:^{
                        parent.alpha = 0.3;
                    }
     
                    completion:^(BOOL Finished){
                        
                    }
     ];
    
    UIButton *infoView = [[parent subviews] objectAtIndex:0];
    
    [UIView transitionWithView:infoView duration:0.2 options:UIViewAnimationOptionCurveEaseInOut
                    animations:^{
                        infoView.transform = CGAffineTransformMakeScale(0.6,0.6);
                    }
     
                    completion:^(BOOL Finished){
                        [parent removeFromSuperview];
                    }
     ];
    
}

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

-(BOOL)isShowDevUpdate
{
    DWORD dwApContactID = [[AppDelegate sharedDefault] dwApContactID];
    if (dwApContactID != 0) {
        return NO;
    }
    else
    {
        BOOL isShow = (self.contact.contactType==CONTACT_TYPE_IPC || self.contact.contactType==CONTACT_TYPE_DOORBELL);
        return isShow;
    }
}

-(BOOL)isShowApStaSwitch
{
    DWORD dwApContactID = [[AppDelegate sharedDefault] dwApContactID];
    if (dwApContactID != 0) {
        return YES;
    }
    else
    {
        return [UDManager isSupportAp:self.contact.contactId.intValue];
    }
}

-(void)getRowInfo
{
    _iDevUpdateRow = -1;
    _iApStaSwitchRow = -1;
    
    if ([self isShowDevUpdate]) {
        _iDevUpdateRow = 8;
    }
    
    if ([[AppDelegate sharedDefault]dwApContactID] != 0)
    {
        _iApStaSwitchRow = 6;
    }
    else
    {
        if ([UDManager isSupportAp:self.contact.contactId.intValue])
        {
            if (_iDevUpdateRow == -1)
            {
                _iApStaSwitchRow = 8;
            }
            else
            {
                _iApStaSwitchRow = 9;
            }
        }
    }
}

@end