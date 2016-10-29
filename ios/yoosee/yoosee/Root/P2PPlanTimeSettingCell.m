//
//  P2PPlanTimeSettingCell.m
//  Yoosee
//
//  Created by guojunyi on 14-5-19.
//  Copyright (c) 2014年 guojunyi. All rights reserved.
//

#import "P2PPlanTimeSettingCell.h"
#import "Constants.h"
#import "PlanTimePickView.h"
@implementation P2PPlanTimeSettingCell
-(void)dealloc{
    [self.picker1 release];
    [self.picker2 release];
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

-(void)layoutSubviews{
    [super layoutSubviews];
    CGFloat cellWidth = self.backgroundView.frame.size.width;
    CGFloat cellHeight = self.backgroundView.frame.size.height;
    
    
    if(!self.picker1){
       
        PlanTimePickView *picker1 = [[PlanTimePickView alloc] initWithFrame:CGRectMake(30,5, (cellWidth-30*2-15)/2, cellHeight-5*2)];
        self.picker1 = picker1;
        [picker1 release];
        [self.contentView addSubview:self.picker1];
        
        
    }else{
        
        [self.picker1 setFrame:CGRectMake(30,5, (cellWidth-30*2-15)/2, cellHeight-5*2)];
    }
    NSInteger hour_from = (self.planTime>>24)&0xff;
    NSInteger minute_from = (self.planTime>>8)&0xff;
    [self.picker1 selectedCellFromPlanTimePickView:hour_from minCell:minute_from];
    
    
    if(!self.picker2){
        
        PlanTimePickView *picker2 = [[PlanTimePickView alloc] initWithFrame:CGRectMake(30+(cellWidth-30*2-15)/2+15,5, (cellWidth-30*2-15)/2, cellHeight-5*2)];
        self.picker2 = picker2;
        [picker2 release];
        [self.contentView addSubview:self.picker2];
        
        
    }else{
        
        [self.picker2 setFrame:CGRectMake(30+(cellWidth-30*2-15)/2+15,5, (cellWidth-30*2-15)/2, cellHeight-5*2)];
    }
    NSInteger hour_to = (self.planTime>>16)&0xff;
    NSInteger minute_to = self.planTime&0xff;
    [self.picker2 selectedCellFromPlanTimePickView:hour_to minCell:minute_to];
    
}
@end
