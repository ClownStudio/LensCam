//
//  BasicViewController.m
//  FTCamera
//
//  Created by 张文洁 on 2018/8/2.
//  Copyright © 2018年 JamStudio. All rights reserved.
//

#import "BasicViewController.h"
#import <MessageUI/MessageUI.h>
#import <MBProgressHUD+JDragon.h>
#import "Macro.h"
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface BasicViewController () <MFMailComposeViewControllerDelegate,GADInterstitialDelegate>

@end

@implementation BasicViewController{
    GADInterstitial *_interstitial;
    NSTimer *_timer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.proManager = [[ProManager alloc] init];
    self.proManager.delegate = self;
}

- (void)startAd{
    if ([_interstitial isReady] == NO) {
        _interstitial = [self createAndLoadInterstitial];
    }
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:CameraShowAdTime target:self selector:@selector(showInterstitialAds) userInfo:nil repeats:YES];
}


- (GADInterstitial *)createAndLoadInterstitial{
    GADInterstitial *interstitial = [[GADInterstitial alloc] initWithAdUnitID:AD_INTERSTITIAL_ID];
    interstitial.delegate = self;
    [interstitial loadRequest:[GADRequest request]];
    return interstitial;
}

- (void)interstitialDidDismissScreen:(GADInterstitial *)ad{
    _interstitial = [self createAndLoadInterstitial];
}

- (void)showInterstitialAds{
    NSLog(@"计时器");
    if ([_interstitial isReady] && [ProManager isProductPaid:AD_PRODUCT_ID] == NO && [ProManager isFullPaid] == NO) {
        [_interstitial presentFromRootViewController:self];
    }
}

- (void)onFeedback{
    if ([MFMailComposeViewController canSendMail]) { // 用户已设置邮件账户
        
    }else{
        [MBProgressHUD showErrorMessage:NSLocalizedString(@"NoMailAccount", nil)];
        return;
    }
    if ([MFMessageComposeViewController canSendText] == YES) {
        MFMailComposeViewController *mailCompose = [[MFMailComposeViewController alloc]init];
        mailCompose.mailComposeDelegate = self;
        [mailCompose setSubject:@""];
        NSArray *arr = @[@"samline228@yahoo.com"];
        //收件人
        [mailCompose setToRecipients:arr];
        [self presentViewController:mailCompose animated:YES completion:nil];
    }else{
        [MBProgressHUD showErrorMessage:NSLocalizedString(@"NoSupportMail", nil)];
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(nullable NSError *)error{
    if (result) {
        NSLog(@"Result : %ld",(long)result);
    }
    if (error) {
        NSLog(@"Error : %@",error);
    }
    switch (result)
    {
        case MFMailComposeResultCancelled: // 用户取消编辑
            NSLog(@"Mail send canceled...");
            break;
        case MFMailComposeResultSaved: // 用户保存邮件
            NSLog(@"Mail saved...");
            break;
        case MFMailComposeResultSent: // 用户点击发送
            NSLog(@"Mail sent...");
            break;
        case MFMailComposeResultFailed: // 用户尝试保存或发送邮件失败
            NSLog(@"Mail send errored: %@...", [error localizedDescription]);
            break;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onRestore{
    [MBProgressHUD showActivityMessageInView:NSLocalizedString(@"Loading", nil)];
    [self.proManager restorePro];
}

-(void)didSuccessBuyProduct:(NSString*)productId
{
    [MBProgressHUD hideHUD];
    [MBProgressHUD showSuccessMessage:NSLocalizedString(@"PurchaseSuccess", nil)];
}

-(void)didSuccessRestoreProducts:(NSArray*)productIds
{
    [MBProgressHUD hideHUD];
    if ([ProManager isFullPaid])
    {
        //全解锁
        [MBProgressHUD showSuccessMessage:NSLocalizedString(@"RestoreSuccess", nil)];
        return ;
    }
    
    //未买过，进行支付
    [self.proManager buyProduct:kProDeluxeId];
}

-(void)didFailRestore:(NSString *)reason
{
    [MBProgressHUD hideHUD];
    [self.proManager buyProduct:kProDeluxeId];
}

-(void)didFailedBuyProduct:(NSString*)productId forReason:(NSString*)reason
{
    [MBProgressHUD hideHUD];
    [MBProgressHUD showErrorMessage:reason];
}

-(void)didCancelBuyProduct:(NSString*)productId
{
    [MBProgressHUD hideHUD];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (self.proManager) {
        self.proManager.delegate = self;
    }
    
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    if ([ProManager isFullPaid] == NO && [ProManager isProductPaid:AD_PRODUCT_ID] == NO && [@"1" isEqualToString:ALLOW_AD]) {
        [self startAd];
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
}

@end
