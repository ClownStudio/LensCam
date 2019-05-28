//
//  PhotoListCollectionViewCell.h
//  LensCam
//
//  Created by 张文洁 on 2018/11/6.
//  Copyright © 2018 JamStudio. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^DeletePhotoBlock) (NSInteger index);

@interface PhotoListCollectionViewCell : UICollectionViewCell

@property (nonatomic,strong) UIImageView *imageView;
@property (nonatomic,copy) DeletePhotoBlock deleteBlock;

- (void)setImageWithImages:(NSArray *)images andIndex:(NSInteger)index andIsEdit:(BOOL)isEdit;

@end

NS_ASSUME_NONNULL_END
