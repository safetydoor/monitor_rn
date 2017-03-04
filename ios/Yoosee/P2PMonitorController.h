//
//  P2PMonitorController.h
//  Yoosee
//
//  Created by guojunyi on 14-3-26.
//  Copyright (c) 2014年 guojunyi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "P2PClient.h"
#import <AVFoundation/AVFoundation.h>
#import "TouchButton.h"
#import "OpenGLView.h"
#import "CustomBorderButton.h"
#import "CustomView.h"
#import "ProgressImageView.h"
#import "MainController.h"
#import "AppDelegate.h"
#define FocalLength_Elongation_btnTag 300
#define FocalLength_Shorten_btnTag 301
#define FocalLength_Change_sliderTag 302

//竖屏
#define SOUND_BUTTON_H_TAG 1603221
#define SWITCH_SCREEN_BUTTON_H_TAG 1603222
#define DEFENCE_BUTTON_H_TAG 1603223
#define TALK_BUTTON_H_TAG 1603224
#define SCREENSHOT_BUTTON_H_TAG 1603225
#define PROMPT_BUTTON_TAG 1603226

@class CustomTopBar;
@interface P2PMonitorController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate,UIGestureRecognizerDelegate,TouchButtonDelegate,OpenGLViewDelegate,UIScrollViewDelegate,UIAlertViewDelegate,MainControllerDelegate,GApplicationDelegate>//监控界面缩放
@property (nonatomic, strong) OpenGLView *remoteView;
@property (nonatomic) BOOL isReject;
@property (nonatomic) BOOL isFullScreen4B3;
@property (nonatomic) BOOL isShowControllerBar;
@property (nonatomic) BOOL isVideoModeHD;

@property (nonatomic,strong) UIScrollView *scrollView;//监控界面缩放
@property (nonatomic) BOOL isScale;//监控界面缩放

@property (strong, nonatomic) UIView *bottomView;//重新调整监控画面
@property (strong, nonatomic) UIView *pressView;
@property (nonatomic) BOOL isTalking;

@property (strong, nonatomic) UIView *controllerRight;
@property (strong, nonatomic) UIView *controllerRightBg;//重新调整监控画面
@property (strong, nonatomic) UIView *bottomBarView;//重新调整监控画面
@property (strong, nonatomic) UIView *controllBar;

@property (nonatomic) BOOL isAlreadyShowResolution;//重新调整监控画面

@property (nonatomic) BOOL isDefenceOn;//重新调整监控画面

//GPIO 口控制参数记录
@property(strong, nonatomic) CustomBorderButton *customBorderButton;
@property(strong, nonatomic) CustomView *leftView;
@property(nonatomic) BOOL isShowLeftView;

@property(nonatomic) int lastGroup;
@property(nonatomic) int lastPin;
@property(nonatomic) int lastValue;
@property(nonatomic) int *lastTime;

@property(nonatomic, strong) UIButton *clickGPIO0_0Button;
@property(nonatomic, strong) UIButton *clickGPIO0_1Button;
@property(nonatomic, strong) UIButton *clickGPIO0_2Button;
@property(nonatomic, strong) UIButton *clickGPIO0_3Button;
@property(nonatomic, strong) UIButton *clickGPIO0_4Button;
@property(nonatomic, strong) UIButton *clickGPIO2_6Button;

@property(nonatomic, strong) UIButton *lightButton;
@property (nonatomic) BOOL isLightSwitchOn;
@property (strong, nonatomic) UIActivityIndicatorView *progressView;
@property (nonatomic) BOOL isSupportLightSwitch;



@property (strong, nonatomic) UIView *focalLengthView;
@property (nonatomic) BOOL isSupportFocalLength;
@property (strong, nonatomic) UIPinchGestureRecognizer *pinchGestureRecognizer;

//判断当前监控处于横屏还是竖屏界面
@property (assign,nonatomic) BOOL isFullScreen;
@property (strong, nonatomic) UIView *fullScreenBgView;

//竖屏控件
@property (nonatomic,strong) CustomTopBar *topBar;   //全屏时，隐藏
@property (nonatomic,strong) UIView *canvasView;    //显示监控画面的载体
@property (assign,nonatomic) CGRect canvasframe;
@property (nonatomic,strong) UIButton *promptButton;
@property (nonatomic,strong) UILabel *labelTip;
@property (strong, nonatomic) ProgressImageView *yProgressView;
@property (nonatomic,strong) UIView *midToolHView;   //全屏时，隐藏
@property (nonatomic,strong) UIView *bottomToolHView;   //全屏时，隐藏
@property (nonatomic,strong) UIButton *defenceButtonH;   //布防撤防按钮

//YES表示当前处于监控中，且接收到推送，点击观看监控
@property (assign,nonatomic) BOOL isIntoMonitorFromMonitor;

@end
