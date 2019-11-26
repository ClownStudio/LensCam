//
//  Macro.h
//  LensCam
//
//  Created by 张文洁 on 2018/10/17.
//  Copyright © 2018年 JamStudio. All rights reserved.
//

#ifndef Macro_h
#define Macro_h

#define WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define HEIGHT ([[UIScreen mainScreen] bounds].size.height)

#define APP_ID @"1039766045"

#define kStoreProductKey [NSString stringWithFormat:@"storeProduct%@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]]

#define ALL_PRODUCT_ID [NSString stringWithFormat:@"%@.pro",[[NSBundle mainBundle] bundleIdentifier]]

#define HIDE_SETTING_ANIMATION @"HIDE_SETTING_ANIMATION"

#define PAY_AD_PRODUCT @"PAY_AD_PRODUCT"

#define kLastImage @"kLastImage"

#define Is_iPad (UI_USER_INTERFACE_IDIOM()== UIUserInterfaceIdiomPad)
#define Is_iPhoneX ([UIScreen mainScreen].bounds.size.height == 812 || [UIScreen mainScreen].bounds.size.height == 896)

//是否允许小图广告 1为允许 其余为不允许
#define ALLOW_AD @"1"

#define ALLOW_BIG_VIEWPORT @"1"

//广告产品id
#define AD_PRODUCT_ID @"com.appstudio.X2.ad"

//应⽤程式ID
#define AD_APP_ID @"ca-app-pub-3553919144267977~5799280260"
//插⻚广告ID
#define AD_INTERSTITIAL_ID @"ca-app-pub-3553919144267977/7659156843"
//横幅广告ID
#define AD_BANNER_ID @"ca-app-pub-3553919144267977/1668463564"
//奖励广告ID
#define AWARD_VIDEO_ID @"ca-app-pub-3553919144267977/8358952851"

//广告展示时间间隔（秒）
#define CameraShowAdTime 20

#endif /* Macro_h */
