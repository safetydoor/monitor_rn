//
//  KTPhotoView.h
//  Sample
//
//  Created by Kirby Turner on 2/24/10.
//  Copyright 2010 White Peak Software Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol KTPhotoViewDelegate//保存图片到相册
-(void)KTPhotoViewDeleteImage:(NSInteger)deleteIndex;
@end

@class KTPhotoScrollViewController;


@interface KTPhotoView : UIScrollView <UIScrollViewDelegate,UIActionSheetDelegate>//保存图片到相册
{
   UIImageView *imageView_;
   KTPhotoScrollViewController *scroller_;
   NSInteger index_;
}

@property (nonatomic, assign) KTPhotoScrollViewController *scroller;
@property (nonatomic, assign) NSInteger index;

@property (assign, nonatomic) id<KTPhotoViewDelegate> deleteImageDelegate;//保存图片到相册

- (void)setImage:(UIImage *)newImage;
- (void)turnOffZoom;

- (CGPoint)pointToCenterAfterRotation;
- (CGFloat)scaleToRestoreAfterRotation;
- (void)setMaxMinZoomScalesForCurrentBounds;
- (void)restoreCenterPoint:(CGPoint)oldCenter scale:(CGFloat)oldScale;


@end
