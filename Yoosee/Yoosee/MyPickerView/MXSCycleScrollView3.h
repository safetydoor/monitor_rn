//
//  MXSCycleScrollView3.h
//  2cu
//
//  Created by 高琦 on 15/2/9.
//  Copyright (c) 2015年 guojunyi. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol MXSCycleScrollView3Delegate;
@protocol MXSCycleScrollView3Datasource;
@interface MXSCycleScrollView3 : UIView<UIScrollViewDelegate>
{
    UIScrollView *_scrollView;
    
    NSInteger _totalPages;
    NSInteger _curPage;
    
    NSMutableArray *_curViews;
}
@property (nonatomic,readonly) UIScrollView *scrollView;
@property (nonatomic,assign) NSInteger currentPage;
@property (nonatomic,assign)BOOL isthreelabel;
@property (nonatomic,assign,setter = setDataource:) id<MXSCycleScrollView3Datasource> datasource;
@property (nonatomic,assign,setter = setDelegate:) id<MXSCycleScrollView3Delegate> delegate;

- (void)setCurrentSelectPage:(NSInteger)selectPage; //设置初始化页数
- (void)reloadData;
- (void)setViewContent:(UIView *)view atIndex:(NSInteger)index;

@end

@protocol MXSCycleScrollView3Delegate <NSObject>

@optional
- (void)didClickPage:(MXSCycleScrollView3 *)csView atIndex:(NSInteger)index;
- (void)scrollviewDidChangeNumber;
- (void)scrollviewDidEndChangeNumber;

@end

@protocol MXSCycleScrollView3Datasource <NSObject>

@required
- (NSInteger)numberOfPages:(MXSCycleScrollView3 *)scrollView;
- (UIView *)pageAtIndex:(NSInteger)index andScrollView:(MXSCycleScrollView3 *)scrollView;

@end