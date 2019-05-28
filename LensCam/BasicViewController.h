//
//  BasicViewController.h
//  FTCamera
//
//  Created by 张文洁 on 2018/8/2.
//  Copyright © 2018年 JamStudio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProManager.h"

@interface BasicViewController : UIViewController <ProManagerDelegate>

@property (nonatomic, strong) ProManager *proManager;

- (void)onFeedback;
- (void)onRestore;

@end
