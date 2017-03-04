//
//  ProgressImageView.h
//  Yoosee
//
//  Created by eppla on 16/3/25.
//  Copyright © 2016年 guojunyi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProgressImageView : UIImageView

@property (nonatomic) CGFloat angle;
@property (nonatomic) BOOL isStartAnim;
@property (nonatomic,strong) UIImageView *backgroundView;

-(void)start;
-(void)stop;

@end
