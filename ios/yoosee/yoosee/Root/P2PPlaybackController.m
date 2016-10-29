//
//  P2PPlaybackController.m
//  Yoosee
//
//  Created by guojunyi on 14-4-22.
//  Copyright (c) 2014年 guojunyi. All rights reserved.
//

#import "P2PPlaybackController.h"
#import "AppDelegate.h"
#import "Constants.h"
#import "MainController.h"
#import "TopBar.h"
#import "Utils.h"
#import "Contact.h"
#import "P2PClient.h"
#import "Toast+UIView.h"
#import "P2PPlayingbackController.h"
#import "SVPullToRefresh.h"
#import "UIScrollView+SVInfiniteScrolling.h"
@interface P2PPlaybackController ()

@end

@implementation P2PPlaybackController
-(void)dealloc{
    DLog(@"release");
    [self.contact release];
    [self.layerView release];
    [self.searchBarView release];
    [self.playbackFiles release];
    [self.playbackSize release];
    [self.timesData release];
    [self.tableView release];
    [self.searchMaskView release];
    [self.movieView release];
    [self.startTimeBtn release];
    [self.endTimeBtn release];
    [self.startTimeLabel release];
    [self.endTimeLabel release];
    [self.customView release];
    [self.cycleview release];
    [[P2PClient sharedClient] setPlaybackDelegate:nil];
    [[P2PClient sharedClient] p2pHungUp];
    
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
    if ([[AppDelegate sharedDefault]dwApContactID]) {
        mainController = [AppDelegate sharedDefault].mainController_ap;
    }
    [mainController setBottomBarHidden:YES];
    
    
   [[P2PClient sharedClient] setIsClearPlaybackFilesLength:YES];//isClearPlaybackFilesLength
}

-(void)viewDidAppear:(BOOL)animated{
    DLog(@"viewDidAppear");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveRemoteMessage:) name:RECEIVE_REMOTE_MESSAGE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ack_receiveRemoteMessage:) name:ACK_RECEIVE_REMOTE_MESSAGE object:nil];
    
    if(!self.isInitSearch){
        self.isInitSearch = !self.isInitSearch;
        [[P2PClient sharedClient] setCurrentLabel:1];
        [[P2PClient sharedClient] getPlaybackFilesWithId:self.contact.contactId password:self.contact.contactPassword timeInterval:1];
    }
    
    [[P2PClient sharedClient] setPlaybackDelegate:self];
}

-(void)viewWillDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RECEIVE_REMOTE_MESSAGE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ACK_RECEIVE_REMOTE_MESSAGE object:nil];
    
}


- (void)receiveRemoteMessage:(NSNotification *)notification{
    NSDictionary *parameter = [notification userInfo];
    int key   = [[parameter valueForKey:@"key"] intValue];
    switch(key){
        case RET_GET_PLAYBACK_FILES:
        {
            //回放文件名称
            NSArray *array = [NSArray arrayWithArray:(NSArray*)[parameter valueForKey:@"files"]];
            //回放文件的时间记录
            NSArray *times = [NSArray arrayWithArray:(NSArray*)[parameter valueForKey:@"times"]];
            //回放文件的播放时长
            NSArray *sizes = [NSArray arrayWithArray:(NSArray*)[parameter valueForKey:@"sizes"]];
            
            
            //选择最近1天、3天、1个月或者自定义时，清空存储回放文件的数组、存储播放时长的数组
            if (self.isChangePlaybackItem) {
                [self.playbackFiles removeAllObjects];
                [self.playbackSize removeAllObjects];
                self.isChangePlaybackItem = NO;
            }
            
            //若不是上拉加载更多时，则往已清空的数组存放回放文件
            //若是上拉加载更多，则往存有数据的数组末尾添加回放文件
            for (NSString *file in array){
                [self.playbackFiles addObject:file];
            }
            
            //若不是上拉加载更多时，则往数组存放回放文件的播放时长
            //若是上拉加载更多，则往数组末尾添加回放文件的播放时长
            for (NSString *size in sizes){
                [self.playbackSize addObject:size];
            }
            
            //刷新表格
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
                if (self.playbackFiles.count < 1) {
                    [self.view makeToast:NSLocalizedString(@"no_playback_file", nil)];
                }
            });
            
            
            self.timesData = [NSMutableArray arrayWithArray:times];
            if (self.timesData.count==0) {
                return;
            }
            
            //记录最近1天、3天...已显示文件里最后一个文件的时间（最早文件的时间）
            //用于上拉加载时传入的结束时间
            self.nextStartTime = [self.timesData lastObject];
        }
            break;
    }
    
}

- (void)ack_receiveRemoteMessage:(NSNotification *)notification{
    NSDictionary *parameter = [notification userInfo];
    int key   = [[parameter valueForKey:@"key"] intValue];
    int result   = [[parameter valueForKey:@"result"] intValue];
    switch(key){
        case ACK_RET_GET_PLAYBACK_FILES:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView transitionWithView:self.searchMaskView duration:0.3 options:UIViewAnimationOptionCurveEaseOut
                                animations:^{
                                    self.searchMaskView.alpha = 0.3;
                                }
                 
                                completion:^(BOOL finished){
                                    [self.searchMaskView setHidden:YES];
                                }
                 ];
                
                if(result==1){
                    [self.view makeToast:NSLocalizedString(@"device_password_error", nil)];
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        usleep(800000);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.navigationController popViewControllerAnimated:YES];
                        });
                    });
                }else if(result==2){
                    
                    [self.view makeToast:NSLocalizedString(@"net_exception", nil)];
                }
                
                
            });
            DLog(@"ACK_RET_GET_PLAYBACK_FILES:%i",result);
        }
            break;
    }
    
}

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    self.selectedLabel = 1;
    self.playbackFiles = [NSMutableArray arrayWithCapacity:0];
    self.playbackSize = [NSMutableArray arrayWithCapacity:0];
    
    [self initComponent];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#define SEARCH_BAR_HEIGHT 36
#define TOP_INFO_BAR_HEIGHT 80
#define PLAYBACK_LIST_ITEM_HEIGHT 40
#define TOP_HEAD_MARGIN 10
#define PROGRESS_WIDTH_AND_HEIGHT 58
#define ANIM_VIEW_WIDTH_AND_HEIGHT 80


-(void)initComponent{
    CGRect rect = [AppDelegate getScreenSize:YES isHorizontal:NO];
    CGFloat width = rect.size.width;
    CGFloat height = rect.size.height;
    
    [self.view setBackgroundColor:XBgColor];
    
    TopBar *topBar = [[TopBar alloc] initWithFrame:CGRectMake(0, 0, width, NAVIGATION_BAR_HEIGHT)];
    [topBar setBackButtonHidden:NO];
    [topBar.backButton addTarget:self action:@selector(onBackPress) forControlEvents:UIControlEventTouchUpInside];
    
    [topBar setTitle:NSLocalizedString(@"playback",nil)];
    [self.view addSubview:topBar];
    [topBar release];
    
    UIView *topInfoBarView = [[UIView alloc] initWithFrame:CGRectMake(0, NAVIGATION_BAR_HEIGHT, width, TOP_INFO_BAR_HEIGHT)];
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
    [self.view addSubview:topInfoBarView];
    [topInfoBarView release];
    
    
    UIView *searchBarView = [[UIView alloc] initWithFrame:CGRectMake(0, NAVIGATION_BAR_HEIGHT+TOP_INFO_BAR_HEIGHT, width, SEARCH_BAR_HEIGHT)];
    [searchBarView setBackgroundColor:XWhite];
    UIImageView *layarView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, width/4, SEARCH_BAR_HEIGHT)];
    [layarView setBackgroundColor:XBlue];
    [searchBarView addSubview:layarView];
    self.layerView = layarView;
    [layarView release];
    
    for(int i=0;i<4;i++){
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(i*width/4,0,width/4,SEARCH_BAR_HEIGHT)];
        button.tag = i;
        UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,button.frame.size.width,button.frame.size.height)];
        
        textLabel.textAlignment = NSTextAlignmentCenter;
        ;
        textLabel.backgroundColor = XBGAlpha;
        [textLabel setFont:XFontBold_14];
        if(i==0){
            textLabel.textColor = XBlack;
            textLabel.text = NSLocalizedString(@"recent_one_day", nil);
        }else if(i==1){
            textLabel.textColor = UIColorFromRGB(0x808080);
            textLabel.text = NSLocalizedString(@"recent_three_day", nil);
        }else if(i==2){
            textLabel.textColor = UIColorFromRGB(0x808080);
            textLabel.text = NSLocalizedString(@"recent_one_month", nil);
        }else if(i==3){
            textLabel.textColor = UIColorFromRGB(0x808080);
            textLabel.text = NSLocalizedString(@"custom", nil);
        }
        
        [button addSubview:textLabel];
        [button addTarget:self action:@selector(onButtonPress:) forControlEvents:UIControlEventTouchUpInside];
        [searchBarView addSubview:button];
        [textLabel release];
        [button release];
        
    }
    
    [self.view addSubview:searchBarView];
    self.searchBarView = searchBarView;
    [searchBarView release];
    
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, NAVIGATION_BAR_HEIGHT+TOP_INFO_BAR_HEIGHT+SEARCH_BAR_HEIGHT, width, height-(NAVIGATION_BAR_HEIGHT+TOP_INFO_BAR_HEIGHT+SEARCH_BAR_HEIGHT)) style:UITableViewStylePlain];
    
    tableView.delegate = self;
    tableView.dataSource = self;
    [tableView setBackgroundColor:XBGAlpha];
    [tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.view addSubview:tableView];
    
    [tableView addInfiniteScrollingWithActionHandler:^{
        
        //获取的回放文件里会包含endDate时间的文件
        NSDate * endDate = [Utils dateFromString:self.nextStartTime];
        
        if (self.selectedLabel==1) {//1 day
            NSDate *nowDate = [NSDate date];
            //1天前
            NSDate *startDate = [nowDate dateByAddingTimeInterval: -(24*60*60)];
            
            [[P2PClient sharedClient] setIsLoadMorePlaybackFilesForOneDay:YES];
            
            [[P2PClient sharedClient] getPlaybackFilesWithIdByDate:self.contact.contactId password:self.contact.contactPassword startDate:startDate endDate:endDate];
        }else if (self.selectedLabel==2){//3 days
            
            NSDate *nowDate = [NSDate date];
            //3天前
            NSDate *startDate = [nowDate dateByAddingTimeInterval: -(3*24*60*60)];
            
            [[P2PClient sharedClient] setIsLoadMorePlaybackFilesForThreeDay:YES];
            
            [[P2PClient sharedClient] getPlaybackFilesWithIdByDate:self.contact.contactId password:self.contact.contactPassword startDate:startDate endDate:endDate];
        }else if (self.selectedLabel==3){//1 mon
            
            NSDate *nowDate = [NSDate date];
            //1个月前
            NSDate *startDate = [nowDate dateByAddingTimeInterval: -(31*24*60*60)];
            
            [[P2PClient sharedClient] setIsLoadMorePlaybackFilesForOneMon:YES];
            
            [[P2PClient sharedClient] getPlaybackFilesWithIdByDate:self.contact.contactId password:self.contact.contactPassword startDate:startDate endDate:endDate];
        }else if (self.selectedLabel==4){
            
            [[P2PClient sharedClient] setIsLoadMorePlaybackFilesForCustom:YES];
            
            NSDate *customStartDate = [Utils dateFromString:self.startTime];
            [[P2PClient sharedClient] getPlaybackFilesWithIdByDate:self.contact.contactId password:self.contact.contactPassword startDate:customStartDate endDate:endDate];
        }//视频回放修复
        
        
        
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            sleep(1.0);
            dispatch_async(dispatch_get_main_queue(), ^{
                
                
                [self.tableView.infiniteScrollingView stopAnimating];
            });
        });
        
    }];
    
    self.tableView = tableView;
    [tableView release];
    
    UIView *searchMaskView = [[UIView alloc] initWithFrame:CGRectMake(0, NAVIGATION_BAR_HEIGHT, self.view.frame.size.width, self.view.frame.size.height-NAVIGATION_BAR_HEIGHT)];
    [searchMaskView setBackgroundColor:XBlack_128];
    UIActivityIndicatorView *progress = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    progress.frame = CGRectMake((searchMaskView.frame.size.width-PROGRESS_WIDTH_AND_HEIGHT)/2, (searchMaskView.frame.size.height-PROGRESS_WIDTH_AND_HEIGHT)/2, PROGRESS_WIDTH_AND_HEIGHT, PROGRESS_WIDTH_AND_HEIGHT);
    [progress startAnimating];
    [searchMaskView addSubview:progress];
    [progress release];
    [searchMaskView setHidden:NO];
    [self.view addSubview:searchMaskView];
    self.searchMaskView = searchMaskView;
    [searchMaskView release];
    
    UIView *movieView = [[UIView alloc] initWithFrame:CGRectMake(0, NAVIGATION_BAR_HEIGHT, self.view.frame.size.width, self.view.frame.size.height-NAVIGATION_BAR_HEIGHT)];
    [movieView setBackgroundColor:XBlack_128];
    UIImageView *animView = [[UIImageView alloc] initWithFrame:CGRectMake((movieView.frame.size.width-ANIM_VIEW_WIDTH_AND_HEIGHT)/2, (movieView.frame.size.height-ANIM_VIEW_WIDTH_AND_HEIGHT)/2, ANIM_VIEW_WIDTH_AND_HEIGHT, ANIM_VIEW_WIDTH_AND_HEIGHT)];
    
    NSArray *imagesArray = [NSArray arrayWithObjects:[UIImage imageNamed:@"movie1.png"],[UIImage imageNamed:@"movie2.png"],[UIImage imageNamed:@"movie3.png"],nil];
    
    animView.animationImages = imagesArray;
    animView.animationDuration = ((CGFloat)[imagesArray count])*100.0f/1000.0f;
    animView.animationRepeatCount = 0;
    [animView startAnimating];
    
    [movieView addSubview:animView];
    [animView release];
    [movieView setHidden:YES];
    [self.view addSubview:movieView];
    self.movieView = movieView;
    [movieView release];
    
    
    [self initCustomView];
    
    
}

#define CUSTOM_VIEW_HEIGHT 338
#define CUSTOM_VIEW_RIGHT_BTN_WIDTH_AND_HEIGHT 38
#define CUSTOM_VIEW_INPUT_VIEW_HEIGHT 100
#define CUSTOM_VIEW_INPUT_VIEW_ITEM_LEFT_LABEL_WIDTH 75
-(void)initCustomView{
    CGRect rect = [AppDelegate getScreenSize:YES isHorizontal:NO];
    CGFloat width = rect.size.width;
    CGFloat height = rect.size.height;
    
    
    //
    UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(0, height, width, CUSTOM_VIEW_HEIGHT)];
    [customView setBackgroundColor:XWhite];
    
    
    //查询按钮
    UIButton *searchBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [searchBtn addTarget:self action:@selector(onCustomSearch:) forControlEvents:UIControlEventTouchUpInside];
    [searchBtn setBackgroundColor:[UIColor grayColor]];
    [searchBtn setBackgroundImage:[UIImage imageNamed:@"bg_normal_cell_p.png"] forState:UIControlStateHighlighted];
    searchBtn.frame = CGRectMake(0, 0, customView.frame.size.width, CUSTOM_VIEW_RIGHT_BTN_WIDTH_AND_HEIGHT);
    //查询文本
    UILabel *searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, searchBtn.frame.size.width, searchBtn.frame.size.height)];
    searchLabel.textAlignment = NSTextAlignmentCenter;
    searchLabel.textColor = XWhite;
    searchLabel.font = XFontBold_16;
    searchLabel.backgroundColor = XBGAlpha;
    searchLabel.text = NSLocalizedString(@"search", nil);
    [searchBtn addSubview:searchLabel];
    [searchLabel release];
    
    //    UIImageView *sep = [[UIImageView alloc] initWithFrame:CGRectMake(searchBtn.frame.size.width, 0, 1, searchBtn.frame.size.height)];
    //    [sep setBackgroundColor:XBlack];
    //    [customView addSubview: sep];
    //    [sep release];
    
    //    UIButton *hideBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    //    [hideBtn setBackgroundImage:[UIImage imageNamed:@"bg_normal_cell_p.png"] forState:UIControlStateHighlighted];
    //    hideBtn.frame = CGRectMake(customView.frame.size.width-CUSTOM_VIEW_RIGHT_BTN_WIDTH_AND_HEIGHT, 0, CUSTOM_VIEW_RIGHT_BTN_WIDTH_AND_HEIGHT, CUSTOM_VIEW_RIGHT_BTN_WIDTH_AND_HEIGHT);
    
    //    [customView addSubview:hideBtn];
    [customView addSubview:searchBtn];
    
    
    //
    UIView *inputView = [[UIView alloc] initWithFrame:CGRectMake(0, CUSTOM_VIEW_RIGHT_BTN_WIDTH_AND_HEIGHT, customView.frame.size.width, CUSTOM_VIEW_INPUT_VIEW_HEIGHT)];
    [inputView setBackgroundColor:XWhite];
    //查询开始时间按钮
    UIButton *startTime = [[UIButton alloc] initWithFrame:CGRectMake(10, 10, inputView.frame.size.width-20, (inputView.frame.size.height-30)/2)];
    startTime.tag = 0;
    startTime.layer.cornerRadius = 2;
    startTime.layer.borderWidth = 1;
    startTime.layer.borderColor = [XWhite CGColor];
    startTime.layer.masksToBounds = YES;
    startTime.backgroundColor = UIColorFromRGB(0xcccccc);
    [startTime.layer setShadowOffset:CGSizeMake(0, 0)];
    [startTime.layer setShadowColor:[XBlue CGColor]];
    [startTime.layer setShadowOpacity:1.0];
    [startTime setClipsToBounds:NO];
    self.startTimeBtn = startTime;
    [startTime addTarget:self action:@selector(changeTimeBtnShadow:) forControlEvents:UIControlEventTouchUpInside];
    //文本
    UILabel *startLeftLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CUSTOM_VIEW_INPUT_VIEW_ITEM_LEFT_LABEL_WIDTH, startTime.frame.size.height)];
    startLeftLabel.textAlignment = NSTextAlignmentRight;
    startLeftLabel.textColor = XBlue;
    startLeftLabel.font = XFontBold_16;
    startLeftLabel.backgroundColor = XBGAlpha;
    startLeftLabel.text = NSLocalizedString(@"start_time", nil);
    [startTime addSubview:startLeftLabel];
    [startLeftLabel release];
    //文本
    UILabel *startRightLabel = [[UILabel alloc] initWithFrame:CGRectMake(CUSTOM_VIEW_INPUT_VIEW_ITEM_LEFT_LABEL_WIDTH, 0, startTime.frame.size.width-CUSTOM_VIEW_INPUT_VIEW_ITEM_LEFT_LABEL_WIDTH, startTime.frame.size.height)];
    startRightLabel.textAlignment = NSTextAlignmentCenter;
    startRightLabel.textColor = XBlue;
    startRightLabel.font = XFontBold_16;
    startRightLabel.backgroundColor = XBGAlpha;
    startRightLabel.text = @"";
    [startTime addSubview:startRightLabel];
    self.startTimeLabel = startRightLabel;
    [startRightLabel release];
    
    [inputView addSubview:startTime];
    
    //查询结束时间按钮
    UIButton *endTime = [[UIButton alloc] initWithFrame:CGRectMake(10, 10+(inputView.frame.size.height-30)/2+10, inputView.frame.size.width-20, (inputView.frame.size.height-30)/2)];
    endTime.tag = 1;
    endTime.layer.cornerRadius = 2;
    endTime.layer.borderWidth = 1;
    endTime.layer.borderColor = [XWhite CGColor];
    endTime.layer.masksToBounds = YES;
    endTime.backgroundColor = UIColorFromRGB(0xcccccc);
    [endTime.layer setShadowOffset:CGSizeMake(1, 1)];
    [endTime.layer setShadowColor:[XBGAlpha CGColor]];
    [endTime.layer setShadowOpacity:1.0];
    [endTime setClipsToBounds:NO];
    self.endTimeBtn = endTime;
    [endTime addTarget:self action:@selector(changeTimeBtnShadow:) forControlEvents:UIControlEventTouchUpInside];
    //文本
    UILabel *endLeftLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CUSTOM_VIEW_INPUT_VIEW_ITEM_LEFT_LABEL_WIDTH, endTime.frame.size.height)];
    endLeftLabel.textAlignment = NSTextAlignmentRight;
    endLeftLabel.textColor = XBlue;
    endLeftLabel.font = XFontBold_16;
    endLeftLabel.backgroundColor = XBGAlpha;
    endLeftLabel.text = NSLocalizedString(@"end_time", nil);
    [endTime addSubview:endLeftLabel];
    [endLeftLabel release];
    //文本
    UILabel *endRightLabel = [[UILabel alloc] initWithFrame:CGRectMake(CUSTOM_VIEW_INPUT_VIEW_ITEM_LEFT_LABEL_WIDTH, 0, endTime.frame.size.width-CUSTOM_VIEW_INPUT_VIEW_ITEM_LEFT_LABEL_WIDTH, endTime.frame.size.height)];
    endRightLabel.textAlignment = NSTextAlignmentCenter;
    endRightLabel.textColor = XBlue;
    endRightLabel.font = XFontBold_16;
    endRightLabel.backgroundColor = XBGAlpha;
    endRightLabel.text = @"";
    [endTime addSubview:endRightLabel];
    self.endTimeLabel = endRightLabel;
    [endRightLabel release];
    
    
    [inputView addSubview:endTime];
    [customView addSubview: inputView];
    [inputView release];
    
    [self.view addSubview:customView];
    self.customView = customView;
    [customView release];
    
    
    
    //时间选择器
//    UIDatePicker *datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, CUSTOM_VIEW_RIGHT_BTN_WIDTH_AND_HEIGHT+CUSTOM_VIEW_INPUT_VIEW_HEIGHT, customView.frame.size.width, CUSTOM_VIEW_HEIGHT-CUSTOM_VIEW_RIGHT_BTN_WIDTH_AND_HEIGHT-CUSTOM_VIEW_INPUT_VIEW_HEIGHT)];
//    
//    [datePicker setDatePickerMode:UIDatePickerModeDateAndTime];
//    [datePicker setDate:[NSDate date] animated:NO];
//    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
//    if ([language isEqualToString:@"zh-Hans"]) {
//        NSLocale* locale=[[NSLocale alloc]initWithLocaleIdentifier:@"zh-Hans"];
//        [datePicker setLocale:locale];
//    }else if ([language isEqualToString:@"en"]){
//        NSLocale* locale=[[NSLocale alloc]initWithLocaleIdentifier:@"en"];
//        [datePicker setLocale:locale];
//    }
//    [datePicker setMinimumDate:[Utils dateFromString:[NSString stringWithFormat:@"2013-07-01 00:00"]]];
//    [datePicker setMaximumDate:[Utils dateFromString:[NSString stringWithFormat:@"2035-12-31 23:59"]]];
//    [datePicker addTarget:self action:@selector(onDatePickChange:) forControlEvents:UIControlEventValueChanged];
//    
//    [customView addSubview:datePicker];
//    [datePicker release];
    
    CGFloat dwItemHeight = 30;
    CyclePickerView* cycleview = [[CyclePickerView alloc] initWithFrame:CGRectMake(0,50+CUSTOM_VIEW_INPUT_VIEW_HEIGHT+dwItemHeight, width, dwItemHeight*5)];
    cycleview.delegate = self;
    cycleview.datasource = self;
    [cycleview reloadScroll];
    [self.customView addSubview:cycleview];
    self.cycleview = cycleview;
    [cycleview release];
    
    NSDateComponents *dateComponents = [Utils getNowDateComponents];
    int year = (int)[dateComponents year];
    int month = (int)[dateComponents month];
    int day = (int)[dateComponents day];
    int hour = (int)[dateComponents hour];
    int minute = (int)[dateComponents minute];
    [self.cycleview selectCell:year-2010 inScroll:0];
    [self.cycleview selectCell:month-1 inScroll:1];
    [self.cycleview selectCell:day-1 inScroll:2];
    [self.cycleview selectCell:hour inScroll:3];
    [self.cycleview selectCell:minute inScroll:4];
    
    //年月日时分文本
    UIView* headlabelview = [[UIView alloc] initWithFrame:CGRectMake(0,50+CUSTOM_VIEW_INPUT_VIEW_HEIGHT, width, dwItemHeight)];
    NSArray * arr = @[NSLocalizedString(@"year", nil),NSLocalizedString(@"month", nil),NSLocalizedString(@"day", nil),NSLocalizedString(@"hour", nil),NSLocalizedString(@"minute", nil)];
    CGFloat noworigin = 0.0;
    for (NSInteger i = 0; i<5; i++)
    {
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(noworigin*headlabelview.frame.size.width, 0, [self.cycleview.scrollWidthProportion[i] floatValue]*headlabelview.frame.size.width, headlabelview.frame.size.height)];
        label.text = arr[i];
        label.textAlignment = NSTextAlignmentCenter;
        [headlabelview addSubview:label];
        [label release];
        noworigin+=[self.cycleview.scrollWidthProportion[i] floatValue];
    }
    [self.customView addSubview:headlabelview];
    [headlabelview release];
}

#pragma mark - CyclePickerViewDelegate
- (void)CyclePickerViewDidChangeValue:(NSArray *) valuearr{
    
    NSString *time = [Utils getDeviceTimeByIntValue:[valuearr[0] integerValue]
                                              month:[valuearr[1] integerValue]
                                                day:[valuearr[2] integerValue]
                                               hour:[valuearr[3] integerValue]
                                             minute:[valuearr[4] integerValue]];
    
    switch(self.selectedTimeTag){
        case 0:
        {
            self.startTimeLabel.text = time;
        }
            break;
        case 1:
        {
            self.endTimeLabel.text = time;
        }
            break;
    }
    
}

//指定每一列的滚轮上的Cell的个数
- (NSUInteger)numberOfCellsInScroll:(NSUInteger)scroll{
    switch (scroll) {
        case 0:
            return 27;
            break;
        case 1:
            return 12;
            break;
        case 2:
            return 31;
            break;
        case 3:
            return 24;
            break;
        case 4:
            return 60;
            break;
        default:
            return 10;
            break;
    }
    return 0;
}

//指定每一列滚轮所占整体宽度的比例，以:分隔
- (NSString *)scrollWidthProportion{
    return @"1:1:1:1:1";
}
//指定每一列的滚轮上的Cell的初始值，以:分隔
- (NSString *)valueOfCellsInScroll{
    return @"2010:1:1:0:0";
}

-(void)onCustomSearch:(UIButton*)button{
    NSString *startTime = self.startTimeLabel.text;
    NSString *endTime = self.endTimeLabel.text;
    
    self.startTime = startTime;
    self.endTime = endTime;
    
    if(!startTime||!startTime.length>0){
        
        [self.view makeToast:NSLocalizedString(@"unselected_start_time", nil)];
        return;
    }
    
    if(!endTime||!endTime.length>0){
        [self.view makeToast:NSLocalizedString(@"unselected_end_time", nil)];
        return;
    }
    
    NSDate *startDate = [Utils dateFromString:startTime];
    NSDate *endDate = [Utils dateFromString:endTime];
    if([startDate timeIntervalSince1970]>=[endDate timeIntervalSince1970]){
        [self.view makeToast:NSLocalizedString(@"start_time_must_before_end_time", nil)];
        return;
    }
    
    
    [self.searchMaskView setHidden:NO];
    self.searchMaskView.alpha = 0.3;
    
    [UIView transitionWithView:self.searchMaskView duration:0.3 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.searchMaskView.alpha = 1.0;
    }
     
                    completion:^(BOOL finished){
                        
                    }
     ];
    
    if(self.isShowCustomView){
        self.isShowCustomView = !self.isShowCustomView;
        [UIView transitionWithView:self.customView duration:0.2 options:UIViewAnimationOptionCurveEaseOut
                        animations:^{
                            self.customView.transform = CGAffineTransformMakeTranslation(0,0);
                        }
         
                        completion:^(BOOL isFinish){
                            
                        }
         ];
    }
    
    [[P2PClient sharedClient] getPlaybackFilesWithIdByDate:self.contact.contactId password:self.contact.contactPassword startDate:startDate endDate:endDate];
}

-(void)changeTimeBtnShadow:(UIButton*)button{
    self.selectedTimeTag = button.tag;
    switch(button.tag){
        case 0:
        {
            [self.startTimeBtn.layer setShadowColor:[XBlue CGColor]];
            [self.endTimeBtn.layer setShadowColor:[XBGAlpha CGColor]];
            
        }
            break;
        case 1:
        {
            [self.startTimeBtn.layer setShadowColor:[XBGAlpha CGColor]];
            [self.endTimeBtn.layer setShadowColor:[XBlue CGColor]];
        }
            break;
    }
}

-(void)onDatePickChange:(UIDatePicker*)datePick{
    NSString *dateString = [Utils stringFromDate:[datePick date]];
    switch(self.selectedTimeTag){
        case 0:
        {
            self.startTimeLabel.text = dateString;
        }
            break;
        case 1:
        {
            self.endTimeLabel.text = dateString;
        }
            break;
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.playbackFiles count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return PLAYBACK_LIST_ITEM_HEIGHT;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"PlaybackCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if(cell==nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    UIImage *backImg = [UIImage imageNamed:@"bg_normal_cell.png"];
    UIImage *backImg_p = [UIImage imageNamed:@"bg_normal_cell_p.png"];
    UIImageView *backImageView = [[UIImageView alloc] init];
    UIImageView *backImageView_p = [[UIImageView alloc] init];
    
    backImg = [backImg stretchableImageWithLeftCapWidth:backImg.size.width*0.5 topCapHeight:backImg.size.height*0.5];
    backImageView.image = backImg;
    [cell setBackgroundView:backImageView];
    
    backImg_p = [backImg_p stretchableImageWithLeftCapWidth:backImg_p.size.width*0.5 topCapHeight:backImg_p.size.height*0.5];
    backImageView_p.image = backImg_p;
    [cell setSelectedBackgroundView:backImageView_p];
    
    [backImageView release];
    [backImageView_p release];
    
    
    NSString* name = [self.playbackFiles objectAtIndex:indexPath.row];
    
    int iSize = 0;
    if ([self.playbackFiles count] == [self.playbackSize count])    //查询到了文件长度
    {
        NSNumber* number = [self.playbackSize objectAtIndex:indexPath.row];
        iSize = [number intValue];
    }
    if (iSize != 0) {//支持返回播放时长
        cell.textLabel.text = [NSString stringWithFormat:@"%@  (%02d:%02d)", name, iSize/60, iSize%60];
    }
    else
    {
        cell.textLabel.text = [NSString stringWithFormat:@"%@", name];
    }
    cell.textLabel.font = CURRENT_VERSION >= 9.0 ? XFontBold_14 : XFontBold_16;
    
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self.movieView setHidden:NO];
    self.movieView.alpha = 0.3;
    
    [UIView transitionWithView:self.movieView duration:0.3 options:UIViewAnimationOptionCurveEaseOut
                    animations:^{
                        self.movieView.alpha = 1.0;
                    }
     
                    completion:^(BOOL finished){
                        
                    }
     ];
    [[P2PClient sharedClient] p2pPlaybackCallWithId:self.contact.contactId password:self.contact.contactPassword index:indexPath.row];
}

-(void)updateLabelColor:(NSInteger)index{
    for(UIView *view in self.searchBarView.subviews){
        if([view isKindOfClass:[UIButton class]]){
            UILabel *label = [view.subviews objectAtIndex:0];
            
            if(view.tag==index){
                label.textColor = XBlack;
            }else{
                label.textColor = UIColorFromRGB(0x808080);
            }
        }
        
    }
}

-(void)onButtonPress:(id)sender{
    UIButton *button = (UIButton*)sender;
    BOOL isCustom = NO;
    self.isChangePlaybackItem = YES;//视频回放修复
    [[P2PClient sharedClient] setIsClearPlaybackFilesLength:YES];//视频回放修复
    switch(button.tag){
        case 0:
        {
            self.selectedLabel = 1;
            [[P2PClient sharedClient] setCurrentLabel:1];
            [[P2PClient sharedClient] getPlaybackFilesWithId:self.contact.contactId password:self.contact.contactPassword timeInterval:1];
            [self updateLabelColor:0];
            
        }
            break;
        case 1:
        {
            self.selectedLabel = 2;
            [[P2PClient sharedClient] setCurrentLabel:2];
            [[P2PClient sharedClient] getPlaybackFilesWithId:self.contact.contactId password:self.contact.contactPassword timeInterval:3];
            [self updateLabelColor:1];
        }
            break;
        case 2:
        {
            self.selectedLabel = 3;
            [[P2PClient sharedClient] setCurrentLabel:3];
            [[P2PClient sharedClient] getPlaybackFilesWithId:self.contact.contactId password:self.contact.contactPassword timeInterval:31];
            [self updateLabelColor:2];
        }
            break;
        case 3:
        {
            self.selectedLabel = 4;
            [[P2PClient sharedClient] setCurrentLabel:4];
            isCustom = YES;
            [self updateLabelColor:3];
            
            
        }
            break;
    }
    
    
    [UIView transitionWithView:self.layerView duration:0.2 options:UIViewAnimationOptionCurveEaseOut
                    animations:^{
                        self.layerView.frame = CGRectMake(button.tag*button.frame.size.width, self.layerView.frame.origin.y, self.layerView.frame.size.width, self.layerView.frame.size.height);
                    }
     
                    completion:^(BOOL finished){
                        
                    }
     ];
    
    if(!isCustom){
        [self.searchMaskView setHidden:NO];
        self.searchMaskView.alpha = 0.3;
        
        [UIView transitionWithView:self.searchMaskView duration:0.3 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.searchMaskView.alpha = 1.0;
        }
         
                        completion:^(BOOL finished){
                            
                        }
         ];
        
        if(self.isShowCustomView){
            self.isShowCustomView = !self.isShowCustomView;
            [UIView transitionWithView:self.customView duration:0.2 options:UIViewAnimationOptionCurveEaseOut
                            animations:^{
                                self.customView.transform = CGAffineTransformMakeTranslation(0,0);
                            }
             
                            completion:^(BOOL isFinish){
                                
                            }
             ];
        }
    }else{
        if(!self.isShowCustomView){
            self.isShowCustomView = !self.isShowCustomView;
            [UIView transitionWithView:self.customView duration:0.2 options:UIViewAnimationOptionCurveEaseOut
                            animations:^{
                                self.customView.transform = CGAffineTransformMakeTranslation(0, -self.customView.frame.size.height);
                            }
             
                            completion:^(BOOL isFinish){
                                
                            }
             ];
        }
    }
    
}


-(void)onBackPress{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - 视频回放准备播放的回调
-(void)P2PPlaybackReady:(NSDictionary *)info{
    DLog(@"P2PPlaybackReady");
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView transitionWithView:self.movieView duration:0.3 options:UIViewAnimationOptionCurveEaseOut
                        animations:^{
                            self.movieView.alpha = 0.3;
                        }
         
                        completion:^(BOOL finished){
                            [self.movieView setHidden:YES];
                            P2PPlayingbackController *playingbackController = [[P2PPlayingbackController alloc] init];
                            [self presentViewController:playingbackController animated:YES completion:nil];
                            [playingbackController release];
                        }
         ];
    });
}

#pragma mark - 视频回放挂断的回调
-(void)P2PPlaybackReject:(NSDictionary *)info{
    DLog(@"P2PPlaybackReject");
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView transitionWithView:self.movieView duration:0.3 options:UIViewAnimationOptionCurveEaseOut
                        animations:^{
                            self.movieView.alpha = 0.3;
                        }
         
                        completion:^(BOOL finished){
                            [self.movieView setHidden:YES];
                            [self.view makeToast:[info objectForKey:@"rejectMsg"]];
                        }
         ];
    });
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
@end
