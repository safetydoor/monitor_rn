//
//  ContactCell.m
//  Gviews
//
//  Created by guojunyi on 14-4-12.
//  Copyright (c) 2014年 guojunyi. All rights reserved.
//

#import "ContactCell.h"
#import "Utils.h"
#import "Constants.h"
#import "Contact.h"
#import "P2PClient.h"
#import "FListManager.h"
#import "UDPManager.h"
#import "LocalDevice.h"

#define kOperatorBtnTag_Chat 23581
#define kOperatorBtnTag_Playback 23585
#define kOperatorBtnTag_Control 23586
#define kOperatorBtnTag_Modify 23583
#define kOperatorBtnTag_WeakPwd 23587
#define kOperatorBtnTag_UpdateDevice 23588
#define kOperatorBtnTag_initDevicePwd 23589

@implementation ContactCell

-(void)dealloc{
    
    [self.contact release];
    
    [self.topView release];
    [self.headView release];
    [self.typeView release];
    [self.nameLabel release];
    [self.updateDeviceBtn release];
    [self.stateLabel release];
    [self.weakPwdButton release];
    
    [self.initDeviceButton release];
    
    [self.bottomView release];
    [self.defenceStateView release];
    [self.chatButton release];
    [self.playbackButton release];
    [self.controlButton release];
    [self.modifyButton release];
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

#define CONTACT_TYPE_ICON_WIDTH_AND_HEIGHT 16
-(void)layoutSubviews{
    [super layoutSubviews];
    
    CGFloat width = self.contentView.frame.size.width;
    CGFloat height = self.contentView.frame.size.height;
    //bottomView的高
    CGFloat bottomView_h = 70.0/SCREEN_SCALE;
    //topView高
    CGFloat topView_h = height-bottomView_h;
    
    
    //cell的上部分
    if (!self.topView) {
        UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, width, topView_h)];
        [self.contentView addSubview:topView];
        self.topView = topView;
        [topView release];
    }else{
        self.topView.frame = CGRectMake(0.0, 0.0, width, topView_h);
    }
    
    //上部分的图片view（头像）
    if(!self.headView){
        UIButton *headButton = [UIButton buttonWithType:UIButtonTypeCustom];
        headButton.frame = CGRectMake(0.0, 0.0, width, self.topView.frame.size.height);
        [self.topView addSubview:headButton];
        self.headView = headButton;
        //图片
        UIImageView *headImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.headView.frame.size.width ,self.headView.frame.size.height)];
        
        NSString *filePath = [Utils getHeaderFilePathWithId:self.contact.contactId];
        UIImage *headImg = [UIImage imageWithContentsOfFile:filePath];
        
        //默认头像图片上的阴影图片
        UIImage *headShadowImg = [UIImage imageNamed:@"contactCell_header_shadow_img.png"];
        CGFloat headShadowImgView_w = self.headView.frame.size.width;
        CGFloat headShadowImgView_h = headShadowImgView_w*(headShadowImg.size.height/headShadowImg.size.width);
        UIImageView *headShadowImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, headShadowImgView_w, headShadowImgView_h)];
        headShadowImgView.image = headShadowImg;
        [headImageView addSubview:headShadowImgView];
        if(headImg==nil){
            [headShadowImgView setHidden:NO];
        }else{
            [headShadowImgView setHidden:YES];
        }
        [headShadowImgView release];
        
        if(headImg==nil){//默认头像图片
            headImg = [UIImage imageNamed:@"ic_header.png"];
        }
        headImageView.image = headImg;
        [self.headView addSubview:headImageView];
        [headImageView release];
    }else{
        
        self.headView.frame = CGRectMake(0.0, 0.0, width, self.topView.frame.size.height);
        //头像图片
        UIImageView *headImageView = [[self.headView subviews] objectAtIndex:0];
        headImageView.frame = CGRectMake(0.0, 0.0, self.headView.frame.size.width ,self.headView.frame.size.height);
        
        NSString *filePath = [Utils getHeaderFilePathWithId:self.contact.contactId];
        UIImage *headImg = [UIImage imageWithContentsOfFile:filePath];
        
        //默认头像图片上的阴影图片
        UIImageView *headShadowImgView = [[headImageView subviews] objectAtIndex:0];
        
        if(headImg==nil){
            headImg = [UIImage imageNamed:@"ic_header.png"];
            [headShadowImgView setHidden:NO];
        }else{
            [headShadowImgView setHidden:YES];
        }
        
        headImageView.image = headImg;
    }
    [self.headView addTarget:self action:@selector(onHeadClick:) forControlEvents:UIControlEventTouchUpInside];
    
    //设备昵称
    CGFloat nameLabel_w = [Utils getStringWidthWithString:self.contact.contactName font:[UIFont systemFontOfSize:FondSizeWithPxValue(20)] maxWidth:width];
    CGFloat nameLabel_w2 = [Utils getStringWidthWithString:NSLocalizedString(@"offline", nil) font:[UIFont systemFontOfSize:FondSizeWithPxValue(20)] maxWidth:width];
    //label的背景图片
    UIImage *nameImage = [UIImage imageNamed:@"contactCell_state_bg_img.png"];
    CGFloat nameImgView_w = nameLabel_w+4.0;
    CGFloat nameImgView_h = (nameLabel_w2+20.0)*(nameImage.size.height/nameImage.size.width);
    CGFloat nameImgView_x = 20.0/SCREEN_SCALE;
    CGFloat nameImgView_y = 21.0/SCREEN_SCALE;
    if(!self.nameLabel){
        //label的背景图片
        UIImageView *nameImgView = [[UIImageView alloc] initWithFrame:CGRectMake(nameImgView_x, nameImgView_y, nameImgView_w, nameImgView_h)];
        nameImgView.image = nameImage;
        //昵称
        UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0 , 0.0, nameImgView_w, nameImgView_h)];
        textLabel.backgroundColor = XBGAlpha;
        textLabel.text = self.contact.contactName;
        textLabel.textAlignment = NSTextAlignmentCenter;
        textLabel.textColor = XWhite;
        [textLabel setFont:[UIFont systemFontOfSize:FondSizeWithPxValue(20)]];
        
        [nameImgView addSubview:textLabel];
        self.nameLabel = textLabel;
        [textLabel release];
        [self.topView addSubview:nameImgView];
        [nameImgView release];
        
    }else{
        UIImageView *nameImgView = (UIImageView *)self.nameLabel.superview;
        nameImgView.frame = CGRectMake(nameImgView_x, nameImgView_y, nameImgView_w, nameImgView_h);
        
        self.nameLabel.frame = CGRectMake(0.0 , 0.0, nameImgView_w, nameImgView_h);
        self.nameLabel.text = self.contact.contactName;
    }
    
    //设备检查更新按钮图标
    CGFloat updateDeviceBtn_wh = 40.0;
    CGFloat updateDeviceBtn_x = self.topView.frame.size.width-updateDeviceBtn_wh;
    if(!self.updateDeviceBtn){
        UIButton *updateDeviceBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        updateDeviceBtn.frame = CGRectMake(updateDeviceBtn_x, 0.0, updateDeviceBtn_wh, updateDeviceBtn_wh);
        updateDeviceBtn.backgroundColor = XBGAlpha;
        updateDeviceBtn.tag = kOperatorBtnTag_UpdateDevice;
        [updateDeviceBtn addTarget:self action:@selector(onOperatorItemPress:) forControlEvents:UIControlEventTouchUpInside];
        [self.topView addSubview:updateDeviceBtn];
        self.updateDeviceBtn = updateDeviceBtn;
        
        UIImageView *updateDeviceImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0 ,updateDeviceBtn_wh,updateDeviceBtn_wh)];
        updateDeviceImageView.backgroundColor = XBGAlpha;
        updateDeviceImageView.image = [UIImage imageNamed:@"ic_contact_update_device.png"];
        [self.updateDeviceBtn addSubview:updateDeviceImageView];
        [updateDeviceImageView release];
    }
    //isNewVersionDevice为YES表示设备可升级到新版本
    if(self.contact.isNewVersionDevice && (self.contact.defenceState == DEFENCE_STATE_ON || self.contact.defenceState == DEFENCE_STATE_OFF)){
        [self.updateDeviceBtn setHidden:NO];
        CGRect rect1 = self.defenceStateView.frame;
        rect1.origin.y += 20.0;
        self.defenceStateView.frame = rect1;
        CGRect rect2 = self.defenceProgressView.frame;
        rect2.origin.y += 20.0;
        self.defenceProgressView.frame = rect2;
    }else{
        [self.updateDeviceBtn setHidden:YES];
    }
    
    //在线、离线文本
    CGFloat stateLabel_w = [Utils getStringWidthWithString:NSLocalizedString(@"offline", nil) font:[UIFont systemFontOfSize:FondSizeWithPxValue(20)] maxWidth:width];
    //label的背景图片
    UIImage *stateImage = [UIImage imageNamed:@"contactCell_state_bg_img.png"];
    CGFloat stateImgView_w = stateLabel_w+20.0;
    CGFloat stateImgView_h = stateImgView_w*(stateImage.size.height/stateImage.size.width);
    CGFloat stateImgView_x = 20.0/SCREEN_SCALE;
    CGFloat stateImgView_y = self.topView.frame.size.height-18.0/SCREEN_SCALE-stateImgView_h;
    if(!self.stateLabel){
        //label的背景图片
        UIImageView *stateImgView = [[UIImageView alloc] initWithFrame:CGRectMake(stateImgView_x, stateImgView_y, stateImgView_w, stateImgView_h)];
        stateImgView.image = stateImage;
        //在线、离线文本
        UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0,0.0,stateImgView_w,stateImgView_h)];
        textLabel.backgroundColor = XBGAlpha;
        textLabel.textAlignment = NSTextAlignmentCenter;
        [textLabel setFont:[UIFont systemFontOfSize:FondSizeWithPxValue(20)]];
        textLabel.textColor = XWhite;
        if (self.contact.isGettingOnLineState) {//isGettingOnLineState
            [stateImgView setHidden:YES];
            
        }else{
            [stateImgView setHidden:NO];
            if(self.contact.onLineState==STATE_ONLINE){
                textLabel.text = NSLocalizedString(@"online", nil);
            }else{
                textLabel.text = NSLocalizedString(@"offline", nil);
            }
        }
        
        [stateImgView addSubview:textLabel];
        self.stateLabel = textLabel;
        [textLabel release];
        [self.topView addSubview:stateImgView];
        [stateImgView release];
    }else{
        UIImageView *stateImgView = (UIImageView *)self.stateLabel.superview;
        stateImgView.frame = CGRectMake(stateImgView_x, stateImgView_y, stateImgView_w, stateImgView_h);
        
        self.stateLabel.frame = CGRectMake(0.0,0.0,stateImgView_w,stateImgView_h);
        if (self.contact.isGettingOnLineState) {//isGettingOnLineState
            [stateImgView setHidden:YES];

        }else{
            [stateImgView setHidden:NO];
            if(self.contact.onLineState==STATE_ONLINE){
                self.stateLabel.text = NSLocalizedString(@"online", nil);
            }else{
                self.stateLabel.text = NSLocalizedString(@"offline", nil);
            }
        }
    }
    
    //设备类型IPC、NPC...
    CGFloat space_header_type = 10.0;
    if(!self.typeView){
        UIImageView *typeView = [[UIImageView alloc] initWithFrame:CGRectMake(self.headView.frame.origin.x+self.headView.frame.size.width+space_header_type, self.topView.frame.size.height/2+6.0, CONTACT_TYPE_ICON_WIDTH_AND_HEIGHT, CONTACT_TYPE_ICON_WIDTH_AND_HEIGHT)];
        if(self.contact.contactType==CONTACT_TYPE_NPC){
            UIImage *typeImg = [UIImage imageNamed:@"ic_contact_type_npc.png"];
            typeView.image = typeImg;
        }else if(self.contact.contactType==CONTACT_TYPE_IPC){
            UIImage *typeImg = [UIImage imageNamed:@"ic_contact_type_ipc.png"];
            typeView.image = typeImg;
        }else if(self.contact.contactType==CONTACT_TYPE_PHONE){
            UIImage *typeImg = [UIImage imageNamed:@"ic_contact_type_phone.png"];
            typeView.image = typeImg;
        }else if(self.contact.contactType==CONTACT_TYPE_DOORBELL){
            UIImage *typeImg = [UIImage imageNamed:@"ic_contact_type_doorbell.png"];
            typeView.image = typeImg;
        }else if(self.contact.contactType==CONTACT_TYPE_UNKNOWN){
            UIImage *typeImg = [UIImage imageNamed:@"ic_contact_type_unknown.png"];
            typeView.image = typeImg;
        }
        
        //[self.topView addSubview:typeView];
        self.typeView = typeView;
        
    }else{
        self.typeView.frame = CGRectMake(self.headView.frame.origin.x+self.headView.frame.size.width+space_header_type, self.topView.frame.size.height/2+6.0, CONTACT_TYPE_ICON_WIDTH_AND_HEIGHT, CONTACT_TYPE_ICON_WIDTH_AND_HEIGHT);
        
        if(self.contact.contactType==CONTACT_TYPE_NPC){
            UIImage *typeImg = [UIImage imageNamed:@"ic_contact_type_npc.png"];
            self.typeView.image = typeImg;
        }else if(self.contact.contactType==CONTACT_TYPE_IPC){
            UIImage *typeImg = [UIImage imageNamed:@"ic_contact_type_ipc.png"];
            self.typeView.image = typeImg;
        }else if(self.contact.contactType==CONTACT_TYPE_PHONE){
            UIImage *typeImg = [UIImage imageNamed:@"ic_contact_type_phone.png"];
            self.typeView.image = typeImg;
        }else if(self.contact.contactType==CONTACT_TYPE_DOORBELL){
            UIImage *typeImg = [UIImage imageNamed:@"ic_contact_type_doorbell.png"];
            self.typeView.image = typeImg;
        }else if(self.contact.contactType==CONTACT_TYPE_UNKNOWN){
            UIImage *typeImg = [UIImage imageNamed:@"ic_contact_type_unknown.png"];
            self.typeView.image = typeImg;
        }
        
    }
    
    
    //设备列表的设备已经被初始化，点击按钮跳转到初始化密码界面
    //按钮的宽、高
    CGFloat initDeviceButton_w = width;
    CGFloat initDeviceButton_h = height;
    if(!self.initDeviceButton){
        UIButton *initDeviceButton = [UIButton buttonWithType:UIButtonTypeCustom];
        initDeviceButton.frame = CGRectMake(0.0 ,0.0 ,initDeviceButton_w,initDeviceButton_h);
        initDeviceButton.tag = kOperatorBtnTag_initDevicePwd;
        [initDeviceButton addTarget:self action:@selector(onOperatorItemPress:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:initDeviceButton];
        self.initDeviceButton = initDeviceButton;
    }else{
        self.initDeviceButton.frame = CGRectMake(0.0 ,0.0 ,initDeviceButton_w,initDeviceButton_h);
    }
    BOOL isInitedDevice = NO;//YES表示密码为空，点击cell时跳转到设置密码界面
    NSArray* deviceList = [[UDPManager sharedDefault] getLanDevices];
    for (LocalDevice *localDevice in deviceList) {
        if ([localDevice.contactId isEqualToString:self.contact.contactId]&&localDevice.flag==0) {
            isInitedDevice = YES;
            break;
        }
    }
    if(isInitedDevice){
        [self.initDeviceButton setHidden:NO];
        
    }else{
        [self.initDeviceButton setHidden:YES];
    }
    
    
    
    //cell的下部分
    if (!self.bottomView) {
        UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0.0, self.topView.frame.origin.y+self.topView.frame.size.height, width, bottomView_h)];
        [self.contentView addSubview:bottomView];
        self.bottomView = bottomView;
        [bottomView release];
    }else{
        self.bottomView.frame = CGRectMake(0.0, self.topView.frame.origin.y+self.topView.frame.size.height, width, bottomView_h);
    }
    
    //布防、撤防
    CGFloat defenceStateView_x = 29.0/SCREEN_SCALE;
    CGFloat defenceStateView_wh = self.bottomView.frame.size.height;
    if(!self.defenceStateView){
        UIButton *defenceStateView = [UIButton buttonWithType:UIButtonTypeCustom];
        defenceStateView.frame = CGRectMake(defenceStateView_x, 0.0, defenceStateView_wh, defenceStateView_wh);
        [self.bottomView addSubview:defenceStateView];
        self.defenceStateView = defenceStateView;
        
        UIImage *defenceImage = [UIImage imageNamed:@"ic_defence_on.png"];
        switch(self.contact.defenceState){
            case DEFENCE_STATE_ON:
            {
                defenceImage = [UIImage imageNamed:@"ic_defence_on.png"];
            }
                break;
                
            case DEFENCE_STATE_OFF:
            {
                defenceImage = [UIImage imageNamed:@"ic_defence_off.png"];
            }
                break;
                
            case DEFENCE_STATE_LOADING:
            {
                
            }
                break;
                
            case DEFENCE_STATE_WARNING_NET:
            {
                defenceImage = [UIImage imageNamed:@"ic_defence_warning.png"];
            }
                break;
                
            case DEFENCE_STATE_WARNING_PWD:
            {
                defenceImage = [UIImage imageNamed:@"ic_device_pwd_error_warning.png"];
            }
                break;
            case DEFENCE_STATE_NO_PERMISSION:
            {
                defenceImage = [UIImage imageNamed:@"ic_defence_limit.png"];
            }
                break;
        }
        CGFloat imageView_h = 20.0;
        CGFloat imageView_w = imageView_h*(defenceImage.size.width/defenceImage.size.height);
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, (defenceStateView_wh-imageView_h)/2, imageView_w, imageView_h)];
        imageView.image = defenceImage;
        [self.defenceStateView addSubview:imageView];
        [imageView release];
        
        
    }else{
        self.defenceStateView.frame = CGRectMake(defenceStateView_x, 0.0, defenceStateView_wh, defenceStateView_wh);
        
        UIImage *defenceImage = [UIImage imageNamed:@"ic_defence_on.png"];
        switch(self.contact.defenceState){
            case DEFENCE_STATE_ON:
            {
                defenceImage = [UIImage imageNamed:@"ic_defence_on.png"];
            }
                break;
                
            case DEFENCE_STATE_OFF:
            {
                defenceImage = [UIImage imageNamed:@"ic_defence_off.png"];
            }
                break;
                
            case DEFENCE_STATE_LOADING:
            {
                
            }
                break;
                
            case DEFENCE_STATE_WARNING_NET:
            {
                defenceImage = [UIImage imageNamed:@"ic_defence_warning.png"];
            }
                break;
                
            case DEFENCE_STATE_WARNING_PWD:
            {
                defenceImage = [UIImage imageNamed:@"ic_device_pwd_error_warning.png"];
            }
                break;
            case DEFENCE_STATE_NO_PERMISSION:
            {
                defenceImage = [UIImage imageNamed:@"ic_defence_limit.png"];
            }
                break;
        }
        CGFloat imageView_h = 20.0;
        CGFloat imageView_w = imageView_h*(defenceImage.size.width/defenceImage.size.height);
        UIImageView *imageView = [[self.defenceStateView subviews] objectAtIndex:0];
        imageView.frame = CGRectMake(0.0, (defenceStateView_wh-imageView_h)/2, imageView_w, imageView_h);
        imageView.image = defenceImage;
    }
    //指示器
    UIImageView *defenceImageView = self.defenceStateView.subviews[0];
    CGRect defenceProgressViewRect = [self.defenceStateView convertRect:defenceImageView.frame toView:self.bottomView];
    if(!self.defenceProgressView){
        YProgressView *progressView = [[YProgressView alloc] initWithFrame:CGRectMake(defenceProgressViewRect.origin.x, defenceProgressViewRect.origin.y, 20.0, 20.0)];
        progressView.center = CGPointMake(defenceProgressViewRect.origin.x+defenceProgressViewRect.size.width/2, defenceProgressViewRect.origin.y+defenceProgressViewRect.size.height/2);
        progressView.backgroundView.image = [UIImage imageNamed:@"ic_progress_arrow.png"];
        
        self.defenceProgressView = progressView;
        [progressView release];
        [self.bottomView addSubview:self.defenceProgressView];
        
    }else{
        self.defenceProgressView.frame = CGRectMake(defenceProgressViewRect.origin.x, defenceProgressViewRect.origin.y, 20.0, 20.0);
        self.defenceProgressView.center = CGPointMake(defenceProgressViewRect.origin.x+defenceProgressViewRect.size.width/2, defenceProgressViewRect.origin.y+defenceProgressViewRect.size.height/2);
    }
    //NVR没有布防撤防
    
    [self updateDefenceStateView];
    [self.defenceStateView addTarget:self action:@selector(onDefencePress:) forControlEvents:UIControlEventTouchUpInside];
    
    //弱密码提示
    //弱密码按钮的宽、高
    CGFloat weakPwdButton_wh = self.bottomView.frame.size.height;
    //按钮图片的宽、高
    UIImage *weakPwdImage = [UIImage imageNamed:@"ic_contact_weak_pwd.png"];
    CGFloat weakPwdImageView_h = 20.0;
    CGFloat weakPwdImageView_w = weakPwdImageView_h*(weakPwdImage.size.width/weakPwdImage.size.height);
    if(!self.weakPwdButton){
        UIButton *weakPwdButton = [UIButton buttonWithType:UIButtonTypeCustom];
        weakPwdButton.frame = CGRectMake(CGRectGetMaxX(self.defenceStateView.frame)+10.0 ,0.0 ,weakPwdButton_wh,weakPwdButton_wh);
        weakPwdButton.tag = kOperatorBtnTag_WeakPwd;
        [weakPwdButton addTarget:self action:@selector(onOperatorItemPress:) forControlEvents:UIControlEventTouchUpInside];
        [self.bottomView addSubview:weakPwdButton];
        self.weakPwdButton = weakPwdButton;
        
        UIImageView *weakPwdImageView = [[UIImageView alloc] initWithFrame:CGRectMake(weakPwdButton_wh-weakPwdImageView_w, (weakPwdButton_wh-weakPwdImageView_h)/2 ,weakPwdImageView_w,weakPwdImageView_h)];
        weakPwdImageView.image = weakPwdImage;
        [self.weakPwdButton addSubview:weakPwdImageView];
        [weakPwdImageView release];
    }
    //NVR没有布防撤防
    
    [self showOrHiddenWeakPwdButton];
    
    
    //通话
    CGFloat chatButton_wh = self.bottomView.frame.size.height;
    //按钮图片的宽、高
    UIImage *chatButtonImage = [UIImage imageNamed:@"ic_operator_item_chat.png"];
    CGFloat chatImageView_h = 20.0;
    CGFloat chatImageView_w = chatImageView_h*(chatButtonImage.size.width/chatButtonImage.size.height);
    if (!self.chatButton) {
        UIButton *chatButton = [UIButton buttonWithType:UIButtonTypeCustom];
        chatButton.frame = CGRectMake(CGRectGetMaxX(self.weakPwdButton.frame)+10.0 ,0.0 ,chatButton_wh,chatButton_wh);
        chatButton.tag = kOperatorBtnTag_Chat;
        [chatButton addTarget:self action:@selector(onOperatorItemPress:) forControlEvents:UIControlEventTouchUpInside];
        [self.bottomView addSubview:chatButton];
        self.chatButton = chatButton;
        
        UIImageView *chatImageView = [[UIImageView alloc] initWithFrame:CGRectMake(chatButton_wh-chatImageView_w, (chatButton_wh-chatImageView_h)/2 ,chatImageView_w,chatImageView_h)];
        chatImageView.image = chatButtonImage;
        [self.chatButton addSubview:chatImageView];
        [chatImageView release];
    }
    //只有NPC才有通话功能
    
    
    //回放
    CGFloat playbackButton_wh = self.bottomView.frame.size.height;
    //按钮图片的宽、高
    UIImage *playbackImage = [UIImage imageNamed:@"ic_operator_item_playback.png"];
    CGFloat playbackImageView_h = 20.0;
    CGFloat playbackImageView_w = playbackImageView_h*(playbackImage.size.width/playbackImage.size.height);
    if (!self.playbackButton) {
        UIButton *playbackButton = [UIButton buttonWithType:UIButtonTypeCustom];
        playbackButton.frame = CGRectMake(CGRectGetMaxX(self.chatButton.frame)+10.0 ,0.0 ,playbackButton_wh,playbackButton_wh);
        playbackButton.tag = kOperatorBtnTag_Playback;
        [playbackButton addTarget:self action:@selector(onOperatorItemPress:) forControlEvents:UIControlEventTouchUpInside];
        [self.bottomView addSubview:playbackButton];
        self.playbackButton = playbackButton;
        
        UIImageView *playbackImageView = [[UIImageView alloc] initWithFrame:CGRectMake(playbackButton_wh-playbackImageView_w, (playbackButton_wh-playbackImageView_h)/2 ,playbackImageView_w,playbackImageView_h)];
        playbackImageView.image = playbackImage;
        [self.playbackButton addSubview:playbackImageView];
        [playbackImageView release];
    }
    //只有NPC、IPC才有
    
    
    //设置
    CGFloat controlButton_wh = self.bottomView.frame.size.height;
    //按钮图片的宽、高
    UIImage *controlImage = [UIImage imageNamed:@"ic_operator_item_control.png"];
    CGFloat controlImageView_h = 20.0;
    CGFloat controlImageView_w = controlImageView_h*(controlImage.size.width/controlImage.size.height);
    if (!self.controlButton) {
        UIButton *controlButton = [UIButton buttonWithType:UIButtonTypeCustom];
        controlButton.frame = CGRectMake(CGRectGetMaxX(self.playbackButton.frame)+10.0 ,0.0 ,controlButton_wh,controlButton_wh);
        controlButton.tag = kOperatorBtnTag_Control;
        [controlButton addTarget:self action:@selector(onOperatorItemPress:) forControlEvents:UIControlEventTouchUpInside];
        [self.bottomView addSubview:controlButton];
        self.controlButton = controlButton;
        
        UIImageView *controlImageView = [[UIImageView alloc] initWithFrame:CGRectMake(controlButton_wh-controlImageView_w, (controlButton_wh-controlImageView_h)/2 ,controlImageView_w,controlImageView_h)];
        controlImageView.image = controlImage;
        [self.controlButton addSubview:controlImageView];
        [controlImageView release];
    }
    
    //编辑
    CGFloat modifyButton_wh = self.bottomView.frame.size.height;
    //按钮图片的宽、高
    UIImage *modifyImage = [UIImage imageNamed:@"ic_operator_item_modify.png"];
    CGFloat modifyImageView_h = 20.0;
    CGFloat modifyImageView_w = modifyImageView_h*(modifyImage.size.width/modifyImage.size.height);
    if (!self.modifyButton) {
        UIButton *modifyButton = [UIButton buttonWithType:UIButtonTypeCustom];
        modifyButton.frame = CGRectMake(CGRectGetMaxX(self.controlButton.frame)+10.0 ,0.0 ,modifyButton_wh,modifyButton_wh);
        modifyButton.tag = kOperatorBtnTag_Modify;
        [modifyButton addTarget:self action:@selector(onOperatorItemPress:) forControlEvents:UIControlEventTouchUpInside];
        [self.bottomView addSubview:modifyButton];
        self.modifyButton = modifyButton;
        
        UIImageView *modifyImageView = [[UIImageView alloc] initWithFrame:CGRectMake(modifyButton_wh-modifyImageView_w, (modifyButton_wh-modifyImageView_h)/2 ,modifyImageView_w,modifyImageView_h)];
        modifyImageView.image = modifyImage;
        [self.modifyButton addSubview:modifyImageView];
        [modifyImageView release];
    }
    
    //根据设备类型，隐藏、显示 、调整布防撤防、弱密码、通话、回放、设置和编辑按钮
    [self reLayoutBtnViewInBottomByContactType];
    
    
    
    //弱密码按钮提前
    [self.contentView bringSubviewToFront:self.weakPwdButton];
    [self.contentView insertSubview:self.initDeviceButton belowSubview:self.weakPwdButton];
}

#pragma mark - 根据设备类型，隐藏、显示 、调整布防撤防、弱密码、通话、回放、设置和编辑按钮
-(void)reLayoutBtnViewInBottomByContactType{
    //
    switch(self.contact.contactType){
        case CONTACT_TYPE_PHONE:
        {
            //未知
        }
            break;
        case CONTACT_TYPE_DOORBELL:
        case CONTACT_TYPE_IPC:
        {
            //显示，布防撤防、弱密码、回放、设置和编辑按钮
            //编辑按钮
            CGFloat modifyButton_x = self.bottomView.frame.size.width-42.0/SCREEN_SCALE-self.modifyButton.frame.size.width;
            self.modifyButton.frame = CGRectMake(modifyButton_x, 0.0 ,self.modifyButton.frame.size.width, self.modifyButton.frame.size.height);
            //设置按钮
            CGFloat controlButton_x = self.modifyButton.frame.origin.x-self.controlButton.frame.size.width-10.0;
            self.controlButton.frame = CGRectMake(controlButton_x, 0.0 ,self.controlButton.frame.size.width, self.controlButton.frame.size.height);
            [self.controlButton setEnabled:YES];
            //回放按钮
            CGFloat playbackButton_x = self.controlButton.frame.origin.x-self.playbackButton.frame.size.width-10.0;
            self.playbackButton.frame = CGRectMake(playbackButton_x, 0.0 ,self.playbackButton.frame.size.width, self.playbackButton.frame.size.height);
            [self.playbackButton setHidden:NO];
            [self.playbackButton setEnabled:YES];
            //通话按钮
            [self.chatButton setHidden:YES];
            //弱密码按钮
            CGFloat weakPwdButton_x = self.playbackButton.frame.origin.x-self.weakPwdButton.frame.size.width-10.0;
            self.weakPwdButton.frame = CGRectMake(weakPwdButton_x, 0.0 ,self.weakPwdButton.frame.size.width, self.weakPwdButton.frame.size.height);
            
        }
            break;
        case CONTACT_TYPE_NPC:
        {
            //显示，布防撤防、弱密码、通话、回放、设置和编辑按钮
            //编辑按钮
            CGFloat modifyButton_x = self.bottomView.frame.size.width-42.0/SCREEN_SCALE-self.modifyButton.frame.size.width;
            self.modifyButton.frame = CGRectMake(modifyButton_x, 0.0 ,self.modifyButton.frame.size.width, self.modifyButton.frame.size.height);
            //设置按钮
            CGFloat controlButton_x = self.modifyButton.frame.origin.x-self.controlButton.frame.size.width-10.0;
            self.controlButton.frame = CGRectMake(controlButton_x, 0.0 ,self.controlButton.frame.size.width, self.controlButton.frame.size.height);
            [self.controlButton setEnabled:YES];
            //回放按钮
            CGFloat playbackButton_x = self.controlButton.frame.origin.x-self.playbackButton.frame.size.width-10.0;
            self.playbackButton.frame = CGRectMake(playbackButton_x, 0.0 ,self.playbackButton.frame.size.width, self.playbackButton.frame.size.height);
            [self.playbackButton setHidden:NO];
            [self.playbackButton setEnabled:YES];
            //通话按钮
            CGFloat chatButton_x = self.playbackButton.frame.origin.x-self.chatButton.frame.size.width-10.0;
            self.chatButton.frame = CGRectMake(chatButton_x, 0.0 ,self.chatButton.frame.size.width, self.chatButton.frame.size.height);
            [self.chatButton setHidden:NO];
            //弱密码按钮
            CGFloat weakPwdButton_x = self.chatButton.frame.origin.x-self.weakPwdButton.frame.size.width-10.0;
            self.weakPwdButton.frame = CGRectMake(weakPwdButton_x, 0.0 ,self.weakPwdButton.frame.size.width, self.weakPwdButton.frame.size.height);
            
        }
            break;
        case 888://NVR
        {
            //显示，设置、编辑按钮
            //编辑按钮
            CGFloat modifyButton_x = self.bottomView.frame.size.width-42.0/SCREEN_SCALE-self.modifyButton.frame.size.width;
            self.modifyButton.frame = CGRectMake(modifyButton_x, 0.0 ,self.modifyButton.frame.size.width, self.modifyButton.frame.size.height);
            //设置按钮
            CGFloat controlButton_x = self.modifyButton.frame.origin.x-self.controlButton.frame.size.width-10.0;
            self.controlButton.frame = CGRectMake(controlButton_x, 0.0 ,self.controlButton.frame.size.width, self.controlButton.frame.size.height);
            [self.controlButton setEnabled:YES];
            //回放按钮
            [self.playbackButton setHidden:YES];
            //通话按钮
            [self.chatButton setHidden:YES];
            //弱密码按钮
            [self.weakPwdButton setHidden:YES];
            //布防撤防按钮
            [self.defenceStateView setHidden:YES];
            [self.defenceProgressView setHidden:YES];
        }
            break;
        default:
        {
            if(self.contact.contactId.intValue<256){//IP添加设备
                //显示，回放、设置和编辑按钮
                //编辑按钮
                CGFloat modifyButton_x = self.bottomView.frame.size.width-42.0/SCREEN_SCALE-self.modifyButton.frame.size.width;
                self.modifyButton.frame = CGRectMake(modifyButton_x, 0.0 ,self.modifyButton.frame.size.width, self.modifyButton.frame.size.height);
                //设置按钮
                CGFloat controlButton_x = self.modifyButton.frame.origin.x-self.controlButton.frame.size.width-10.0;
                self.controlButton.frame = CGRectMake(controlButton_x, 0.0 ,self.controlButton.frame.size.width, self.controlButton.frame.size.height);
                [self.controlButton setEnabled:YES];
                //回放按钮
                CGFloat playbackButton_x = self.controlButton.frame.origin.x-self.playbackButton.frame.size.width-10.0;
                self.playbackButton.frame = CGRectMake(playbackButton_x, 0.0 ,self.playbackButton.frame.size.width, self.playbackButton.frame.size.height);
                [self.playbackButton setHidden:NO];
                [self.playbackButton setEnabled:YES];
                //通话按钮
                [self.chatButton setHidden:YES];
                //弱密码按钮
                [self.weakPwdButton setHidden:YES];
                //布防撤防按钮
                [self.defenceStateView setHidden:YES];
                [self.defenceProgressView setHidden:YES];
                
            }else{//其他
                //显示，回放(不可点击)、设置(不可点击)和编辑按钮
                //编辑按钮
                CGFloat modifyButton_x = self.bottomView.frame.size.width-42.0/SCREEN_SCALE-self.modifyButton.frame.size.width;
                self.modifyButton.frame = CGRectMake(modifyButton_x, 0.0 ,self.modifyButton.frame.size.width, self.modifyButton.frame.size.height);
                //设置按钮
                CGFloat controlButton_x = self.modifyButton.frame.origin.x-self.controlButton.frame.size.width-10.0;
                self.controlButton.frame = CGRectMake(controlButton_x, 0.0 ,self.controlButton.frame.size.width, self.controlButton.frame.size.height);
                [self.controlButton setEnabled:NO];
                //回放按钮
                CGFloat playbackButton_x = self.controlButton.frame.origin.x-self.playbackButton.frame.size.width-10.0;
                self.playbackButton.frame = CGRectMake(playbackButton_x, 0.0 ,self.playbackButton.frame.size.width, self.playbackButton.frame.size.height);
                [self.playbackButton setHidden:NO];
                [self.playbackButton setEnabled:NO];
                //通话按钮
                [self.chatButton setHidden:YES];
                //弱密码按钮
                [self.weakPwdButton setHidden:YES];
                //布防撤防按钮
                [self.defenceStateView setHidden:YES];
                [self.defenceProgressView setHidden:YES];
                
            }
        }
            break;
    }
}

-(void)willTransitionToState:(UITableViewCellStateMask)state{
    if (state == UITableViewCellStateShowingDeleteConfirmationMask) {
        //cell进入delete编辑状态时，不可以点击头像、空密码按钮
        [self.initDeviceButton setEnabled:NO];
        [self.headView setEnabled:NO];
    }else{
        //cell退出delete编辑状态时，可以点击头像、空密码按钮
        [self.initDeviceButton setEnabled:YES];
        [self.headView setEnabled:YES];
    }
}

#pragma mark - 通话、回放、设置和修改按钮
-(void)onOperatorItemPress:(id)sender{
    UIButton *button = (UIButton*)sender;
    
    
    if (self.delegate) {
        [self.delegate ContactCellOnClickBottomBtn:button.tag contact:self.contact];
    }
}

-(void)onHeadClick:(id)sender{
    DLog(@"HEAD CLICK");
    if (self.delegate) {
        [self.delegate onClick:self.position contact:self.contact];
    }
}

-(void)onDefencePress:(UIButton*)button{
    //UIImageView *imageView = [[button subviews] objectAtIndex:0];
    [[FListManager sharedFList] setIsClickDefenceStateBtnWithId:self.contact.contactId isClick:YES];
    if(self.contact.defenceState==DEFENCE_STATE_WARNING_NET||self.contact.defenceState==DEFENCE_STATE_WARNING_PWD){
        self.contact.defenceState = DEFENCE_STATE_LOADING;
        [self updateDefenceStateView];
        [[P2PClient sharedClient] getDefenceState:self.contact.contactId password:self.contact.contactPassword];
        
    }else if(self.contact.defenceState==DEFENCE_STATE_ON){
        self.contact.defenceState = DEFENCE_STATE_LOADING;
        [self updateDefenceStateView];
        [[P2PClient sharedClient] setRemoteDefenceWithId:self.contact.contactId password:self.contact.contactPassword state:SETTING_VALUE_REMOTE_DEFENCE_STATE_OFF];
    }else if(self.contact.defenceState==DEFENCE_STATE_OFF){
        self.contact.defenceState = DEFENCE_STATE_LOADING;
        [self updateDefenceStateView];
        [[P2PClient sharedClient] setRemoteDefenceWithId:self.contact.contactId password:self.contact.contactPassword state:SETTING_VALUE_REMOTE_DEFENCE_STATE_ON];
    }
}

-(void)updateDefenceStateView{
    if(self.contact.onLineState==STATE_ONLINE){
        if(self.contact.defenceState==DEFENCE_STATE_LOADING){
            [self.defenceStateView setHidden:YES];
            [self.defenceProgressView setHidden:NO];
            [self.defenceProgressView start];
            
        }else{
            [self.defenceStateView setHidden:NO];
            [self.defenceProgressView setHidden:YES];
            [self.defenceProgressView stop];
        }
        
    }else{
        [self.defenceStateView setHidden:YES];
        [self.defenceProgressView setHidden:YES];
        [self.defenceProgressView stop];
    }
}

-(void)showOrHiddenWeakPwdButton{
    //密码的第一位为0，则表示是加密过的，为非弱密码
    //因为设备密码的第一位不为0
    NSString *weakPwd = [self.contact.contactPassword substringToIndex:1];
    if ((self.contact.onLineState==STATE_ONLINE) && (self.contact.defenceState == DEFENCE_STATE_ON || self.contact.defenceState == DEFENCE_STATE_OFF) && (![weakPwd isEqualToString:@"0"])) {
        [self.weakPwdButton setHidden:NO];//弱（红）
        
    }else{
        [self.weakPwdButton setHidden:YES];
    }
}

@end
