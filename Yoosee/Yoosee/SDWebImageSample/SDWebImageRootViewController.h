//
//  SDWebImageRootViewController.h
//  Sample
//
//  Created by Kirby Turner on 3/18/10.
//  Copyright 2010 White Peak Software Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KTThumbsViewController.h"

@class SDWebImageDataSource;
#define ALERT_TAG_CLEAR 0

@interface SDWebImageRootViewController : KTThumbsViewController 
{
@private
   SDWebImageDataSource *images_;
   UIActivityIndicatorView *activityIndicatorView_;
   UIWindow *window_;
}

@property (strong, nonatomic) UIBarButtonItem *btn_right;
@property (strong, nonatomic) UIBarButtonItem *negativeSpacer;

@end
