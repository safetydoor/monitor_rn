//
//  SDWebImageRootViewController.m
//  Sample
//

#import "SDWebImageRootViewController.h"
#import "SDWebImageDataSource.h"
#import "AppDelegate.h"
#import "UDManager.h"
#import "LoginResult.h"
#import "Toast+UIView.h"
#import "TopBar.h"

@interface SDWebImageRootViewController ()
- (void)showActivityIndicator;
- (void)hideActivityIndicator;
@end

@implementation SDWebImageRootViewController

- (void)dealloc 
{
   [activityIndicatorView_ release], activityIndicatorView_ = nil;
   [images_ release], images_ = nil;
    [self.btn_right release];
    [self.negativeSpacer release];
   [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setBackgroundColor:XBgColor];
    
    self.navigationItem.title = NSLocalizedString(@"screenshot", nil);
    
    //rightBarButtonItem
    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    rightButton.frame = CGRectMake(10.0, 0.0, 60.0, 34.0);
    
    UIImage *rightButtonImg = [UIImage imageNamed:@"bg_bar_btn.png"];
    rightButtonImg = [rightButtonImg stretchableImageWithLeftCapWidth:rightButtonImg.size.width*0.5 topCapHeight:rightButtonImg.size.height*0.5];
    
    UIImage *rightButtonImg_p = [UIImage imageNamed:@"bg_bar_btn_p.png"];
    rightButtonImg_p = [rightButtonImg_p stretchableImageWithLeftCapWidth:rightButtonImg_p.size.width*0.5 topCapHeight:rightButtonImg_p.size.height*0.5];
    
    [rightButton setBackgroundImage:rightButtonImg forState:UIControlStateNormal];
    [rightButton setBackgroundImage:rightButtonImg_p forState:UIControlStateHighlighted];;
    
    UIImageView *rightButtonIconView = [[UIImageView alloc]initWithFrame:CGRectMake((rightButton.frame.size.width-rightButton.frame.size.height)/2, 0, rightButton.frame.size.height, rightButton.frame.size.height)];
    rightButtonIconView.image = [UIImage imageNamed:@"ic_bar_btn_clear.png"];
    [rightButton addSubview:rightButtonIconView];
    
    [rightButtonIconView release];
    
    [rightButton addTarget:self action:@selector(onRightButtonPress) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *btn_right  = [[UIBarButtonItem alloc] initWithCustomView:rightButton];
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                       target:nil action:nil];
    /**
     *  width为负数时，相当于btn向右移动width数值个像素，由于按钮本身和边界间距为5pix，所以width设为-5时，间距正好调整
     *  为0；width为正数时，正好相反，相当于往左移动width数值个像素
     */
    if([UIDevice currentDevice].systemVersion.floatValue < 7.0){
        negativeSpacer.width = -0.0;
    }else{
        negativeSpacer.width = -11.0;
    }
    self.btn_right = btn_right;
    self.negativeSpacer = negativeSpacer;
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:negativeSpacer, btn_right, nil];
    [btn_right release];
    
    //back按钮
    if ([[AppDelegate sharedDefault]dwApContactID] != 0) {
        //rightBarButtonItem
        UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
        leftButton.frame = CGRectMake(10.0, 0.0, 60.0, 34.0);
        
        UIImage *leftButtonImg = [UIImage imageNamed:@"bg_bar_btn.png"];
        leftButtonImg = [leftButtonImg stretchableImageWithLeftCapWidth:leftButtonImg.size.width*0.5 topCapHeight:leftButtonImg.size.height*0.5];
        
        UIImage *leftButtonImg_p = [UIImage imageNamed:@"bg_bar_btn_p.png"];
        leftButtonImg_p = [leftButtonImg_p stretchableImageWithLeftCapWidth:leftButtonImg_p.size.width*0.5 topCapHeight:leftButtonImg_p.size.height*0.5];
        
        [leftButton setBackgroundImage:leftButtonImg forState:UIControlStateNormal];
        [leftButton setBackgroundImage:leftButtonImg_p forState:UIControlStateHighlighted];;
        
        UIImageView *leftButtonIconView = [[UIImageView alloc]initWithFrame:CGRectMake((leftButton.frame.size.width-leftButton.frame.size.height)/2, 0, leftButton.frame.size.height, leftButton.frame.size.height)];
        leftButtonIconView.image = [UIImage imageNamed:@"ic_bar_btn_back.png"];
        [leftButton addSubview:leftButtonIconView];
        
        [leftButtonIconView release];
        
        [leftButton addTarget:self action:@selector(onBackButtonPress) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *btn_left  = [[UIBarButtonItem alloc] initWithCustomView:leftButton];
        UIBarButtonItem *negativeSpacerLeft = [[UIBarButtonItem alloc]
                                           initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                           target:nil action:nil];
        /**
         *  width为负数时，相当于btn向右移动width数值个像素，由于按钮本身和边界间距为5pix，所以width设为-5时，间距正好调整
         *  为0；width为正数时，正好相反，相当于往左移动width数值个像素
         */
        if([UIDevice currentDevice].systemVersion.floatValue < 7.0){
            negativeSpacerLeft.width = -0.0;
        }else{
            negativeSpacerLeft.width = -11.0;
        }
        self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:negativeSpacerLeft, btn_left, nil];
        [btn_left release];
    }
    self.navigationController.navigationBarHidden = NO;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    [self.navigationController.navigationBar setAlpha:1.0];
    
    
    if ([[AppDelegate sharedDefault]dwApContactID]) {
        MainController *mainController = [AppDelegate sharedDefault].mainController_ap;
        [mainController setBottomBarHidden:YES];
    }
    else
    {
        MainController *mainController = [AppDelegate sharedDefault].mainController;
        [mainController setBottomBarHidden:NO];
    }
    
    if ([[AppDelegate sharedDefault] dwApContactID]) {
        [images_ release];
        images_ = nil;
        images_ = [[SDWebImageDataSource alloc] init];
        [self setDataSource:images_];//关键代码
        
        if (images_.screenshotPaths.count <= 0) {//没有图片，则隐藏清除按钮
            self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:nil];
        }else{
            self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:self.negativeSpacer, self.btn_right, nil];
        }
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:YES];

    //ap模式和联网模式，图片显示的时机不同。
    if ([[AppDelegate sharedDefault] dwApContactID] == 0)
    {
        //浏览图片返回 和 点击tabBar按钮时，都执行
        [images_ release];
        images_ = nil;
        images_ = [[SDWebImageDataSource alloc] init];
        [self setDataSource:images_];//关键代码
        
        if (images_.screenshotPaths.count <= 0) {//没有图片，则隐藏清除按钮
            self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:nil];
        }else{
            self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:self.negativeSpacer, self.btn_right, nil];
        }
    }
}



-(void)onRightButtonPress{
    UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"sure_to_clear", nil) message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:NSLocalizedString(@"ok", nil),nil];
    deleteAlert.tag = ALERT_TAG_CLEAR;
    [deleteAlert show];
    [deleteAlert release];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch(alertView.tag){
        case ALERT_TAG_CLEAR:
        {
            if(buttonIndex==1){
                NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                NSString *filePath = nil;
                
                int  dwApContactID = [[AppDelegate sharedDefault] dwApContactID];
                if (dwApContactID == 0) {
                    LoginResult *loginResult = [UDManager getLoginInfo];
                    filePath = [NSString stringWithFormat:@"%@/screenshot/%@",rootPath,loginResult.contactId];
                }
                else
                {
                    filePath = [NSString stringWithFormat:@"%@/screenshot/ap/%d",rootPath,dwApContactID];
                }
                
                
                NSFileManager *manager = [NSFileManager defaultManager];
                NSError *error;
                
                [manager removeItemAtPath:filePath error:&error];
                if(error){
                    //DLog(@"%@",error);
                }
                
                //[self.screenshotFiles removeAllObjects];
                //浏览图片返回 和 点击tabBar按钮时，都执行
                [images_ release];
                images_ = nil;
                images_ = [[SDWebImageDataSource alloc] init];
                [self setDataSource:images_];//关键代码
                
                if (images_.screenshotPaths.count <= 0) {//没有图片，则隐藏清除按钮
                    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:nil];
                }
                
                [self.view makeToast:NSLocalizedString(@"operator_success", nil)];
                
                
            }
        }
            break;
    }
}

- (void)didReceiveMemoryWarning 
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload 
{
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)willLoadThumbs 
{
   [self showActivityIndicator];
}

- (void)didLoadThumbs 
{
   [self hideActivityIndicator];
}


#pragma mark -
#pragma mark Activity Indicator

- (UIActivityIndicatorView *)activityIndicator 
{
   if (activityIndicatorView_) {
      return activityIndicatorView_;
   }

   activityIndicatorView_ = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
   CGPoint center = [[self view] center];
   [activityIndicatorView_ setCenter:center];
   [activityIndicatorView_ setHidesWhenStopped:YES];
   [activityIndicatorView_ startAnimating];
   [[self view] addSubview:activityIndicatorView_];
   
   return activityIndicatorView_;
}

- (void)showActivityIndicator 
{
   [[self activityIndicator] startAnimating];
}

- (void)hideActivityIndicator 
{
   [[self activityIndicator] stopAnimating];
}


//-(BOOL)shouldAutorotate{
//    return YES;
//}
//
//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interface {
//    return (interface == UIInterfaceOrientationPortrait );
//}
//
//#ifdef IOS6
//
//- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
//{
//    return UIInterfaceOrientationPortrait;
//}
//
//- (BOOL)shouldAutorotate {
//    return NO;
//}
//
//- (NSUInteger)supportedInterfaceOrientations {
//    return UIInterfaceOrientationMaskPortrait;
//}
//#endif
//
//-(NSUInteger)supportedInterfaceOrientations{
//    return UIInterfaceOrientationMaskPortrait;
//}
//
//-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
//    return UIInterfaceOrientationPortrait;
//}
-(void)onBackButtonPress{
    if ([[AppDelegate sharedDefault] dwApContactID] != 0) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}
@end
