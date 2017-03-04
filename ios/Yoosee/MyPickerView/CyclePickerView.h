//
//  CyclePickerView.h
//  RBCustomDateTimePicker
//
//  Created by 高琦 on 15/1/22.
//  Copyright (c) 2015年 renbing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MXSCycleScrollView.h"
@protocol CyclePickerViewDatasource;
@protocol CyclePickerViewDelegate;
@interface CyclePickerView : UIView<MXSCycleScrollViewDatasource,MXSCycleScrollViewDelegate>
@property (nonatomic, assign) id<CyclePickerViewDatasource> datasource;
@property (nonatomic, assign) id<CyclePickerViewDelegate> delegate;
@property (nonatomic,strong) NSMutableArray * scrollWidthProportion;//每一列所占的宽度比例
@property (nonatomic,strong) NSMutableArray * numberOfCellsInScroll;//每一列滚轮上cell的个数
@property (nonatomic,strong) NSMutableArray * scrollviews;
@property (nonatomic,copy) NSString * scrollWidthstring;
@property (nonatomic,strong) NSArray * valueOfCellsInScroll;
- (void)setAfterScrollShowView:(MXSCycleScrollView*)scrollview  andCurrentPage:(NSInteger)pageNumber;
- (void)reloadScroll;
//设置默认选中的Cell
- (void)selectCell:(NSUInteger)cell inScroll:(NSUInteger)scroll;

@end

@protocol CyclePickerViewDatasource<NSObject>
@required
//指定每一列的滚轮上的Cell的个数
- (NSUInteger)numberOfCellsInScroll:(NSUInteger)scroll;
//指定每一列滚轮所占整体宽度的比例，以:分隔
- (NSString *)scrollWidthProportion;
//指定每一列的滚轮上的Cell的初始值，以:分隔
- (NSString *)valueOfCellsInScroll;
@end

@protocol CyclePickerViewDelegate<NSObject>
@optional
//当滚轮的值改变时调用此方法，数组中为选中值的字符串类型
- (void)CyclePickerViewDidChangeValue:(NSArray *) valuearr;
@end