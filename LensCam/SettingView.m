//
//  SettingView.m
//  FTCamera
//
//  Created by 张文洁 on 2018/7/30.
//  Copyright © 2018年 JamStudio. All rights reserved.
//

#import "SettingView.h"
#import "SettingModel.h"
#import "Macro.h"
#import <MessageUI/MessageUI.h>
#import "BasicViewController.h"
#import "Macro.h"
#import <MBProgressHUD+JDragon.h>
#import "ProManager.h"

@implementation SettingView{
    LYSDatePicker *_pickerView;
}

-(void)layoutSubviews{
    [self.autoSaveBtn setOn:[[SettingModel sharedInstance] isAutoSave]];
    [self.dateStampBtn setOn:[[SettingModel sharedInstance] isStamp]];
    [self.randomDateBtn setOn:[[SettingModel sharedInstance] isRandom]];
    [self.customDateBtn setTitle:[[SettingModel sharedInstance] customDate] forState:UIControlStateNormal];
    [self.soundBtn setOn:[[SettingModel sharedInstance] isSound]];
    
    [self.scrollView setContentSize:CGSizeMake(0, 650)];
}

- (IBAction)onClose:(id)sender{
    [[NSNotificationCenter defaultCenter] postNotificationName:HIDE_SETTING_ANIMATION object:nil];
}

-(IBAction)onAutoSave:(id)sender{
    if([@"1" isEqualToString:ALLOW_AD] &&[ProManager isProductPaid:AD_PRODUCT_ID] == NO){
        [self.autoSaveBtn setOn:NO];
        [[NSNotificationCenter defaultCenter] postNotificationName:PAY_AD_PRODUCT object:nil];
        return;
    }
    [self.autoSaveBtn setOn:!self.autoSaveBtn.isOn];
    [[SettingModel sharedInstance] setIsAutoSave:self.autoSaveBtn.isOn];
}

- (IBAction)onAddStamp:(id)sender{
    [self.dateStampBtn setOn:!self.dateStampBtn.isOn];
    [[SettingModel sharedInstance] setIsStamp:self.dateStampBtn.isOn];
}

- (IBAction)onRadom:(id)sender{
    [self.randomDateBtn setOn:!self.randomDateBtn.isOn];
    [[SettingModel sharedInstance] setIsRandom:self.randomDateBtn.isOn];
}

- (IBAction)onSound:(id)sender{
    [self.soundBtn setOn:!self.soundBtn.isOn];
    [[SettingModel sharedInstance] setIsSound:self.soundBtn.isOn];
}

- (IBAction)onCustomDate:(id)sender{
    LYSDateHeaderBarItem *commitItem = [[LYSDateHeaderBarItem alloc] initWithTitle:NSLocalizedString(@"OK", nil) target:self action:@selector(commitAction:)];
    
    commitItem.tintColor = [UIColor whiteColor];
    
    LYSDateHeaderBar *headerBar = [[LYSDateHeaderBar alloc] init];
    headerBar.rightBarItem = commitItem;
    headerBar.titleColor = [UIColor whiteColor];
    
    _pickerView = [[LYSDatePicker alloc] initWithFrame:CGRectMake(0, HEIGHT - 256, CGRectGetWidth(self.frame), 256) type:(LYSDatePickerTypeCustom)];
    _pickerView.datePickerMode = LYSDatePickerModeYearAndDate;
    _pickerView.date = [NSDate date];
    _pickerView.headerView.headerBar = headerBar;
    _pickerView.delegate = self;
    _pickerView.dataSource = self;
    [self addSubview:_pickerView];
}

- (void)commitAction:(LYSDateHeaderBarItem *)sender
{
    [_pickerView removeFromSuperview];
}

- (void)datePicker:(LYSDatePicker *)pickerView didSelectDate:(NSDate *)date
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyy"];
    NSInteger currentYear=[[formatter stringFromDate:date] integerValue];
    [formatter setDateFormat:@"MM"];
    NSInteger currentMonth=[[formatter stringFromDate:date]integerValue];
    [formatter setDateFormat:@"dd"];
    NSInteger currentDay=[[formatter stringFromDate:date] integerValue];
    NSString *dateString = [NSString stringWithFormat:@"%ld / %ld / %ld",(long)currentYear,(long)currentMonth,(long)currentDay];
    [[SettingModel sharedInstance] setCustomDate:dateString];
    [self.customDateBtn setTitle:[[SettingModel sharedInstance] customDate] forState:UIControlStateNormal];
}

- (IBAction)onRate:(id)sender{
    [self layoutRateAlert];
}

- (void)layoutRateAlert{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tip", nil) message:NSLocalizedString(@"Evaluate", nil) preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0) {
            [self goToAppStore];
        }else{
            NSString *urlStr = [NSString stringWithFormat:@"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@&pageNumber=0&sortOrdering=2&mt=8", APP_ID];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlStr]];
        }
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    UIViewController *viewController = [self viewControllerSupportView:self];
    [viewController presentViewController:alertController animated:YES completion:nil];
}

-(void)goToAppStore{
    NSString *itunesurl = [NSString stringWithFormat:@"itms-apps://itunes.apple.com/cn/app/id%@?mt=8&action=write-review",APP_ID];;
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:itunesurl]];
}

- (IBAction)onRestore:(id)sender{
    UIViewController *viewController = [self viewControllerSupportView:self];
    if (viewController) {
        if ([viewController respondsToSelector:@selector(onRestore)]) {
            [(BasicViewController *)viewController onRestore];
        }else{
            [MBProgressHUD showErrorMessage:NSLocalizedString(@"RestoreError", nil)];
        }
    }else{
        [MBProgressHUD showErrorMessage:NSLocalizedString(@"RestoreError", nil)];
    }
}

- (IBAction)onFeedback:(id)sender{
    UIViewController *viewController = [self viewControllerSupportView:self];
    if (viewController) {
        if ([viewController respondsToSelector:@selector(onFeedback)]) {
            [(BasicViewController *)viewController onFeedback];
        }else{
            [MBProgressHUD showErrorMessage:NSLocalizedString(@"FeedbackError", nil)];
        }
    }else{
        [MBProgressHUD showErrorMessage:NSLocalizedString(@"FeedbackError", nil)];
    }
}

- (UIViewController *)viewControllerSupportView:(UIView *)view {
    for (UIView* next = [view superview]; next; next = next.superview) {
        UIResponder *nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)nextResponder;
        }
    }
    return nil;
}

- (IBAction)onFollow:(id)sender{
    NSString *urlText = [NSString stringWithFormat:@"https://www.instagram.com"];
    [[UIApplication sharedApplication]openURL:[NSURL URLWithString:urlText]];
}

@end
