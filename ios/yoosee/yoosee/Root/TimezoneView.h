//
//  TimezoneView.h
//  Yoosee
//
//  Created by guojunyi on 14-9-28.
//  Copyright (c) 2014年 guojunyi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IDJPickerView.h"
#import "Constants.h"
@protocol TimezoneViewDelegate <NSObject>

@optional
-(void)onTimezoneChange:(NSInteger)timezone;
@end

//时区值数组,用于APP上显示
static float fTimeZoneVal[30] = {-11,-10,-9,-8,-7,-6,-5,-4,-3.5,-3,-2,-1,0,1,2,3,3.5,4,4.5,5,5.5,6,6.5,7,8,9,9.5,10,11,12};
//设置时区值数组时，相应发送给设备的值
static float fTimeZoneFlag[30] = {0,1,2,3,4,5,6,7,29,8,9,10,11,12,13,14,25,15,26,16,24,17,27,18,19,20,28,21,22,23};

//发送给设备的值在fTimeZoneFlag对应的下标
static int timeZoneFlag[30] = {0,1,2,3,4,5,6,7,9,10,11,12,13,14,15,17,19,21,23,24,25,27,28,29,20,16,18,22,26,8};

@interface TimezoneView : UIView
@property (nonatomic, strong) IDJPickerView *picker;
@property (nonatomic) NSInteger timezone;
@property (nonatomic, assign) id<TimezoneViewDelegate> delegate;

//选择当前cell
-(void)selectedCellFromTimezoneView:(NSUInteger)cell;

@end
