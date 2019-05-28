//
//  ThemeManager.m
//  LensCam
//
//  Created by 张文洁 on 2018/10/17.
//  Copyright © 2018年 JamStudio. All rights reserved.
//

#import "ThemeManager.h"

static ThemeManager * sharedThemeManager;

@implementation ThemeManager

- (id) init {
    if(self = [super init]) {
        NSString * themePath = [[NSBundle mainBundle] pathForResource:@"LCTheme" ofType:@"plist"];
        self.themePlistArray = [NSArray arrayWithContentsOfFile:themePath];
        self.themeIndex = 0;
    }
    
    return self;
}

+ (ThemeManager *) sharedThemeManager {
    @synchronized(self) {
        if (nil == sharedThemeManager) {
            sharedThemeManager = [[ThemeManager alloc] init];
        }
    }
    
    return sharedThemeManager;
}

// Override 重写themeName的set方法
- (void) setThemeIndex:(NSInteger)themeIndex {
    _themeIndex = themeIndex;
}

- (CGFloat )getViewPortScale{
    CGFloat scale = [[[self.themePlistArray objectAtIndex:self.themeIndex] objectForKey:@"Scale"] floatValue];
    if (scale <= 0) {
        scale = 1;
    }
    return scale;
}

- (UIImage *) themeImageWithName:(NSString *)imageName {
    if (imageName == nil) {
        return nil;
    }
    
    NSString * themePath = [self themePath];
    NSString * themeImagePath = [themePath stringByAppendingPathComponent:imageName];
    UIImage * themeImage = [UIImage imageWithContentsOfFile:themeImagePath];
    
    return themeImage;
}

// 返回主题路径
- (NSString *)themePath {
    NSString * resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString * themeSubPath = [[self.themePlistArray objectAtIndex:self.themeIndex] objectForKey:@"Path"];
    NSString * themeFilePath = [resourcePath stringByAppendingPathComponent:themeSubPath];
    
    return themeFilePath;
}

@end
