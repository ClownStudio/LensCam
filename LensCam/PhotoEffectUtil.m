//
//  PhotoEffectUtil.m
//  LensCam
//
//  Created by 张文洁 on 2018/10/31.
//  Copyright © 2018 JamStudio. All rights reserved.
//

#import "PhotoEffectUtil.h"
#import "ThemeManager.h"
#import "GPUImage.h"
#import "PhotoXAcvFilter.h"
#import "HCTestFilter.h"
#import "UIImage+Rotate.h"
#import "SettingModel.h"
#import "FBGlowLabel.h"

@interface PhotoEffectUtil ()

@end

@implementation PhotoEffectUtil{
    UIDeviceOrientation _deviceOrientation;
}

- (UIImage *)getEffectImageWithOriImage:(UIImage *)oriImage andDevice:(UIDeviceOrientation)deviceOrientation{
    UIImage *image = oriImage;
    image = [image fixOrientation];
    _deviceOrientation = deviceOrientation;
    
    ThemeManager *themeManage = [ThemeManager sharedThemeManager];
    NSDictionary *dict = [[themeManage themePlistArray] objectAtIndex:[themeManage themeIndex]];
    NSArray *baseFilters = [dict objectForKey:@"BaseFilters"];
    if ([baseFilters count] > 0) {
        image = [self createBaseFilterWithImage:image andFilters:baseFilters];
    }
    
    NSArray *blendModes = [dict objectForKey:@"BlendMode"];
    NSArray *colors = [dict objectForKey:@"FilterColors"];
    NSArray *filters = [dict objectForKey:@"Filters"];
    if ([filters count] > 0) {
        image = [self createBlendFilterWithImage:image andBlendModes:blendModes andFilters:filters andColors:colors];
    }
    
    NSArray *textures = [dict objectForKey:@"Textures"];
    if ([textures count] > 0) {
        image = [self createBlendTextureWithImage:image andBlendModes:blendModes andTextures:textures];
    }
    
    NSArray *bonders = [dict objectForKey:@"Bonders"];
    if ([bonders count] > 0) {
        image = [self createBonderWithImage:image andBonders:bonders];
    }
    
    NSDictionary *fontProperty = [dict objectForKey:@"FontProperty"];
    if ([[SettingModel sharedInstance] isStamp]) {
        image = [self createFontWithImage:image andFontProperty:fontProperty];
    }
    
    return image;
}

- (UIImage *)createFontWithImage:(UIImage *)image andFontProperty:(NSDictionary *)fontProperty{
    image = [image fixOrientation];
    if([[UIDevice currentDevice] orientation] != _deviceOrientation){
        if (_deviceOrientation == UIDeviceOrientationLandscapeRight) {
            image = [image imageRotatedByDegrees:90];
        }else if (_deviceOrientation == UIDeviceOrientationLandscapeLeft){
            image = [image imageRotatedByDegrees:270];
        }else if (_deviceOrientation == UIDeviceOrientationPortraitUpsideDown){
            image = [image imageRotatedByDegrees:180];
        }
    }
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    FBGlowLabel *label = [[FBGlowLabel alloc] init];
    
    CGFloat value = imageView.frame.size.width > imageView.frame.size.height ? imageView.frame.size.width : imageView.frame.size.height;
    CGFloat base = value/1344;
    
    UIFont *font = [UIFont fontWithName:[fontProperty objectForKey:@"fontName"] size:[[fontProperty objectForKey:@"fontSize"] floatValue] * base];
    if (font == nil) {
        NSLog(@"没找到您配置的字体哦！！！");
        font = [UIFont fontWithName:@"DS-Digital" size:[[fontProperty objectForKey:@"fontSize"] floatValue] * base];
    }
    [label setFont:font];
    //描边
    NSArray *strokes = [[fontProperty objectForKey:@"strokeColor"] componentsSeparatedByString:@","];
    if (strokes!=nil && [strokes count] == 4) {
        label.strokeColor = [UIColor colorWithRed:[strokes[0] floatValue]/255 green:[strokes[1] floatValue]/255 blue:[strokes[2] floatValue]/255 alpha:[strokes[3] floatValue]];
    }else{
        label.strokeColor = [UIColor colorWithRed:0.937 green:0.337 blue:0.157 alpha:0.7];
    }
    
    label.strokeWidth = [[fontProperty objectForKey:@"strokeWidth"] floatValue];
    //发光
    label.layer.shadowRadius = [[fontProperty objectForKey:@"shadowRadius"] floatValue];
    
    NSArray *shadows = [[fontProperty objectForKey:@"shadowColor"] componentsSeparatedByString:@","];
    if (shadows!=nil && [shadows count] == 4) {
        label.layer.shadowColor = [UIColor colorWithRed:[shadows[0] floatValue]/255 green:[shadows[1] floatValue]/255 blue:[shadows[2] floatValue]/255 alpha:[shadows[3] floatValue]].CGColor;
    }else{
        label.layer.shadowColor = [UIColor colorWithRed:0.937 green:0.337 blue:0.157 alpha:1].CGColor;
    }
    
    label.layer.shadowOffset = CGSizeFromString([fontProperty objectForKey:@"shadowOffset"]);
    label.layer.shadowOpacity = [[fontProperty objectForKey:@"shadowOpacity"] floatValue];
    
    NSArray *fontColors = [[fontProperty objectForKey:@"fontColor"] componentsSeparatedByString:@","];
    if (fontColors!=nil && [fontColors count] == 4) {
        [label setTextColor:[UIColor colorWithRed:[fontColors[0] floatValue]/255 green:[fontColors[1] floatValue]/255 blue:[fontColors[2] floatValue]/255 alpha:[fontColors[3] floatValue]]];
    }else{
        [label setTextColor:[UIColor colorWithRed:0.937 green:0.337 blue:0.157 alpha:0.7]];
    }
    
    NSMutableString *whiteSpace = [NSMutableString new];
    NSInteger count = [[fontProperty objectForKey:@"distance"] integerValue];
    for (int i = 0; i < count; i++) {
        [whiteSpace appendString:@" "];
    }
    
    if ([[SettingModel sharedInstance] isRandom]) {
        NSString *year = [self getRandomDate:0 to:99];
        NSString *month = [self getRandomDate:1 to:12];
        NSString *day = [self getRandomDate:1 to:31];
        NSMutableString * dateString = [[NSMutableString alloc]initWithString:@"'"];
        [dateString appendString:year];
        [dateString appendString:whiteSpace];
        [dateString appendString:month];
        [dateString appendString:whiteSpace];
        [dateString appendString:day];
        [label setText:dateString];
    }else{
        NSMutableString * dateString = [[NSMutableString alloc] initWithString:[[SettingModel sharedInstance] customDate]];
        NSString *resultDateString = [dateString stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSArray *array = [resultDateString componentsSeparatedByString:@"/"];
        NSMutableString *result = [[NSMutableString alloc] initWithString:@"'"];
        for (int i = 0; i < [array count]; i++) {
            NSString *string = [array objectAtIndex:i];
            if ([string length] > 2) {
                string = [string substringFromIndex:string.length - 2];
            }
            [result appendString:string];
            if (i != [array count] - 1) {
                [result appendString:whiteSpace];
            }
        }
        [label setText:result];
    }
    [imageView addSubview:label];
    
    CGSize size = [label.text sizeWithAttributes:@{NSFontAttributeName: font}];
    CGSize adaptionSize = CGSizeMake(ceilf(size.width), ceilf(size.height));
    CGSize gap = CGSizeFromString([fontProperty objectForKey:@"position"]);
    label.frame = CGRectMake(imageView.frame.size.width - adaptionSize.width - gap.width*base, imageView.frame.size.height - gap.height*base, adaptionSize.width, adaptionSize.height);
    UIImage *resultImage = [self convertViewToImage:imageView andScale:image.scale];
    return resultImage;
}

-(NSString *)getRandomDate:(int)from to:(int)to
{
    int randomNum = (int)(from + (arc4random() % (to - from + 1)));
    NSLog(@"随机到的数值：%d",randomNum);
    if (randomNum < 10 && randomNum >= 0) {
        return [NSString stringWithFormat:@"0%d",randomNum];
    }
    return [NSString stringWithFormat:@"%d",randomNum];
}

- (UIImage*)convertViewToImage:(UIView *)view andScale:(CGFloat)scale{
    CGSize size = view.bounds.size;
    // 下面方法，第一个参数表示区域大小。第二个参数表示是否是非透明的。如果需要显示半透明效果，需要传NO，否则传YES。第三个参数就是屏幕密度了。
    UIGraphicsBeginImageContextWithOptions(size, NO, scale);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    UIImage *resultImage = [[UIImage alloc] initWithCGImage:image.CGImage scale:scale orientation:0];
    return resultImage;
}

- (UIImage *)createBonderWithImage:(UIImage *)image andBonders:(NSArray *)bonders{
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    int num = [self getRandomNumber:0 to:(int)([bonders count] - 1)];
    UIImage *bonderImage = [UIImage imageNamed:[bonders objectAtIndex:num]];
    [bonderImage drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    if(newImage){
        image = newImage;
    }
    return image;
}

- (UIImage *)createBaseFilterWithImage:(UIImage *)image andFilters:(NSArray *)filters{
    int num = [self getRandomNumber:0 to:(int)([filters count] - 1)];
    NSString *filterString = [filters objectAtIndex:num];
    if ([filterString hasSuffix:@".png"] || [filterString hasSuffix:@".jpg"]){
        return [self generateImage:image andLutImageName:filterString];
    }
    
    GPUImagePicture *pic = [[GPUImagePicture alloc] initWithImage:image];
    if ([filterString hasSuffix:@".acv"]) {
        PhotoXAcvFilter *acvFilter = [[PhotoXAcvFilter alloc]initWithACVData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:filterString ofType:nil]]];
        [pic addTarget:acvFilter];
        [acvFilter useNextFrameForImageCapture];
        [pic processImage];
        UIImage *newImage = [acvFilter imageFromCurrentFramebuffer];
        if (newImage) {
            return newImage;
        }
    }else{
        GPUImageFilter *outFilter = [[[NSClassFromString(filterString) class] alloc] init];
        [pic addTarget:outFilter];
        [outFilter useNextFrameForImageCapture];
        [pic processImage];
        UIImage *newImage = [outFilter imageFromCurrentFramebuffer];
        if(newImage){
            return newImage;
        }
    }
    
    return image;
}

- (UIImage *)createBlendFilterWithImage:(UIImage *)image andBlendModes:(NSArray *)modes andFilters:(NSArray *)filters andColors:(NSArray *)colors{
    int num = [self getRandomNumber:0 to:(int)([filters count] - 1)];
    NSString *filterString = [filters objectAtIndex:num];
    
    if ([filterString hasSuffix:@".png"] || [filterString hasSuffix:@".jpg"]){
        return [self generateImage:image andLutImageName:filterString];
    }
    GPUImagePicture *pic = [[GPUImagePicture alloc] initWithImage:image];
    
    if ([modes count] > 0) {
        int blendNum = [self getRandomNumber:0 to:(int)([modes count] - 1)];
        NSString *blendString = [modes objectAtIndex:blendNum];
        
        UIColor *color = [UIColor whiteColor];
        if ([colors count] >0) {
            int colorNum = [self getRandomNumber:0 to:(int)([colors count] - 1)];
            NSString *colorStr = [colors objectAtIndex:colorNum];
            NSArray *fontColors = [colorStr componentsSeparatedByString:@","];
            if (fontColors!=nil && [fontColors count] == 4) {
                color = [UIColor colorWithRed:[fontColors[0] floatValue]/255 green:[fontColors[1] floatValue]/255 blue:[fontColors[2] floatValue]/255 alpha:[fontColors[3] floatValue]];
            }
        }
        
        UIView *colorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
        [colorView setBackgroundColor:color];
        UIImage *filterColorImage = [self convertViewToImage:colorView andScale:image.scale];
        GPUImagePicture *overImageSource = [[GPUImagePicture alloc] initWithImage:filterColorImage];
        
        GPUImageFilter *blendFilter = [[[NSClassFromString(blendString) class] alloc] init];
        
        if ([filterString hasSuffix:@".acv"]) {
            PhotoXAcvFilter *acvFilter = [[PhotoXAcvFilter alloc]initWithACVData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:filterString ofType:nil]]];
            [overImageSource addTarget:acvFilter];
            [acvFilter useNextFrameForImageCapture];
            [overImageSource processImage];
            
            [pic addTarget:blendFilter atTextureLocation:0];
            [overImageSource addTarget:blendFilter atTextureLocation:1];
            [blendFilter useNextFrameForImageCapture];
            [pic processImage];
            image = [blendFilter imageFromCurrentFramebuffer];
        }else{
            GPUImageFilter *outFilter = [[[NSClassFromString(filterString) class] alloc] init];
            
            [overImageSource addTarget:outFilter];
            [outFilter useNextFrameForImageCapture];
            [overImageSource processImage];
            
            [pic addTarget:blendFilter atTextureLocation:0];
            [overImageSource addTarget:blendFilter atTextureLocation:1];
            [blendFilter useNextFrameForImageCapture];
            [pic processImage];
            image = [blendFilter imageFromCurrentFramebuffer];
        }
        return image;
    }else{
        if ([filterString hasSuffix:@".acv"]) {
            PhotoXAcvFilter *acvFilter = [[PhotoXAcvFilter alloc]initWithACVData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:filterString ofType:nil]]];
            [pic addTarget:acvFilter];
            [acvFilter useNextFrameForImageCapture];
            [pic processImage];
            UIImage *newImage = [acvFilter imageFromCurrentFramebuffer];
            if (newImage) {
                return newImage;
            }
        }else{
            GPUImageFilter *outFilter = [[[NSClassFromString(filterString) class] alloc] init];
            [pic addTarget:outFilter];
            [outFilter useNextFrameForImageCapture];
            [pic processImage];
            UIImage *newImage = [outFilter imageFromCurrentFramebuffer];
            if(newImage){
                return newImage;
            }
        }
    }
    
    return image;
}

- (UIImage *)createBlendTextureWithImage:(UIImage *)image andBlendModes:(NSArray *)modes andTextures:(NSArray *)textures{
    GPUImagePicture *pic = [[GPUImagePicture alloc] initWithImage:image];
    
    if ([modes count] > 0) {
        int blendNum = [self getRandomNumber:0 to:(int)([modes count] - 1)];
        NSString *blendString = [modes objectAtIndex:blendNum];
        GPUImageFilter *blendFilter = [[[NSClassFromString(blendString) class] alloc] init];
        [pic addTarget:blendFilter atTextureLocation:0];
        
        int num = [self getRandomNumber:0 to:(int)([textures count] - 1)];
        UIImage *textureImage = [UIImage imageNamed:[textures objectAtIndex:num]];
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(image.size.width, image.size.height), NO, image.scale);
        [textureImage drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
        UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        GPUImagePicture *overImageSource = [[GPUImagePicture alloc] initWithImage:resultImage];
        
        [pic addTarget:blendFilter atTextureLocation:0];
        [overImageSource addTarget:blendFilter atTextureLocation:1];
        [blendFilter useNextFrameForImageCapture];
        
        [pic processImage];
        [overImageSource processImage];
        
        UIImage *newImage = [blendFilter imageFromCurrentFramebuffer];
        
        if (newImage) {
            return newImage;
        }
    }else{
        int num = [self getRandomNumber:0 to:(int)([textures count] - 1)];
        UIImage *textureImage = [UIImage imageNamed:[textures objectAtIndex:num]];
        HCTestFilter *texture = [[HCTestFilter alloc] initWithTextureImage:textureImage];
        [pic addTarget:texture];
        [texture useNextFrameForImageCapture];
        [pic processImage];
        UIImage *newImage = [texture imageFromCurrentFramebuffer];
        
        if (newImage) {
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(newImage.size.width, newImage.size.height), NO, newImage.scale);
            [image drawInRect:CGRectMake(0, 0, newImage.size.width, newImage.size.height)];
            [newImage drawInRect:CGRectMake(0, 0, newImage.size.width, newImage.size.height) blendMode:kCGBlendModePlusLighter alpha:1.0];
            UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            return resultImage;
        }
    }
    
    return image;
}

-(int)getRandomNumber:(int)from to:(int)to{
    int randomNum = (int)(from + (arc4random() % (to - from + 1)));
    return randomNum;
}

- (UIImage *)generateImage:(UIImage *)inputImage andLutImageName:(NSString *)imageName
{
    UIImage *outputImage;
    GPUImagePicture *stillImageSource = [[GPUImagePicture alloc] initWithImage:inputImage];
    //添加滤镜
    GPUImageLookupFilter *lookUpFilter = [[GPUImageLookupFilter alloc] init];
    GPUImagePicture *lookupImg = [[GPUImagePicture alloc] initWithImage:[UIImage imageNamed:imageName]];
    [lookupImg addTarget:lookUpFilter atTextureLocation:1];
    [stillImageSource addTarget:lookUpFilter atTextureLocation:0];
    [lookUpFilter useNextFrameForImageCapture];
    if([lookupImg processImageWithCompletionHandler:nil] && [stillImageSource processImageWithCompletionHandler:nil]) {
        outputImage = [lookUpFilter imageFromCurrentFramebuffer];
    }
    return outputImage;
}

@end
