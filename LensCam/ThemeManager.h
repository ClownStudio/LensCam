//
//  ThemeManager.h
//  LensCam
//
//  Created by 张文洁 on 2018/10/17.
//  Copyright © 2018年 JamStudio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ThemeManager : NSObject

@property (nonatomic) NSInteger themeIndex;           // 主题
@property (nonatomic, retain) NSArray * themePlistArray;    // 主题属性列表字典

+ (ThemeManager *) sharedThemeManager;
- (NSString *)themePath;
- (UIImage *)themeImageWithName:(NSString *)imageName;
- (CGFloat)getViewPortScale;

@end

NS_ASSUME_NONNULL_END
