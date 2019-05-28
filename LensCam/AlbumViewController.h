//
//  AlbumViewController.h
//  LensCam
//
//  Created by 张文洁 on 2018/10/23.
//  Copyright © 2018 JamStudio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BasicViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface AlbumViewController : BasicViewController

@property (nonatomic,strong) UICollectionView *collectionView;
@property (nonatomic,strong) NSMutableArray *imageList;
@property (nonatomic) NSInteger selectCameraIndex;

@end

NS_ASSUME_NONNULL_END
