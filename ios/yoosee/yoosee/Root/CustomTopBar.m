//
//  CustomTopBar.m
//  Yoosee
//
//  Created by eppla on 16/3/23.
//  Copyright © 2016年 guojunyi. All rights reserved.
//

#import "CustomTopBar.h"
#import "Constants.h"

@implementation CustomTopBar

-(void)dealloc{
    [self.backgroundImageView release];
    
    [self.titleLabel release];
    
    [self.backButton release];
    [self.backButtonIconView release];
    
    [self.leftButton release];
    [self.leftButtonIconView release];
    
    [self.rightButton release];
    [self.rightButtonIconView release];
    [self.rightButtonLabel release];
    
    [self.rightButton2 release];
    [self.rightButtonLabel2 release];
    [super dealloc];
}

#define MSG_ICON_ITERVAL_X  17
#define MSG_ICON_ITERVAL_Y  7

#define LEFT_BAR_BTN_WIDTH (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 90:60)
#define LEFT_BAR_BTN_MARGIN (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 10:5.0)

#define RIGHT_BAR_BTN_WIDTH (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 90:60)
#define RIGHT_BAR_BTN_MARGIN (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 10:5)

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        //TopBar导航的背景
        UIImageView *backImgView = [[UIImageView alloc] initWithFrame:frame];
        backImgView.image = [UIImage imageNamed:@""];
        [self addSubview:backImgView];
        self.backgroundImageView = backImgView;
        [backImgView release];
        
        
        
        //导航内容的frame为(0.0, 20.0, width, 44.0)
        if(CURRENT_VERSION>=7.0){
            frame = CGRectMake(frame.origin.x, frame.origin.y+20, frame.size.width, frame.size.height-20);
        }
        
        
        
        //导航的标题
        UILabel *textLabel = [[UILabel alloc] initWithFrame:frame];
        textLabel.backgroundColor = XBGAlpha;
        textLabel.textAlignment = NSTextAlignmentCenter;
        textLabel.textColor = XHeadBarTextColor;
        [textLabel setFont:[UIFont boldSystemFontOfSize:XHeadBarTextSize]];
        [backImgView addSubview:textLabel];
        self.titleLabel = textLabel;
        [textLabel release];
        
        
        
        //导航的返回按钮
        //导航栏为44.0，图片为20.0*20.0
        CGFloat backButton_x = 5.0;
        CGFloat backButton_y = 5.0;
        CGFloat backButton_w = 44.0-2*backButton_y;
        CGFloat backButton_h = backButton_w;
        UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        backButton.frame = CGRectMake(backButton_x, frame.origin.y+backButton_y, backButton_w, backButton_h);
        [self addSubview:backButton];
        [backButton setHidden:YES];
        self.backButton = backButton;
        //返回按钮的图片
        UIImageView *backBtnIconView = [[UIImageView alloc]initWithFrame:CGRectMake((self.backButton.frame.size.width-self.backButton.frame.size.height)/2, 0, self.backButton.frame.size.height, self.backButton.frame.size.height)];
        backBtnIconView.image = [UIImage imageNamed:@""];
        [self.backButton addSubview:backBtnIconView];
        self.backButtonIconView = backBtnIconView;
        [backBtnIconView release];
        
        
        
        //导航左边的按钮（只是大小与返回按钮不同）
        //导航栏为44.0，图片为20.0*20.0
        CGFloat leftButton_x = 5.0;
        CGFloat leftButton_y = 5.0;
        CGFloat leftButton_w = 44.0-2*leftButton_y;
        CGFloat leftButton_h = leftButton_w;
        UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
        leftButton.frame = CGRectMake(leftButton_x, frame.origin.y+leftButton_y, leftButton_w, leftButton_h);
        [self addSubview:leftButton];
        [leftButton setHidden:YES];
        self.leftButton = leftButton;
        //左边按钮的图片
        UIImageView *leftButtonIconView = [[UIImageView alloc]initWithFrame:CGRectMake((self.leftButton.frame.size.width-self.leftButton.frame.size.height)/2, LEFT_BAR_BTN_MARGIN, self.leftButton.frame.size.height-10, self.leftButton.frame.size.height-10)];
        leftButtonIconView.image = [UIImage imageNamed:@""];
        leftButtonIconView.contentMode = UIViewContentModeScaleAspectFit;
        [self.leftButton addSubview:leftButtonIconView];
        self.leftButtonIconView = leftButtonIconView;
        [leftButtonIconView release];
        
        
        
        //导航右边的按钮
        //导航栏为44.0，图片为20.0*20.0
        CGFloat rightMargin = 5.0;
        CGFloat rightButton_y = 5.0;
        CGFloat rightButton_w = 44.0-2*rightButton_y;
        CGFloat rightButton_h = rightButton_w;
        UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        rightButton.frame = CGRectMake(frame.size.width-rightMargin-rightButton_w, frame.origin.y+rightButton_y, rightButton_w, rightButton_h);
        [self addSubview:rightButton];
        [rightButton setHidden:YES];
        self.rightButton = rightButton;
        //右边按钮的图片
        UIImageView *rightButtonIconView = [[UIImageView alloc]initWithFrame:CGRectMake((self.rightButton.frame.size.width-self.rightButton.frame.size.height)/2, 0, self.rightButton.frame.size.height, self.rightButton.frame.size.height)];
        rightButtonIconView.image = [UIImage imageNamed:@""];
        [self.rightButton addSubview:rightButtonIconView];
        self.rightButtonIconView = rightButtonIconView;
        [rightButtonIconView release];
        //右边按钮的文本
        UILabel *rightButtonLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,self.rightButton.frame.size.width,self.rightButton.frame.size.height)];
        rightButtonLabel.backgroundColor = XBGAlpha;
        rightButtonLabel.textAlignment = NSTextAlignmentCenter;
        rightButtonLabel.textColor = XWhite;
        [rightButtonLabel setFont:XFontBold_14];
        [self.rightButton addSubview:rightButtonLabel];
        self.rightButtonLabel = rightButtonLabel;
        [rightButtonLabel release];
        
        
        
        //导航第二种右边按钮(显示新的报警记录)
        UIButton *rightButton2 = [UIButton buttonWithType:UIButtonTypeCustom];
        rightButton2.frame = CGRectMake(frame.origin.x+(frame.size.width-RIGHT_BAR_BTN_MARGIN-RIGHT_BAR_BTN_WIDTH-RIGHT_BAR_BTN_WIDTH+10), frame.origin.y+RIGHT_BAR_BTN_MARGIN, RIGHT_BAR_BTN_WIDTH, frame.size.height-RIGHT_BAR_BTN_MARGIN*2);
        rightButton2.layer.cornerRadius = 10;
        [self addSubview:rightButton2];
        [rightButton2 setHidden:YES];
        self.rightButton2 = rightButton2;
        //按钮文本
        UILabel *rightButtonLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(self.rightButton2.frame.origin.x+self.rightButton2.frame.size.width-MSG_ICON_ITERVAL_X-10, self.rightButton2.frame.origin.y+MSG_ICON_ITERVAL_Y-8, 16, 16)];
        rightButtonLabel2.backgroundColor = [UIColor redColor];
        rightButtonLabel2.layer.cornerRadius = 8;//rectButton2.size.height/2;
        [[rightButtonLabel2 layer] setMasksToBounds:YES];
        rightButtonLabel2.textAlignment = NSTextAlignmentCenter;
        rightButtonLabel2.textColor = XWhite;
        [rightButtonLabel2 setFont:[UIFont boldSystemFontOfSize:8.0]];
        [self addSubview:rightButtonLabel2];
        rightButtonLabel2.hidden = YES;
        self.rightButtonLabel2 = rightButtonLabel2;
        [rightButtonLabel2 release];
    }
    return self;
}

#pragma mark - 导航背景设置
-(void)setBackgroundImageViewWith:(UIImage *)backgroundImage withBackgroundColor:(UIColor *)backgroundColor{
    if (self.backgroundImageView && backgroundImage) {//bg_navigation_bar.png
        backgroundImage = [backgroundImage stretchableImageWithLeftCapWidth:backgroundImage.size.width*0.5 topCapHeight:backgroundImage.size.height*0.5];
        self.backgroundImageView.image = backgroundImage;
    }
    
    if (self.backgroundImageView && backgroundColor) {//UIColorFromRGB(0x35c5e7)
        [self.backgroundImageView setBackgroundColor:backgroundColor];
    }
}


#pragma mark - 设置导航的标题
-(void)setTitle:(NSString *)title{
    
    if(self.titleLabel){
        self.titleLabel.text = title;
    }
}


#pragma mark - 导航返回按钮
#pragma mark 隐藏或者显示
-(void)setBackButtonHidden:(BOOL)hidden{
    if(self.backButton){
        [self.backButton setHidden:hidden];
    }
}
#pragma mark 设置图片
-(void)setBackButtonIcon:(UIImage*)img{
    if (self.backButtonIconView) {
        CGFloat backButtonIconView_w = img.size.width/SCREEN_SCALE;
        CGFloat backButtonIconView_h = backButtonIconView_w*(img.size.height/img.size.width);
        self.backButtonIconView.frame = CGRectMake((self.backButton.frame.size.width-backButtonIconView_w)/2, (self.backButton.frame.size.height-backButtonIconView_h)/2, backButtonIconView_w, backButtonIconView_h);
        self.backButtonIconView.image = img;
    }
}


#pragma mark - 导航左边按钮
#pragma mark 隐藏或者显示
-(void)setLeftButtonHidden:(BOOL)hidden{
    if (self.leftButton) {
        [self.leftButton setHidden:hidden];
    }
}
#pragma mark 设置图片
-(void)setLeftButtonIcon:(UIImage *)img{
    if (self.leftButtonIconView) {
        CGFloat leftButtonIconView_w = img.size.width/SCREEN_SCALE;
        CGFloat leftButtonIconView_h = leftButtonIconView_w*(img.size.height/img.size.width);
        self.leftButtonIconView.frame = CGRectMake((self.rightButton.frame.size.width-leftButtonIconView_w)/2, (self.rightButton.frame.size.height-leftButtonIconView_h)/2, leftButtonIconView_w, leftButtonIconView_h);
        self.leftButtonIconView.image = img;
    }
}


#pragma mark - 导航右边按钮
#pragma mark 隐藏或者显示
-(void)setRightButtonHidden:(BOOL)hidden{
    if(self.rightButton){
        [self.rightButton setHidden:hidden];
    }
}
#pragma mark 设置图片
-(void)setRightButtonIcon:(UIImage *)img{
    if(self.rightButtonIconView){
        CGFloat rightButtonIconView_w = img.size.width/SCREEN_SCALE;
        CGFloat rightButtonIconView_h = rightButtonIconView_w*(img.size.height/img.size.width);
        self.rightButtonIconView.frame = CGRectMake((self.rightButton.frame.size.width-rightButtonIconView_w)/2, (self.rightButton.frame.size.height-rightButtonIconView_h)/2, rightButtonIconView_w, rightButtonIconView_h);
        self.rightButtonIconView.image = img;
    }
}
#pragma mark 设置文本
-(void)setRightButtonText:(NSString *)text{
    if(self.rightButtonLabel){
        self.rightButtonLabel.text = text;
    }
}


#pragma mark - 导航右边按钮2
#pragma mark 隐藏或者显示
-(void)setRightButtonHidden2:(BOOL)hidden{
    if (self.rightButton2) {
        [self.rightButton2 setHidden:hidden];
        [self.rightButtonLabel2 setHidden:hidden];
    }
}
#pragma mark 设置图片2
-(void)setRightButtonIcon2:(UIImage *)img{
    if (self.rightButton2) {
        self.rightButton2.imageEdgeInsets = UIEdgeInsetsMake(MSG_ICON_ITERVAL_Y, MSG_ICON_ITERVAL_X, MSG_ICON_ITERVAL_Y, MSG_ICON_ITERVAL_X);
        [self.rightButton2 setImage:img forState:UIControlStateNormal];
    }
}
#pragma mark 设置文本2
-(void)setRightButtonText2:(NSString *)text{
    if  (self.rightButtonLabel2 == nil || self.rightButton2 == nil)
        return;
    
    if (NSOrderedSame == [text compare:@"0"])
    {
        [self.rightButton2 setHidden:YES];
        [self.rightButtonLabel2 setHidden:YES];
    }
    else
    {
        [self.rightButton2 setHidden:NO];
        [self.rightButtonLabel2 setHidden:NO];
        [self.rightButtonLabel2 setText:text];
    }
}

@end
