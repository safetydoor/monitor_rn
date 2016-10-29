//
//  ProgressImageView.m
//  Yoosee
//
//  Created by eppla on 16/3/25.
//  Copyright © 2016年 guojunyi. All rights reserved.
//

#import "ProgressImageView.h"

@implementation ProgressImageView

-(void)dealloc{
    [self.backgroundColor release];
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        [self addSubview:backgroundView];
        self.backgroundView = backgroundView;
        
    }
    return self;
}

-(void)start{
    if(self.isStartAnim){
        return;
    }
    self.angle = 0.0;
    self.isStartAnim = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while(self.isStartAnim){
            dispatch_async(dispatch_get_main_queue(), ^{
                self.backgroundView.transform = CGAffineTransformMakeRotation(self.angle);
            });
            self.angle += 0.01;
            if(self.angle>M_PI*2){
                self.angle = 0.0;
                //usleep(300000);
            }else{
                usleep(1000);
            }
            
        }
        self.isStartAnim = NO;
    });
    
}

-(void)stop{
    self.isStartAnim = NO;
}

@end
