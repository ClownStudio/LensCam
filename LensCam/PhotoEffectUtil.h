//
//  PhotoEffectUtil.h
//  LensCam
//
//  Created by 张文洁 on 2018/10/31.
//  Copyright © 2018 JamStudio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PhotoEffectUtil : NSObject

- (UIImage *)getEffectImageWithOriImage:(UIImage *)oriImage andDevice:(UIDeviceOrientation)deviceOrientation;

@end

NS_ASSUME_NONNULL_END
