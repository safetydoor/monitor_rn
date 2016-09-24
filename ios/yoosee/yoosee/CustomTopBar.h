//
//  CustomTopBar.h
//  Yoosee
//
//  Created by eppla on 16/3/23.
//  Copyright © 2016年 guojunyi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomTopBar : UIView

//导航背景
@property (strong, nonatomic) UIImageView *backgroundImageView;

//导航标题
@property (strong, nonatomic) UILabel *titleLabel;

//导航返回按钮
@property (strong, nonatomic) UIButton *backButton;
@property (strong, nonatomic) UIImageView *backButtonIconView;

//导航左边按钮
@property (strong, nonatomic) UIButton *leftButton;
@property (strong, nonatomic) UIImageView *leftButtonIconView;

//导航右边按钮
@property (strong, nonatomic) UIButton *rightButton;
@property (strong, nonatomic) UIImageView *rightButtonIconView;
@property (strong, nonatomic) UILabel *rightButtonLabel;

//导航右边按钮2
@property (strong, nonatomic) UIButton *rightButton2;
@property (strong, nonatomic) UILabel *rightButtonLabel2;


//导航背景设置
-(void)setBackgroundImageViewWith:(UIImage *)backgroundImage withBackgroundColor:(UIColor *)backgroundColor;

//导航标题
-(void)setTitle:(NSString*)title;

//导航返回按钮
-(void)setBackButtonHidden:(BOOL)hidden;
-(void)setBackButtonIcon:(UIImage*)img;

//导航左边按钮
-(void)setLeftButtonHidden:(BOOL)hidden;
-(void)setLeftButtonIcon:(UIImage*)img;

//导航右边按钮
-(void)setRightButtonHidden:(BOOL)hidden;
-(void)setRightButtonIcon:(UIImage*)img;
-(void)setRightButtonText:(NSString*)text;

//导航右边按钮2
-(void)setRightButtonHidden2:(BOOL)hidden;
-(void)setRightButtonIcon2:(UIImage*)img;
-(void)setRightButtonText2:(NSString*)text;

@end
