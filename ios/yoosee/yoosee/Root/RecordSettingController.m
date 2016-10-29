//
//  RecordSettingController.m
//  Yoosee
//
//  Created by guojunyi on 14-5-16.
//  Copyright (c) 2014年 guojunyi. All rights reserved.
//

#import "RecordSettingController.h"
#import "AppDelegate.h"
#import "TopBar.h"
#import "Toast+UIView.h"
#import "Constants.h"
#import "Contact.h"
#import "Utils.h"
#import "P2PClient.h"
#import "P2PEmailSettingCell.h"
#import "P2PRecordTimeCell.h"
#import "P2PTimeSettingCell.h"
#import "RadioButton.h"
#import "P2PPlanTimeSettingCell.h"
#import "PlanTimePickView.h"
#import "P2PSwitchCell.h"
#import "MBProgressHUD.h"

#define MESG_FORMAT_SDCARD_SUCCESS 80
#define MESG_FORMAT_SDCARD_FAIL 81
#define MESG_SDCARD_NO_EXIST 82

@interface RecordSettingController ()
{
    BOOL _isSupportPreRecord;
    BOOL _isShow;
    
    int _iPreRecordSection;//记录预录像处于第几段
    int _iStorageSection;//记录存储信息处于第几段
}
@end

@implementation RecordSettingController
-(void)dealloc{
    [self.radioRecordType1 release];
    [self.radioRecordType2 release];
    [self.radioRecordType3 release];
    [self.tableView release];
    [self.contact release];
    
    [self.planPicker1 release];
    [self.planPicker2 release];
    
    [self.progressAlert release];
    [self.sdCardPrompt release];
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveRemoteMessage:) name:RECEIVE_REMOTE_MESSAGE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ack_receiveRemoteMessage:) name:ACK_RECEIVE_REMOTE_MESSAGE object:nil];
    
    self.isLoadingRecordType = YES;
    self.isFirstCompoleteLoadRecordType = NO;
    self.recordType = SETTING_VALUE_RECORD_MANUAL;
    
    self.isLoadingRecordTime = YES;
    self.recordTime = SETTING_VALUE_RECORD_TIME_ONE;
    
    self.isLoadingRecordPlanTime = YES;

    self.isLoadingRemoteRecord = YES;
    self.remoteRecordState = SETTING_VALUE_REMOTE_RECORD_STATE_OFF;
    
    self.isLoadingPreRecord = YES;
    self.preRecordState = 0;
    
    self.isLoadingStorageInfo = YES;
    self.isLoadingStorageFormat = NO;

    
    [[P2PClient sharedClient] getNpcSettingsWithId:self.contact.contactId password:self.contact.contactPassword];
    [[P2PClient sharedClient] getSDCardInfoWithId:self.contact.contactId password:self.contact.contactPassword];
}

- (void)receiveRemoteMessage:(NSNotification *)notification{
    NSDictionary *parameter = [notification userInfo];
    int key   = [[parameter valueForKey:@"key"] intValue];
    switch(key){
        case RET_GET_NPCSETTINGS_PRERECORD:    //预录像开关
        {
            NSInteger state = [[parameter valueForKey:@"state"] intValue];
            
            self.preRecordState = (unsigned int)state;
            self.isLoadingPreRecord = NO;
            _isSupportPreRecord = YES;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
            break;
            
        case RET_SET_NPCSETTINGS_PRERECORD:     //预录像开关
        {
            NSInteger result = [[parameter valueForKey:@"result"] intValue];
            self.isLoadingPreRecord = NO;
            if(result==0){
                self.lastPreRecordState = self.preRecordState;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                });
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.preRecordState = self.lastPreRecordState;
                    [self.tableView reloadData];
                });
            }
        }
            break;
        case RET_GET_NPCSETTINGS_RECORD_TYPE:
        {
            NSInteger type = [[parameter valueForKey:@"type"] intValue];
            
            self.recordType = (unsigned int)type;
            self.isFirstCompoleteLoadRecordType = YES;
            self.isLoadingRecordType = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self.tableView reloadData];
            });
            DLog(@"record type:%i",type);
            
        }
        break;
        case RET_SET_NPCSETTINGS_RECORD_TYPE:
        {
            NSInteger result = [[parameter valueForKey:@"result"] intValue];
            self.isLoadingRecordType = NO;
            if(result==0){
                
                [[P2PClient sharedClient] getNpcSettingsWithId:self.contact.contactId password:self.contact.contactPassword];//类型设置成功，刷新各设置
                
                self.lastRecordType = self.recordType;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];

                    [self.view makeToast:NSLocalizedString(@"operator_success", nil)];
                });
                
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.recordType = self.lastRecordType;
                    [self.tableView reloadData];
                    [self.view makeToast:NSLocalizedString(@"operator_failure", nil)];
                });
            }
        }
        break;
        case RET_GET_NPCSETTINGS_RECORD_TIME:
        {
            NSInteger time = [[parameter valueForKey:@"time"] intValue];
            
            self.recordTime = time;
            self.isFirstCompoleteLoadRecordType = YES;
            self.isLoadingRecordTime = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
            DLog(@"record time:%i",time);
        }
        break;
        case RET_SET_NPCSETTINGS_RECORD_TIME:
        {
            NSInteger result = [[parameter valueForKey:@"result"] intValue];
            self.isLoadingRecordTime = NO;
            if(result==0){
                self.lastRecordTime = self.recordTime;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                    [self.view makeToast:NSLocalizedString(@"operator_success", nil)];
                });
                
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.recordTime = self.lastRecordTime;
                    [self.tableView reloadData];
                    [self.view makeToast:NSLocalizedString(@"operator_failure", nil)];
                });
            }
        }
            break;
        case RET_GET_NPCSETTINGS_RECORD_PLAN_TIME:
        {
            NSInteger time = [[parameter valueForKey:@"time"] intValue];
            
            self.planTime = time;
            self.isFirstCompoleteLoadRecordType = YES;
            self.isLoadingRecordPlanTime = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
            DLog(@"record plan time:%i",time);
        }
            break;
        case RET_SET_NPCSETTINGS_RECORD_PLAN_TIME:
        {
            NSInteger result = [[parameter valueForKey:@"result"] intValue];
            self.isLoadingRecordPlanTime = NO;
            if(result==0){
                self.lastPlanTime = self.planTime;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                    [self.view makeToast:NSLocalizedString(@"operator_success", nil)];
                });
                
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.planTime = self.lastPlanTime;
                    [self.tableView reloadData];
                    [self.view makeToast:NSLocalizedString(@"operator_failure", nil)];
                });
            }
        }
            break;
        case RET_GET_NPCSETTINGS_REMOTE_RECORD:
        {
            NSInteger state = [[parameter valueForKey:@"state"] intValue];
            
            self.remoteRecordState = (unsigned int)state;
            self.isLoadingRemoteRecord = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                //usleep(500000);
                [self.tableView reloadData];
            });
            DLog(@"remote record state:%i",state);
            
        }
            break;
        case RET_SET_NPCSETTINGS_REMOTE_RECORD:
        {
            //NSInteger result = [[parameter valueForKey:@"result"] integerValue];
            [[P2PClient sharedClient] getNpcSettingsWithId:self.contact.contactId password:self.contact.contactPassword];
        }
            break;
            
            
        //storage
        case RET_GET_SDCARD_INFO:
        {
            NSInteger result = [[parameter valueForKey:@"result"] intValue];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (result == 1) {
                    int storageCount = [[parameter valueForKey:@"storageCount"] intValue];
                    self.storageCount = storageCount;
                    self.sdCardID = [[parameter valueForKey:@"sdCardID"] intValue];
                    self.storageType = [[parameter valueForKey:@"storageType"] intValue];
                    
                    if (self.storageType == SDCARD) {
                        NSString * sdTotalStorage = [NSString stringWithFormat:@"%@M",[parameter valueForKey:@"sdTotalStorage"]];
                        self.sdTotalStorage = sdTotalStorage;
                        NSString * sdFreeStorage = [NSString stringWithFormat:@"%@M",[parameter valueForKey:@"sdFreeStorage"]];
                        self.sdFreeStorage = sdFreeStorage;
                    }else{
                        NSString * usbTotalStorage = [NSString stringWithFormat:@"%@M",[parameter valueForKey:@"usbTotalStorage"]];
                        self.usbTotalStorage = usbTotalStorage;
                        NSString * usbFreeStorage = [NSString stringWithFormat:@"%@M",[parameter valueForKey:@"usbFreeStorage"]];
                        self.usbFreeStorage = usbFreeStorage;
                    }
                    
                    if (storageCount > 1) {
                        self.storageCount = storageCount;
                        if (self.storageType == SDCARD) {NSString * usbTotalStorage = [NSString stringWithFormat:@"%@M",[parameter valueForKey:@"usbTotalStorage"]];
                            self.usbTotalStorage = usbTotalStorage;
                            NSString * usbFreeStorage = [NSString stringWithFormat:@"%@M",[parameter valueForKey:@"usbFreeStorage"]];
                            self.usbFreeStorage = usbFreeStorage;
                        }else{
                            NSString * sdTotalStorage = [NSString stringWithFormat:@"%@M",[parameter valueForKey:@"sdTotalStorage"]];
                            self.sdTotalStorage = sdTotalStorage;
                            NSString * sdFreeStorage = [NSString stringWithFormat:@"%@M",[parameter valueForKey:@"sdFreeStorage"]];
                            self.sdFreeStorage = sdFreeStorage;
                        }
                    }
                    
                    self.isLoadingStorageInfo = NO;
                    [self.tableView reloadData];
                    
                    
                    //
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.sdCardPrompt setHidden:YES];
                    });
                    
                }else{
                    //1.存储器不存在，隐藏表格--->return 0;
                    self.storageCount = 0;
                    
                    //
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.sdCardPrompt setHidden:NO];
                    });
                    
                    
                    [self.tableView reloadData];
                    //2.隐藏表格时，显示提示信息
                    if (_isShow) {
                        [self.view makeToast:NSLocalizedString(@"no_storage", nil)];
                        /*
                        dispatch_async(dispatch_get_main_queue(), ^{
                            sleep(1);
                            _isShow = !_isShow;
                            [self onBackPress];
                        });
                         */
                    }
                    
                }
            });
        }
            break;
        case RET_SET_SDCARD_FORMAT:
        {
            int result = [[parameter valueForKey:@"result"] intValue];
            self.isLoadingStorageFormat = NO;
            if (result == MESG_FORMAT_SDCARD_SUCCESS) {
                //格式化成功
                [[P2PClient sharedClient] getSDCardInfoWithId:self.contact.contactId password:self.contact.contactPassword];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                    [self.view makeToast:NSLocalizedString(@"sd_format_success", nil)];
                });
            }else if (result == MESG_FORMAT_SDCARD_FAIL){
                //格式化失败(可能设备的原因)
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                    [self.view makeToast:NSLocalizedString(@"not_support_format", nil)];
                });
            }else{
                //SD卡不存在
            }
        }
            break;
        case RET_DEVICE_NOT_SUPPORT:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self.progressAlert hide:YES];
                [self.view makeToast:NSLocalizedString(@"device_not_support", nil)];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    usleep(800000);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self onBackPress];
                    });
                });
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
        case ACK_RET_GET_NPC_SETTINGS:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(result==1){
                    [self.view makeToast:NSLocalizedString(@"device_password_error", nil)];
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        usleep(800000);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self onBackPress];
                        });
                    });
                }else if(result==2){
                    DLog(@"resend get npc settings");
                    [[P2PClient sharedClient] getNpcSettingsWithId:self.contact.contactId password:self.contact.contactPassword];
                }
                
                
            });
            
            
            
            
            
            DLog(@"ACK_RET_GET_NPC_SETTINGS:%i",result);
        }
            break;
        case ACK_RET_SET_NPCSETTINGS_RECORD_TYPE:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(result==1){
                    [self.view makeToast:NSLocalizedString(@"device_password_error", nil)];
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        usleep(800000);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self onBackPress];
                        });
                    });
                }else if(result==2){
                    DLog(@"resend set record type");
                    [[P2PClient sharedClient] setRecordTypeWithId:self.contact.contactId password:self.contact.contactPassword type:self.recordType];
                }
                
                
            });
            DLog(@"ACK_RET_SET_NPCSETTINGS_RECORD_TYPE:%i",result);
        }
            break;
        case ACK_RET_SET_NPCSETTINGS_RECORD_TIME:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(result==1){
                    [self.view makeToast:NSLocalizedString(@"device_password_error", nil)];
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        usleep(800000);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self onBackPress];
                        });
                    });
                }else if(result==2){
                    DLog(@"resend set record time");
                    [[P2PClient sharedClient] setRecordTimeWithId:self.contact.contactId password:self.contact.contactPassword value:self.recordTime];
                }
                
                
            });
            DLog(@"ACK_RET_SET_NPCSETTINGS_RECORD_TIME:%i",result);
        }
            break;
        case ACK_RET_SET_NPCSETTINGS_RECORD_PLAN_TIME:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(result==1){
                    [self.view makeToast:NSLocalizedString(@"device_password_error", nil)];
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        usleep(800000);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self onBackPress];
                        });
                    });
                }else if(result==2){
                    DLog(@"resend set record plan time");
                    [[P2PClient sharedClient] setRecordPlanTimeWithId:self.contact.contactId password:self.contact.contactPassword time:self.planTime];
                }
                
                
            });
            DLog(@"ACK_RET_SET_NPCSETTINGS_RECORD_PLAN_TIME:%i",result);
        }
            break;
        case ACK_RET_SET_NPCSETTINGS_REMOTE_RECORD:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(result==1){
                    [self.view makeToast:NSLocalizedString(@"device_password_error", nil)];
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        usleep(800000);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self onBackPress];
                        });
                    });
                }else if(result==2){
                    DLog(@"resend set remote record state");
                    [[P2PClient sharedClient] setRemoteRecordWithId:self.contact.contactId password:self.contact.contactPassword state:self.remoteRecordState];
                }
                
                
            });

            DLog(@"ACK_RET_SET_NPCSETTINGS_REMOTE_RECORD:%i",result);
        }
            break;
        case ACK_RET_SET_NPCSETTINGS_RECORD_PRE:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(result==1){
                    [self.view makeToast:NSLocalizedString(@"device_password_error", nil)];
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        usleep(800000);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self onBackPress];
                        });
                    });
                }else if(result==2){
                    [[P2PClient sharedClient] setRecordPreWithId:self.contact.contactId password:self.contact.contactPassword state:self.preRecordState];
                }
            });
        }
            break;
            
        //storage
        case ACK_RET_GET_SDCARD_INFO:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(result==1){
                    [self.progressAlert hide:YES];
                    [self.view makeToast:NSLocalizedString(@"device_password_error", nil)];
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        usleep(800000);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self onBackPress];
                        });
                    });
                    
                }else if(result==2){
                    DLog(@"resend do device update");
                    [[P2PClient sharedClient] getSDCardInfoWithId:self.contact.contactId password:self.contact.contactPassword];
                }
                
                
            });
            
            DLog(@"ACK_RET_GET_SDCARD_INFO:%i",result);
        }
            break;
        case ACK_RET_SET_SDCARD_INFO:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(result==1){
                    [self.progressAlert hide:YES];
                    [self.view makeToast:NSLocalizedString(@"device_password_error", nil)];
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        usleep(800000);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self onBackPress];
                        });
                    });
                    
                }else if(result==2){
                    DLog(@"resend do device update");
                    [[P2PClient sharedClient] setSDCardInfoWithId:self.contact.contactId password:self.contact.contactPassword sdcardID:self.sdCardID];
                }
                
                
            });
            
            DLog(@"ACK_RET_GET_SDCARD_INFO:%i",result);
        }
            break;

    }
    
}
    
- (void)viewDidLoad
    {
        [super viewDidLoad];
        _isShow = YES;
        [self initComponent];
        // Do any additional setup after loading the view.
    }
    
- (void)didReceiveMemoryWarning
    {
        [super didReceiveMemoryWarning];
        // Dispose of any resources that can be recreated.
    }
    
-(void)initComponent{
    [self.view setBackgroundColor:XBgColor];
    CGRect rect = [AppDelegate getScreenSize:YES isHorizontal:NO];
    CGFloat width = rect.size.width;
    CGFloat height = rect.size.height;
    
    TopBar *topBar = [[TopBar alloc] initWithFrame:CGRectMake(0, 0, width, NAVIGATION_BAR_HEIGHT)];
    [topBar setTitle:NSLocalizedString(@"record_set",nil)];
    [topBar setBackButtonHidden:NO];
    [topBar.backButton addTarget:self action:@selector(onBackPress) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:topBar];
    [topBar release];
    
    
    
    //SD卡不存在文本提示
    UILabel *sdCardPrompt = [[UILabel alloc] initWithFrame:CGRectMake(30.0, NAVIGATION_BAR_HEIGHT, width-30.0, 30.0)];
    sdCardPrompt.backgroundColor = XBGAlpha;
    sdCardPrompt.text = NSLocalizedString(@"no_storage",nil);
    [sdCardPrompt setFont:XFontBold_16];
    sdCardPrompt.textColor = [UIColor redColor];
    sdCardPrompt.numberOfLines = 0;
    [self.view addSubview:sdCardPrompt];
    [sdCardPrompt setHidden:YES];
    self.sdCardPrompt = sdCardPrompt;
    [sdCardPrompt release];
    
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, NAVIGATION_BAR_HEIGHT, width, height-NAVIGATION_BAR_HEIGHT) style:UITableViewStyleGrouped];
    [tableView setBackgroundColor:XBGAlpha];
    tableView.backgroundView = nil;
    [tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    tableView.delegate = self;
    tableView.dataSource = self;
    [self.view addSubview:tableView];
    self.tableView = tableView;
    [tableView release];
    
    
}
    
-(void)onBackPress{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RECEIVE_REMOTE_MESSAGE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ACK_RECEIVE_REMOTE_MESSAGE object:nil];
    [self.navigationController popViewControllerAnimated:YES];
}
    
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    /*
     1、录像模式
     2、录像开关(手动) or 录像时长(报警) or 计划时间表(定时)
     3、预录像(报警录像+支持)
     4、存储信息
     */
    
    int iSectionCount = 2;
    if(self.recordType==SETTING_VALUE_RECORD_ALARM && _isSupportPreRecord){
        iSectionCount ++;
    }
    
    if (self.storageCount>0) {
        iSectionCount ++;
    }
    
    return iSectionCount;
}
    
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    [self GetSectionInfo];
    
    if(section==0){
        if(self.isFirstCompoleteLoadRecordType){
            return 2;
        }else{
            return 1;
        }
        
    }else if(section==1){
        if(self.recordType==SETTING_VALUE_RECORD_ALARM){
            return 2;
        }else if(self.recordType==SETTING_VALUE_RECORD_TIMER){
            return 3;
        }else if(self.recordType==SETTING_VALUE_RECORD_MANUAL){
            return 1;
        }else{
            return 0;
        }
        
    }else if(section==_iPreRecordSection){
        return 1;
    }else  if(section==_iStorageSection){
        int iStorageRows = self.storageCount*2;
        if (self.storageType == SDCARD) {
            iStorageRows ++;
        }
        return iStorageRows;
    }
    return 1;
}
    
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.section==0&&indexPath.row==1){
        return BAR_BUTTON_HEIGHT*3;
    }else if(indexPath.section==1&&self.recordType==SETTING_VALUE_RECORD_TIMER){
        if(indexPath.row==1){
            return BAR_BUTTON_HEIGHT*3;
        }else{
            return BAR_BUTTON_HEIGHT;
        }
    }else{
        return BAR_BUTTON_HEIGHT;
    }
    
    
}
    
-(BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath{
    if(self.recordType==SETTING_VALUE_RECORD_TIMER&&indexPath.section==1&&indexPath.row==2){
        return YES;
    }
    
    [self GetSectionInfo];
    if (indexPath.section == _iStorageSection && 1 == self.storageCount && 2==indexPath.row) {
        return YES;
    }
    
    return NO;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier1 = @"P2PEmailSettingCell1";
    static NSString *identifier2 = @"P2PEmailSettingCell2";
    static NSString *identifier3 = @"P2PEmailSettingCell3";
    static NSString *identifier4 = @"P2PEmailSettingCell4";
    static NSString *identifier5 = @"P2PEmailSettingCell5";
    static NSString *identifier6 = @"P2PEmailSettingCell6";
    static NSString *identifier7 = @"P2PEmailSettingCell7";
    static NSString *identifier8 = @"P2PEmailSettingCell8";
    static NSString *identifier9 = @"P2PEmailSettingCell9";
    static NSString *identifier10 = @"P2PEmailSettingCell10";
    static NSString *identifier11 = @"P2PEmailSettingCell11";
    static NSString *identifier12 = @"P2PEmailSettingCell12";
    static NSString *identifier13 = @"P2PEmailSettingCell13";
    
    //CGRect rect = [AppDelegate getScreenSize:YES isHorizontal:NO];
    UITableViewCell *cell = nil;
    
    
    int section = (int)indexPath.section;
    int row = (int)indexPath.row;
    
    UIImage *backImg = nil;
    UIImage *backImg_p = nil;
    
    [self GetSectionInfo];
    
    if(section==0){
        if(row==0){
            cell = [tableView dequeueReusableCellWithIdentifier:identifier1];
            if(cell==nil){
                cell = [[[P2PEmailSettingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier1] autorelease];
                [cell setBackgroundColor:XBGAlpha];
            }
        }else if(row==1){
            cell = [tableView dequeueReusableCellWithIdentifier:identifier2];
            if(cell==nil){
                cell = [[[P2PRecordTypeCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier2] autorelease];
                P2PRecordTypeCell* cellx = (P2PRecordTypeCell*)cell;
                cellx.delegate = self;
                [cell setBackgroundColor:XBGAlpha];
            }
        }
        
        
    }else if(section==1){
        if(self.recordType==SETTING_VALUE_RECORD_ALARM){
            if(row==0){
                cell = [tableView dequeueReusableCellWithIdentifier:identifier3];
                if(cell==nil){
                    cell = [[[P2PEmailSettingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier3] autorelease];
                    [cell setBackgroundColor:XBGAlpha];
                }
            }else if(row==1){
                cell = [tableView dequeueReusableCellWithIdentifier:identifier4];
                if(cell==nil){
                    cell = [[[P2PRecordTimeCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier4] autorelease];
                    [cell setBackgroundColor:XBGAlpha];
                }
            }
        }else if(self.recordType==SETTING_VALUE_RECORD_TIMER){
            if(row==0){
                cell = [tableView dequeueReusableCellWithIdentifier:identifier5];
                if(cell==nil){
                    cell = [[[P2PEmailSettingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier5] autorelease];
                    [cell setBackgroundColor:XBGAlpha];
                }
            }else if(row==1){
                cell = [tableView dequeueReusableCellWithIdentifier:identifier6];
                if(cell==nil){
                    cell = [[[P2PPlanTimeSettingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier6] autorelease];
                    [cell setBackgroundColor:XBGAlpha];
                }
            }else if(row==2){
                cell = [tableView dequeueReusableCellWithIdentifier:identifier7];
                if(cell==nil){
                    cell = [[[P2PTimeSettingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier7] autorelease];
                    [cell setBackgroundColor:XBGAlpha];
                }
            }
        }else if(self.recordType==SETTING_VALUE_RECORD_MANUAL){
            if(row==0){
                cell = [tableView dequeueReusableCellWithIdentifier:identifier8];
                if(cell==nil){
                    cell = [[[P2PSwitchCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier8] autorelease];
                    [cell setBackgroundColor:XBGAlpha];
                }
            }
        }
    }else if(section==_iPreRecordSection){
        cell = [tableView dequeueReusableCellWithIdentifier:identifier9];
        if(cell==nil){
            cell = [[[P2PSwitchCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier9] autorelease];
            [cell setBackgroundColor:XBGAlpha];
        }
    }
    else if (section == _iStorageSection)
    {
        NSString *identifier[4] = {identifier10, identifier11, identifier12, identifier13};

        cell = [tableView dequeueReusableCellWithIdentifier:identifier[row]];
        if(cell==nil){
            cell = [[[P2PEmailSettingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier[row]] autorelease];
            [cell setBackgroundColor:XBGAlpha];
        }
    }
    
        
        if (0==section)
        {
            
            if(row==0){
                P2PEmailSettingCell *emailCell = (P2PEmailSettingCell*)cell;
                if(self.isFirstCompoleteLoadRecordType){
                    backImg = [UIImage imageNamed:@"bg_bar_btn_top.png"];
                    backImg_p = [UIImage imageNamed:@"bg_bar_btn_top_p.png"];
                }else{
                    backImg = [UIImage imageNamed:@"bg_bar_btn_single.png"];
                    backImg_p = [UIImage imageNamed:@"bg_bar_btn_single_p.png"];
                }
                [emailCell setLeftLabelText:NSLocalizedString(@"record_type", nil)];
                if(self.isLoadingRecordType){
                    [emailCell setLeftIconHidden:YES];
                    [emailCell setLeftLabelHidden:NO];
                    [emailCell setRightIconHidden:YES];
                    [emailCell setRightLabelHidden:YES];
                    [emailCell setProgressViewHidden:NO];
                }else{
                    [emailCell setLeftIconHidden:YES];
                    [emailCell setLeftLabelHidden:NO];
                    [emailCell setRightIconHidden:YES];
                    [emailCell setRightLabelHidden:YES];
                    [emailCell setProgressViewHidden:YES];
                }
                
            }else if(row==1){
                P2PRecordTypeCell *recordTypeCell = (P2PRecordTypeCell*)cell;
                backImg = [UIImage imageNamed:@"bg_bar_btn_bottom.png"];
                backImg_p = [UIImage imageNamed:@"bg_bar_btn_bottom_p.png"];
                self.radioRecordType1 = recordTypeCell.radio1;
                self.radioRecordType2 = recordTypeCell.radio2;
                self.radioRecordType3 = recordTypeCell.radio3;
                /*
                [recordTypeCell.radio1 addTarget:self action:@selector(onRadioRecordType1Press) forControlEvents:UIControlEventTouchUpInside];
                [recordTypeCell.radio2 addTarget:self action:@selector(onRadioRecordType2Press) forControlEvents:UIControlEventTouchUpInside];
                [recordTypeCell.radio3 addTarget:self action:@selector(onRadioRecordType3Press) forControlEvents:UIControlEventTouchUpInside];
                 */
                if(self.recordType==SETTING_VALUE_RECORD_MANUAL){
                    [recordTypeCell setSelectedIndex:0];
                }else if(self.recordType==SETTING_VALUE_RECORD_ALARM){
                    [recordTypeCell setSelectedIndex:1];
                }else if(self.recordType==SETTING_VALUE_RECORD_TIMER){
                    [recordTypeCell setSelectedIndex:2];
                }
            }
            
        }

        if (1==section)
        {
            if(self.recordType==SETTING_VALUE_RECORD_ALARM){
                if(row==0){
                    P2PEmailSettingCell *emailCell = (P2PEmailSettingCell*)cell;
                    backImg = [UIImage imageNamed:@"bg_bar_btn_top.png"];
                    backImg_p = [UIImage imageNamed:@"bg_bar_btn_top_p.png"];
                    [emailCell setLeftLabelText:NSLocalizedString(@"record_time", nil)];
                    if(self.isLoadingRecordTime){
                        [emailCell setLeftIconHidden:YES];
                        [emailCell setLeftLabelHidden:NO];
                        [emailCell setRightIconHidden:YES];
                        [emailCell setRightLabelHidden:YES];
                        [emailCell setProgressViewHidden:NO];
                    }else{
                        [emailCell setLeftIconHidden:YES];
                        [emailCell setLeftLabelHidden:NO];
                        [emailCell setRightIconHidden:YES];
                        [emailCell setRightLabelHidden:YES];
                        [emailCell setProgressViewHidden:YES];
                    }
                }else if(row==1){
                    P2PRecordTimeCell *recordTimeCell = (P2PRecordTimeCell*)cell;
                    backImg = [UIImage imageNamed:@"bg_bar_btn_bottom.png"];
                    backImg_p = [UIImage imageNamed:@"bg_bar_btn_bottom_p.png"];
                    
                    recordTimeCell.delegate = self;
                    if(self.recordTime==SETTING_VALUE_RECORD_TIME_ONE){
                        
                        [recordTimeCell setSelectedIndex:0];
                    }else if(self.recordTime==SETTING_VALUE_RECORD_TIME_TWO){
                        
                        [recordTimeCell setSelectedIndex:1];
                    }else if(self.recordTime==SETTING_VALUE_RECORD_TIME_THREE){
                        
                        [recordTimeCell setSelectedIndex:2];
                    }
                }
            }else if(self.recordType==SETTING_VALUE_RECORD_TIMER){
                if(row==0){
                    P2PEmailSettingCell *emailCell = (P2PEmailSettingCell*)cell;
                    backImg = [UIImage imageNamed:@"bg_bar_btn_top.png"];
                    backImg_p = [UIImage imageNamed:@"bg_bar_btn_top_p.png"];
                    [emailCell setLeftLabelText:NSLocalizedString(@"plan_time_table", nil)];
                    [emailCell setLeftIconHidden:YES];
                    [emailCell setLeftLabelHidden:NO];
                    [emailCell setRightIconHidden:YES];
                    [emailCell setRightLabelHidden:YES];
                    [emailCell setProgressViewHidden:YES];
                }else if(row==1){
                    P2PPlanTimeSettingCell *planTimeCell = (P2PPlanTimeSettingCell*)cell;
                    planTimeCell.planTime = self.planTime;
                    backImg = [UIImage imageNamed:@"bg_bar_btn_center.png"];
                    backImg_p = [UIImage imageNamed:@"bg_bar_btn_center_p.png"];
                    self.planPicker1 = planTimeCell.picker1;
                    self.planPicker2 = planTimeCell.picker2;
                }else if(row==2){
                    P2PTimeSettingCell *timeCell = (P2PTimeSettingCell*)cell;
                    backImg = [UIImage imageNamed:@"bg_bar_btn_bottom.png"];
                    backImg_p = [UIImage imageNamed:@"bg_bar_btn_bottom_p.png"];
                    [timeCell setLeftLabelHidden:NO];
                    if(self.isLoadingRecordPlanTime){
                        [timeCell setRightLabelHidden:YES];
                        [timeCell setProgressViewHidden:NO];
                    }else{
                        [timeCell setRightLabelHidden:NO];
                        [timeCell setProgressViewHidden:YES];
                    }
                    [timeCell setCustomViewHidden:YES];
                    [timeCell setLeftLabelText:NSLocalizedString(@"apply", nil)];
                    [timeCell setRightLabelText:[Utils getPlanTimeByIntValue:self.planTime]];
                }
            }else if(self.recordType==SETTING_VALUE_RECORD_MANUAL){
                if(row==0){
                    P2PSwitchCell *switchCell = (P2PSwitchCell*)cell;
                    backImg = [UIImage imageNamed:@"bg_bar_btn_single.png"];
                    backImg_p = [UIImage imageNamed:@"bg_bar_btn_single_p.png"];
                    [switchCell setLeftLabelText:NSLocalizedString(@"remote_record_switch", nil)];
                    
                    switchCell.delegate = self;
                    switchCell.indexPath = indexPath;
                    
                    if(self.isLoadingRemoteRecord){
                        [switchCell setProgressViewHidden:NO];
                        [switchCell setSwitchViewHidden:YES];
                    }else{
                        [switchCell setProgressViewHidden:YES];
                        [switchCell setSwitchViewHidden:NO];
                        if(self.remoteRecordState==SETTING_VALUE_REMOTE_RECORD_STATE_OFF){
                            switchCell.on = NO;
                        }else{
                            switchCell.on = YES;
                            
                        }
                    }
                }
            }
        }
    
        if (_iPreRecordSection==section)
        {
            P2PSwitchCell *switchCell = (P2PSwitchCell*)cell;
            backImg = [UIImage imageNamed:@"bg_bar_btn_single.png"];
            backImg_p = [UIImage imageNamed:@"bg_bar_btn_single_p.png"];
            [switchCell setLeftLabelText:NSLocalizedString(@"early_record", nil)];
            
            switchCell.delegate = self;
            switchCell.indexPath = indexPath;
            
            if(self.isLoadingPreRecord){
                [switchCell setProgressViewHidden:NO];
                [switchCell setSwitchViewHidden:YES];
            }else{
                [switchCell setProgressViewHidden:YES];
                [switchCell setSwitchViewHidden:NO];
                if(self.preRecordState==0){
                    switchCell.on = NO;
                }else{
                    switchCell.on = YES;
                    
                }
            }
            
        }
    
    if (_iStorageSection == section) {
        P2PEmailSettingCell *cellx = (P2PEmailSettingCell*)cell;
        
        [cellx setRightIcon:@"ic_arrow.png"];
        
        if (self.storageCount == 1)
        {
            NSString * totalStorageName = nil;
            NSString * freeStorageName = nil;
            NSString * totalStorage = nil;
            NSString * freeStorage = nil;
            if (self.storageType == SDCARD) {
                totalStorageName = NSLocalizedString(@"sd_card_capacity", nil);
                freeStorageName = NSLocalizedString(@"sd_card_rem_capacity", nil);
                totalStorage = self.sdTotalStorage;
                freeStorage = self.sdFreeStorage;
            }else{
                totalStorageName = NSLocalizedString(@"u_disk_capacity", nil);
                freeStorageName = NSLocalizedString(@"u_disk_rem_capacity", nil);
                totalStorage = self.usbTotalStorage;
                freeStorage = self.usbFreeStorage;
            }
            
            if(row==0){
                backImg = [UIImage imageNamed:@"bg_bar_btn_top.png"];
                backImg_p = [UIImage imageNamed:@"bg_bar_btn_top_p.png"];
                
                [cellx setLeftLabelText:totalStorageName];
                if(self.isLoadingStorageInfo){
                    [cellx setLeftLabelHidden:NO];
                    [cellx setRightLabelHidden:YES];
                    [cellx setProgressViewHidden:NO];
                    
                    [cellx setLeftIconHidden:YES];
                    [cellx setRightIconHidden:YES];
                }else{
                    [cellx setRightLabelText:totalStorage];
                    
                    [cellx setLeftLabelHidden:NO];
                    [cellx setRightLabelHidden:NO];
                    [cellx setProgressViewHidden:YES];
                    
                    [cellx setLeftIconHidden:YES];
                    [cellx setRightIconHidden:YES];
                }
            }else if(row==1){
                if (SDCARD == self.sdCardID)
                {
                    backImg = [UIImage imageNamed:@"bg_bar_btn_center.png"];
                    backImg_p = [UIImage imageNamed:@"bg_bar_btn_center_p.png"];
                }
                else
                {
                    backImg = [UIImage imageNamed:@"bg_bar_btn_bottom.png"];
                    backImg_p = [UIImage imageNamed:@"bg_bar_btn_bottom_p.png"];
                }

                
                [cellx setLeftLabelText:freeStorageName];
                if(self.isLoadingStorageInfo){
                    [cellx setLeftLabelHidden:NO];
                    [cellx setRightLabelHidden:YES];
                    [cellx setProgressViewHidden:NO];
                    
                    [cellx setLeftIconHidden:YES];
                    [cellx setRightIconHidden:YES];
                }else{
                    [cellx setRightLabelText:freeStorage];
                    
                    [cellx setLeftLabelHidden:NO];
                    [cellx setRightLabelHidden:NO];
                    [cellx setProgressViewHidden:YES];
                    
                    [cellx setLeftIconHidden:YES];
                    [cellx setRightIconHidden:YES];
                }
            }
            else if (row==2)    //格式化
            {
                backImg = [UIImage imageNamed:@"bg_bar_btn_bottom.png"];
                backImg_p = [UIImage imageNamed:@"bg_bar_btn_bottom_p.png"];
                
                [cellx setLeftLabelText:NSLocalizedString(@"sd_card_format", nil)];
                if(self.isLoadingStorageFormat){
                    [cellx setLeftLabelHidden:NO];
                    [cellx setRightLabelHidden:YES];
                    [cellx setProgressViewHidden:NO];
                    
                    [cellx setLeftIconHidden:YES];
                    [cellx setRightIconHidden:YES];
                }else{
                    [cellx setLeftLabelHidden:NO];
                    [cellx setRightLabelHidden:YES];
                    [cellx setProgressViewHidden:YES];
                    
                    [cellx setLeftIconHidden:YES];
                    [cellx setRightIconHidden:NO];
                }
            }
        }else{
            if(row==0){
                backImg = [UIImage imageNamed:@"bg_bar_btn_top.png"];
                backImg_p = [UIImage imageNamed:@"bg_bar_btn_top_p.png"];
                
                [cellx setLeftLabelText:NSLocalizedString(@"sd_card_capacity", nil)];
                if(self.isLoadingStorageInfo){
                    [cellx setLeftLabelHidden:NO];
                    [cellx setRightLabelHidden:YES];
                    [cellx setProgressViewHidden:NO];
                    
                    [cellx setLeftIconHidden:YES];
                    [cellx setRightIconHidden:YES];
                }else{
                    [cellx setRightLabelText:self.sdTotalStorage];
                    
                    [cellx setLeftLabelHidden:NO];
                    [cellx setRightLabelHidden:NO];
                    [cellx setProgressViewHidden:YES];
                    
                    [cellx setLeftIconHidden:YES];
                    [cellx setRightIconHidden:YES];
                }
            }else if(row==1){
                backImg = [UIImage imageNamed:@"bg_bar_btn_center.png"];
                backImg_p = [UIImage imageNamed:@"bg_bar_btn_center_p.png"];
                
                [cellx setLeftLabelText:NSLocalizedString(@"sd_card_rem_capacity", nil)];
                if(self.isLoadingStorageInfo){
                    [cellx setLeftLabelHidden:NO];
                    [cellx setRightLabelHidden:YES];
                    [cellx setProgressViewHidden:NO];
                    
                    [cellx setLeftIconHidden:YES];
                    [cellx setRightIconHidden:YES];
                }else{
                    [cellx setRightLabelText:self.sdFreeStorage];
                    
                    [cellx setLeftLabelHidden:NO];
                    [cellx setRightLabelHidden:NO];
                    [cellx setProgressViewHidden:YES];
                    
                    [cellx setLeftIconHidden:YES];
                    [cellx setRightIconHidden:YES];
                }
            }else if(row==2){
                backImg = [UIImage imageNamed:@"bg_bar_btn_center.png"];
                backImg_p = [UIImage imageNamed:@"bg_bar_btn_center_p.png"];
                
                [cellx setLeftLabelText:NSLocalizedString(@"u_disk_capacity", nil)];
                if(self.isLoadingStorageInfo){
                    [cellx setLeftLabelHidden:NO];
                    [cellx setRightLabelHidden:YES];
                    [cellx setProgressViewHidden:NO];
                    
                    [cellx setLeftIconHidden:YES];
                    [cellx setRightIconHidden:YES];
                }else{
                    [cellx setRightLabelText:self.usbTotalStorage];
                    
                    [cellx setLeftLabelHidden:NO];
                    [cellx setRightLabelHidden:NO];
                    [cellx setProgressViewHidden:YES];
                    
                    [cellx setLeftIconHidden:YES];
                    [cellx setRightIconHidden:YES];
                }
            }else{
                backImg = [UIImage imageNamed:@"bg_bar_btn_bottom.png"];
                backImg_p = [UIImage imageNamed:@"bg_bar_btn_bottom_p.png"];
                
                [cellx setLeftLabelText:NSLocalizedString(@"u_disk_rem_capacity", nil)];
                if(self.isLoadingStorageInfo){
                    [cellx setLeftLabelHidden:NO];
                    [cellx setRightLabelHidden:YES];
                    [cellx setProgressViewHidden:NO];
                    
                    [cellx setLeftIconHidden:YES];
                    [cellx setRightIconHidden:YES];
                }else{
                    [cellx setRightLabelText:self.usbFreeStorage];
                    
                    [cellx setLeftLabelHidden:NO];
                    [cellx setRightLabelHidden:NO];
                    [cellx setProgressViewHidden:YES];
                    
                    [cellx setLeftIconHidden:YES];
                    [cellx setRightIconHidden:YES];
                }
            }
        }
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


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(self.recordType==SETTING_VALUE_RECORD_TIMER&&indexPath.section==1&&indexPath.row==2){
        self.isLoadingRecordPlanTime = YES;
        [self.tableView reloadData];
        
        self.lastPlanTime = self.planTime;
        NSInteger hour_from = self.planPicker1.date.hour;
        NSInteger minute_from = self.planPicker1.date.minute;
        
        NSInteger hour_to = self.planPicker2.date.hour;
        NSInteger minute_to = self.planPicker2.date.minute;
        
        self.planTime = (int)(hour_from<<24|hour_to<<16|minute_from<<8|minute_to<<0);
        [[P2PClient sharedClient] setRecordPlanTimeWithId:self.contact.contactId password:self.contact.contactPassword time:self.planTime];
        
    }
    
    [self GetSectionInfo];
    if (indexPath.section == _iStorageSection && 1 == self.storageCount && 2==indexPath.row) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"format_sd_card", nil) message:NSLocalizedString(@"confirm_format", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:NSLocalizedString(@"ok", nil), nil];
        [alertView show];
        [alertView release];
    }
}

-(void)onClickRadioInIndex:(NSInteger)index
{
    if (index == 0) {
        if(!self.isLoadingRecordType&&!self.radioRecordType1.isSelected){
            self.isLoadingPreRecord = YES;//切换录像类型会关闭预录像,GET
            self.isLoadingRemoteRecord = YES;//录像类型切换会自动关闭手动录像,GET
            
            [self.radioRecordType1 setSelected:YES];
            [self.radioRecordType2 setSelected:NO];
            [self.radioRecordType3 setSelected:NO];
            self.isLoadingRecordType = YES;
            
            self.lastRecordType = self.recordType;
            self.recordType = SETTING_VALUE_RECORD_MANUAL;
            [self.tableView reloadData];
            
            [[P2PClient sharedClient] setRecordTypeWithId:self.contact.contactId password:self.contact.contactPassword type:self.recordType];
            
        }
    }
    else if (index == 1)
    {
        if(!self.isLoadingRecordType&&!self.radioRecordType2.isSelected){
            self.isLoadingPreRecord = YES;//切换录像类型会关闭预录像,GET
            self.isLoadingRemoteRecord = YES;//录像类型切换会自动关闭手动录像,GET
            
            [self.radioRecordType1 setSelected:NO];
            [self.radioRecordType2 setSelected:YES];
            [self.radioRecordType3 setSelected:NO];
            self.isLoadingRecordType = YES;
            
            self.lastRecordType = self.recordType;
            self.recordType = SETTING_VALUE_RECORD_ALARM;
            [self.tableView reloadData];
            
            [[P2PClient sharedClient] setRecordTypeWithId:self.contact.contactId password:self.contact.contactPassword type:self.recordType];
            
        }
    }
    else if (index == 2)
    {
        if(!self.isLoadingRecordType&&!self.radioRecordType3.isSelected){
            [self.radioRecordType1 setSelected:NO];
            [self.radioRecordType2 setSelected:NO];
            [self.radioRecordType3 setSelected:YES];
            self.isLoadingRecordType = YES;
            
            self.lastRecordType = self.recordType;
            self.recordType = SETTING_VALUE_RECORD_TIMER;
            [self.tableView reloadData];
            
            [[P2PClient sharedClient] setRecordTypeWithId:self.contact.contactId password:self.contact.contactPassword type:self.recordType];
            
        }
    }
}

#pragma mark - 手动录像
-(void)onRadioRecordType1Press{
    if(!self.isLoadingRecordType&&!self.radioRecordType1.isSelected){
        self.isLoadingPreRecord = YES;//切换录像类型会关闭预录像,GET
        self.isLoadingRemoteRecord = YES;//录像类型切换会自动关闭手动录像,GET
        
        [self.radioRecordType1 setSelected:YES];
        [self.radioRecordType2 setSelected:NO];
        [self.radioRecordType3 setSelected:NO];
        self.isLoadingRecordType = YES;
        
        self.lastRecordType = self.recordType;
        self.recordType = SETTING_VALUE_RECORD_MANUAL;
        [self.tableView reloadData];
        
        [[P2PClient sharedClient] setRecordTypeWithId:self.contact.contactId password:self.contact.contactPassword type:self.recordType];
        
    }
}

#pragma mark - 报警录像
-(void)onRadioRecordType2Press{
    if(!self.isLoadingRecordType&&!self.radioRecordType2.isSelected){
        self.isLoadingPreRecord = YES;//切换录像类型会关闭预录像,GET
        self.isLoadingRemoteRecord = YES;//录像类型切换会自动关闭手动录像,GET
        
        [self.radioRecordType1 setSelected:NO];
        [self.radioRecordType2 setSelected:YES];
        [self.radioRecordType3 setSelected:NO];
        self.isLoadingRecordType = YES;
        
        self.lastRecordType = self.recordType;
        self.recordType = SETTING_VALUE_RECORD_ALARM;
        [self.tableView reloadData];
        
        [[P2PClient sharedClient] setRecordTypeWithId:self.contact.contactId password:self.contact.contactPassword type:self.recordType];
        
    }
}

#pragma mark - 定时录像
-(void)onRadioRecordType3Press{
    if(!self.isLoadingRecordType&&!self.radioRecordType3.isSelected){
        [self.radioRecordType1 setSelected:NO];
        [self.radioRecordType2 setSelected:NO];
        [self.radioRecordType3 setSelected:YES];
        self.isLoadingRecordType = YES;
        
        self.lastRecordType = self.recordType;
        self.recordType = SETTING_VALUE_RECORD_TIMER;
        [self.tableView reloadData];
        
        [[P2PClient sharedClient] setRecordTypeWithId:self.contact.contactId password:self.contact.contactPassword type:self.recordType];
        
    }
}

#pragma mark -
-(void)onRecordTimeCellRadioClick:(RadioButton *)radio index:(NSInteger)index{
    switch(index){
        case 0:
        {
            if(!self.isLoadingRecordTime&&!self.radioRecordTime1.isSelected){
                [self.radioRecordTime1 setSelected:YES];
                [self.radioRecordTime2 setSelected:NO];
                [self.radioRecordTime3 setSelected:NO];
                self.isLoadingRecordTime = YES;
                
                self.lastRecordTime = self.recordTime;
                self.recordTime = SETTING_VALUE_RECORD_TIME_ONE;
                [self.tableView reloadData];
                [[P2PClient sharedClient] setRecordTimeWithId:self.contact.contactId password:self.contact.contactPassword value:self.recordTime];
                
            }
        }
            break;
        case 1:
        {
            if(!self.isLoadingRecordTime&&!self.radioRecordTime2.isSelected){
                [self.radioRecordTime1 setSelected:NO];
                [self.radioRecordTime2 setSelected:YES];
                [self.radioRecordTime3 setSelected:NO];
                self.isLoadingRecordTime = YES;
                
                self.lastRecordTime = self.recordTime;
                self.recordTime = SETTING_VALUE_RECORD_TIME_TWO;
                [self.tableView reloadData];
                [[P2PClient sharedClient] setRecordTimeWithId:self.contact.contactId password:self.contact.contactPassword value:self.recordTime];
                
            }
        }
            break;
        case 2:
        {
            if(!self.isLoadingRecordTime&&!self.radioRecordTime3.isSelected){
                [self.radioRecordTime1 setSelected:NO];
                [self.radioRecordTime2 setSelected:NO];
                [self.radioRecordTime3 setSelected:YES];
                self.isLoadingRecordTime = YES;
                
                self.lastRecordTime = self.recordTime;
                self.recordTime = SETTING_VALUE_RECORD_TIME_THREE;
                [self.tableView reloadData];
                [[P2PClient sharedClient] setRecordTimeWithId:self.contact.contactId password:self.contact.contactPassword value:self.recordTime];
                
            }
        }
            break;
    }
}

#pragma mark - 手动录像开关、预录像开关
-(void)onSwitchValueChange:(UISwitch *)sender indexPath:(NSIndexPath *)indexPath{
    switch (indexPath.section) {
        case 1://手动录像开关
        {
            if(self.remoteRecordState==SETTING_VALUE_REMOTE_RECORD_STATE_OFF&&sender.on){
                self.isLoadingRemoteRecord = YES;
                
                self.lastRemoteRecordState = self.remoteRecordState;
                self.remoteRecordState = SETTING_VALUE_REMOTE_RECORD_STATE_ON;
                [self.tableView reloadData];
                
                [[P2PClient sharedClient] setRemoteRecordWithId:self.contact.contactId password:self.contact.contactPassword state:self.remoteRecordState];
            }else if(self.remoteRecordState!=SETTING_VALUE_REMOTE_RECORD_STATE_OFF&&!sender.on){
                self.isLoadingRemoteRecord = YES;
                
                self.lastRemoteRecordState = self.remoteRecordState;
                self.remoteRecordState = SETTING_VALUE_REMOTE_RECORD_STATE_OFF;
                [self.tableView reloadData];
                
                [[P2PClient sharedClient] setRemoteRecordWithId:self.contact.contactId password:self.contact.contactPassword state:self.remoteRecordState];
            }
        }
            break;
        case 2://预录像开关
        {
            if(self.preRecordState==0 && sender.on){
                self.isLoadingPreRecord = YES;
                self.lastPreRecordState = self.preRecordState;
                self.preRecordState = 1;
                [self.tableView reloadData];
                
                [[P2PClient sharedClient] setRecordPreWithId:self.contact.contactId password:self.contact.contactPassword state:self.preRecordState];
            }
            else if(self.preRecordState == 1 && !sender.on){
                self.isLoadingPreRecord = YES;
                self.lastPreRecordState = self.preRecordState;
                self.preRecordState = 0;
                [self.tableView reloadData];
                
                [[P2PClient sharedClient] setRecordPreWithId:self.contact.contactId password:self.contact.contactPassword state:self.preRecordState];
            }
        }
            break;
    }
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

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex==1) {
        self.isLoadingStorageFormat = YES;
        [self.tableView reloadData];
        
        [[P2PClient sharedClient] setSDCardInfoWithId:self.contact.contactId password:self.contact.contactPassword sdcardID:self.sdCardID];
        
    }
}

-(void)GetSectionInfo
{
    int iPreRecordSection = -1;
    int iStorageSection = 2;
    if(self.recordType==SETTING_VALUE_RECORD_ALARM && _isSupportPreRecord) {
        iPreRecordSection = 2;
        iStorageSection = 3;
    }
    
    
    _iPreRecordSection = -1;
    _iStorageSection = -1;
    if(self.recordType==SETTING_VALUE_RECORD_ALARM && _isSupportPreRecord) {
        _iPreRecordSection = 2;
    }
    
    if (self.storageCount>0) {
        _iStorageSection = 2;
        if (_iPreRecordSection != -1) {
            _iStorageSection ++;
        }
    }
}
@end
