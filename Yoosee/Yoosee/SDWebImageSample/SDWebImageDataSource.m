//
//  SDWebImageDataSource.m
//  Sample
//

#import "SDWebImageDataSource.h"
#import "KTPhotoView+SDWebImage.h"
#import "KTThumbView+SDWebImage.h"
#import "AppDelegate.h"
#import "UDManager.h"
#import "LoginResult.h"
#import "Utils.h"

#define FULL_SIZE_INDEX 0
#define THUMBNAIL_INDEX 1

@implementation SDWebImageDataSource

- (void)dealloc {
   [super dealloc];
}

- (id)init {
   self = [super init];
   if (self) {
       
       //remove imagePaths
       [self.screenshotPaths removeAllObjects];
       //image files
       NSArray *datas = [NSArray arrayWithArray:[Utils getScreenshotFiles]];
       
       self.screenshotPaths = [NSMutableArray arrayWithCapacity:0];
       for (NSString *imageName in datas) {
           NSString *imagePath = [Utils getScreenshotFilePathWithName:imageName];
           [self.screenshotPaths addObject:imagePath];
       }
   }
   return self;
}


#pragma mark -
#pragma mark KTPhotoBrowserDataSource

- (void)deleteImageAtIndex:(NSInteger)index{//保存图片到相册
    //首先，先删除手机本地的图片
    NSFileManager *manager = [NSFileManager defaultManager];
    NSError *error;
    NSString *imagePath = [self.screenshotPaths objectAtIndex:index];
    [manager removeItemAtPath:imagePath error:&error];
    if(error){
        //DLog(@"%@",error);
    }
    
    //再删除资源图片数组
    [self.screenshotPaths removeObjectAtIndex:index];
}

- (NSInteger)numberOfPhotos {
    NSInteger count = [self.screenshotPaths count];
   return count;
}

//selected image
- (void)imageAtIndex:(NSInteger)index photoView:(KTPhotoView *)photoView {
    
    NSString *imagePath = [self.screenshotPaths objectAtIndex:index];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    [photoView setImage:image];
    
    if ([[AppDelegate sharedDefault]dwApContactID] == 0) {
        MainController *mainController = [AppDelegate sharedDefault].mainController;
        [mainController setBottomBarHidden:YES];
    }
    else
    {
        MainController *mainController = [AppDelegate sharedDefault].mainController_ap;
        [mainController setBottomBarHidden:YES];
    }
}

//KTThumbView(UIButton) is small image in SDWebImageRootViewController
//KTThumbView is created in KTThumbsViewController(SDWebImageRootViewController)
//KTThumbView'frame is setted in KTThumbsView(UIScrollView)
//KTThumbView is also showed in KTThumbsView(UIScrollView)

//KTThumbsView(UIScrollView) is created in KTThumbsViewController
//KTThumbsView'frame is setted in
- (void)thumbImageAtIndex:(NSInteger)index thumbView:(KTThumbView *)thumbView {
    
    NSString *imagePath = [self.screenshotPaths objectAtIndex:index];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    [thumbView setThumbImage:image];
}

@end
