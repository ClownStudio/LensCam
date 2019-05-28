//
//  SettingView.h
//  FTCamera
//
//  Created by 张文洁 on 2018/7/30.
//  Copyright © 2018年 JamStudio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LYSDatePicker.h"

@interface SettingView : UIView <LYSDatePickerDelegate,LYSDatePickerDataSource>

@property (nonatomic, strong) IBOutlet UIButton *closeBtn;
@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;

@property (nonatomic, strong) IBOutlet UIButton *restoreBtn;
@property (nonatomic, strong) IBOutlet UISwitch *autoSaveBtn;
@property (nonatomic, strong) IBOutlet UISwitch *dateStampBtn;
@property (nonatomic, strong) IBOutlet UISwitch *randomDateBtn;
@property (nonatomic, strong) IBOutlet UIButton *customDateBtn;
@property (nonatomic, strong) IBOutlet UISwitch *soundBtn;
@property (nonatomic, strong) IBOutlet UIButton *rateBtn;
@property (nonatomic, strong) IBOutlet UIButton *websiteBtn;
@property (nonatomic, strong) IBOutlet UIButton *feedbackBtn;

@end
