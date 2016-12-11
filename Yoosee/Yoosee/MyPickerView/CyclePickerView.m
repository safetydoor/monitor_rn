//
//  CyclePickerView.m
//  RBCustomDateTimePicker
//
//  Created by 高琦 on 15/1/22.
//  Copyright (c) 2015年 renbing. All rights reserved.
//
#define RGBA(r,g,b,a)               [UIColor colorWithRed:(float)r/255.0f green:(float)g/255.0f blue:(float)b/255.0f alpha:(float)a]

#import "CyclePickerView.h"
@interface CyclePickerView(){
    UIView  *timeBroadcastView;//定时播放显示视图
}
@end


@implementation CyclePickerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self CreatePickerView];
    }
    return self;
}
- (void)CreatePickerView{
    CGRect rect = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    timeBroadcastView = [[UIView alloc] initWithFrame:rect];
    NSInteger rowheight = timeBroadcastView.frame.size.height/5;
    NSInteger width = timeBroadcastView.frame.size.width;
    timeBroadcastView.layer.masksToBounds = YES;
    [self addSubview:timeBroadcastView];
    [timeBroadcastView release];
    
    UIView *beforeSepLine = [[UIView alloc] initWithFrame:CGRectMake(0, rowheight, timeBroadcastView.frame.size.width, 1.0)];
    [beforeSepLine setBackgroundColor:RGBA(237.0, 237.0, 237.0, 1.0)];
    [timeBroadcastView addSubview:beforeSepLine];
    [beforeSepLine release];
    
    UIView *middleSepLine = [[UIView alloc] initWithFrame:CGRectMake(0, rowheight*2+1, timeBroadcastView.frame.size.width, 0.5)];
    [middleSepLine setBackgroundColor:[UIColor blackColor]];
    [timeBroadcastView addSubview:middleSepLine];
    [middleSepLine release];
    
    UIImage* image1= [UIImage imageNamed:@"timeset1.png"];
     image1 = [image1 stretchableImageWithLeftCapWidth:image1.size.width*0.5 topCapHeight:image1.size.height*0.5];
    UIImageView * imageview1 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 12, timeBroadcastView.frame.size.width/30, rowheight*5-7)];
    imageview1.image=image1;
    [timeBroadcastView addSubview:imageview1];
    [imageview1 release];
    
    UIImage* image2= [UIImage imageNamed:@"timeset2.png"];
    image2 = [image2 stretchableImageWithLeftCapWidth:image2.size.width*0.5 topCapHeight:image2.size.height*0.5];
    UIImageView * imageview2 = [[UIImageView alloc] initWithFrame:CGRectMake(width-timeBroadcastView.frame.size.width/30, 0, timeBroadcastView.frame.size.width/30, rowheight*5)];
    imageview2.image=image2;
    [timeBroadcastView addSubview:imageview2];
    [imageview2 release];
    
    UIView * middlesecSepLine =[[UIView alloc] initWithFrame:CGRectMake(0, rowheight*3+1, timeBroadcastView.frame.size.width, 0.5)];
    [middlesecSepLine setBackgroundColor:[UIColor blackColor]];
    [timeBroadcastView addSubview:middlesecSepLine];
    [middlesecSepLine release];
    
    UIView *bottomSepLine = [[UIView alloc] initWithFrame:CGRectMake(0, rowheight*4+1, timeBroadcastView.frame.size.width, 1.5)];
    [bottomSepLine setBackgroundColor:RGBA(237.0, 237.0, 237.0, 1.0)];
    [timeBroadcastView addSubview:bottomSepLine];
    [bottomSepLine release];

}
- (void)reloadScroll{
    self.valueOfCellsInScroll = [[self.datasource valueOfCellsInScroll] componentsSeparatedByString:@":"];;
    [self createscrollview];
}
- (void)createscrollview{
    NSArray *array=[[self.datasource scrollWidthProportion] componentsSeparatedByString:@":"];
    CGFloat total=0.0;
    for (NSInteger i=0; i<array.count; i++) {
        total+=[[array objectAtIndex:i]floatValue];
    }
    self.scrollWidthProportion=[NSMutableArray arrayWithCapacity:array.count];
    for (NSInteger i=0; i<array.count; i++) {
        [_scrollWidthProportion addObject:[NSString stringWithFormat:@"%f", [[array objectAtIndex:i]floatValue]/total]];
    }
    
//设置每个滚轮的个数
    self.numberOfCellsInScroll = [NSMutableArray arrayWithCapacity:array.count];
    self.scrollviews = [NSMutableArray arrayWithCapacity:array.count];
    for (NSInteger i = 0; i<array.count; i++) {
        NSInteger numberOfCells=[self.datasource numberOfCellsInScroll:i];
        [self.numberOfCellsInScroll addObject:[NSString stringWithFormat:@"%ld", (long)numberOfCells]];
    }
    CGFloat noworigin = 0.0;
    for (NSInteger i = 0; i<array.count; i++) {
        
        MXSCycleScrollView * cyclescrollView = [[MXSCycleScrollView alloc] initWithFrame:CGRectMake(noworigin*self.frame.size.width, 0, [_scrollWidthProportion[i] floatValue]*self.frame.size.width, self.frame.size.height)];
        //NSLog(@">>>>>>>>>%@",NSStringFromCGRect(cyclescrollView.frame));
        cyclescrollView.delegate = self;
        cyclescrollView.datasource = self;
        cyclescrollView.tag = i+100;
        [self.scrollviews addObject:cyclescrollView];
        //[self setAfterScrollShowView:cyclescrollView andCurrentPage:1];
        [timeBroadcastView addSubview:cyclescrollView];
        noworigin+=[_scrollWidthProportion[i] floatValue];
    }
    for (MXSCycleScrollView * scrollv in self.scrollviews) {
        [scrollv reloadData];
       [self setAfterScrollShowView:scrollv andCurrentPage:1];
    }
}
- (void)setAfterScrollShowView:(MXSCycleScrollView*)scrollview  andCurrentPage:(NSInteger)pageNumber
{
    UILabel *oneLabel = [[(UILabel*)[[scrollview subviews] objectAtIndex:0] subviews] objectAtIndex:pageNumber];
    [oneLabel setFont:[UIFont systemFontOfSize:14]];
    [oneLabel setTextColor:RGBA(186.0, 186.0, 186.0, 1.0)];
    UILabel *twoLabel = [[(UILabel*)[[scrollview subviews] objectAtIndex:0] subviews] objectAtIndex:pageNumber+1];
    [twoLabel setFont:[UIFont systemFontOfSize:16]];
    [twoLabel setTextColor:RGBA(113.0, 113.0, 113.0, 1.0)];
    
    UILabel *currentLabel = [[(UILabel*)[[scrollview subviews] objectAtIndex:0] subviews] objectAtIndex:pageNumber+2];
    [currentLabel setFont:[UIFont systemFontOfSize:18]];
    [currentLabel setTextColor:RGBA(32.0, 94.0, 252.0, 1.0)];
    
    UILabel *threeLabel = [[(UILabel*)[[scrollview subviews] objectAtIndex:0] subviews] objectAtIndex:pageNumber+3];
    [threeLabel setFont:[UIFont systemFontOfSize:16]];
    [threeLabel setTextColor:RGBA(113.0, 113.0, 113.0, 1.0)];
    UILabel *fourLabel = [[(UILabel*)[[scrollview subviews] objectAtIndex:0] subviews] objectAtIndex:pageNumber+4];
    [fourLabel setFont:[UIFont systemFontOfSize:14]];
    [fourLabel setTextColor:RGBA(186.0, 186.0, 186.0, 1.0)];
}

#pragma mark mxccyclescrollview delegate
#pragma mark mxccyclescrollview databasesource
- (NSInteger)numberOfPages:(MXSCycleScrollView*)scrollView
{
    
    for (MXSCycleScrollView * sc in self.scrollviews) {
        if (scrollView.tag == sc.tag) {
            return [_numberOfCellsInScroll[sc.tag-100] integerValue];
        }
        
    }
    return 60;
}

- (UIView *)pageAtIndex:(NSInteger)index andScrollView:(MXSCycleScrollView *)scrollView
{
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, scrollView.frame.size.width, scrollView.frame.size.height/5)];
    
    l.tag = index+100;
    static NSInteger cnt = 0;
    for (MXSCycleScrollView * sc in self.scrollviews) {
        if (scrollView.tag == sc.tag) {
            cnt = sc.tag-100;
            l.text = [NSString stringWithFormat:@"%d",(int)index+(int)[[self.valueOfCellsInScroll objectAtIndex:cnt] integerValue]];
        }
    }
    l.font = [UIFont systemFontOfSize:12];
    l.textAlignment = NSTextAlignmentCenter;
    l.backgroundColor = [UIColor clearColor];
    return l;
}

#pragma mark 当滚动时设置选中的cell
- (void)scrollviewDidChangeNumber
{
    for (MXSCycleScrollView * scrollview in self.scrollviews) {
        UILabel * label = [[(UILabel*)[[scrollview subviews] objectAtIndex:0] subviews] objectAtIndex:3];
        label.textColor = RGBA(32.0, 94.0, 252.0, 1.0);
    }
}
#pragma mark 滚动完成后的回调
- (void)scrollviewDidEndChangeNumber
{
    
    NSMutableArray  * scrollvalue = [NSMutableArray array];
    for (MXSCycleScrollView * scrollview in self.scrollviews) {
        UILabel * label = [[(UILabel*)[[scrollview subviews] objectAtIndex:0] subviews] objectAtIndex:3];
        label.textColor = RGBA(32.0, 94.0, 252.0, 1.0);
        [scrollvalue addObject:label.text];
    }
    if ([_delegate respondsToSelector:@selector(CyclePickerViewDidChangeValue:)]) {
        [_delegate CyclePickerViewDidChangeValue:scrollvalue];
    }
}
#pragma mark 设置默认选中的Cell
- (void)selectCell:(NSUInteger)cell inScroll:(NSUInteger)scroll{
    MXSCycleScrollView * scrollview = [self.scrollviews objectAtIndex:scroll];
    [scrollview setCurrentSelectPage:cell];
    [scrollview reloadData];
    [self setAfterScrollShowView:scrollview andCurrentPage:1];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
