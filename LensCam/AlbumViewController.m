//
//  AlbumViewController.m
//  LensCam
//
//  Created by 张文洁 on 2018/10/23.
//  Copyright © 2018 JamStudio. All rights reserved.
//

#import "AlbumViewController.h"
#import "Macro.h"
#import "ThemeManager.h"
#import "PhotoListCollectionViewCell.h"
#import <BLImagePickerViewController.h>
#import <MBProgressHUD+JDragon.h>
#import "PhotoEffectUtil.h"
#import "SettingModel.h"
#import "UIImage+Rotate.h"
#import "YJJsonKit.h"
#import "LargePhotoCollectionViewCell.h"
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface AlbumViewController () <UICollectionViewDelegate,UICollectionViewDataSource>

@end

@implementation AlbumViewController{
    UIButton *_backBtn;
    BOOL _isEdit;
    UIImageView *_largeBackGroundView;
    UICollectionView *_largeCollectionView;
    UIButton *_shareBtn;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:backgroundImageView];
    _isEdit = NO;
    CGFloat value = 0;
    if (Is_iPad) {
        [backgroundImageView setImage:[[ThemeManager sharedThemeManager] themeImageWithName:@"album_background_iPad"]];
    }else{
        if (Is_iPhoneX) {
            [backgroundImageView setImage:[[ThemeManager sharedThemeManager] themeImageWithName:@"album_background_iPhoneX"]];
            value = 44;
        }else{
            [backgroundImageView setImage:[[ThemeManager sharedThemeManager] themeImageWithName:@"album_background_iPhone"]];
        }
    }
    
    _backBtn = [[UIButton alloc] initWithFrame:CGRectMake((WIDTH - 60)/2, Is_iPhoneX ? 50:30, 60, 60)];
    [_backBtn setImage:[[ThemeManager sharedThemeManager] themeImageWithName:@"back-camera"] forState:UIControlStateNormal];
    [_backBtn addTarget:self action:@selector(onBack:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_backBtn];
    
    UIButton *albumBtn = [[UIButton alloc] initWithFrame:CGRectMake(_backBtn.frame.origin.x - 50 - 40, Is_iPhoneX ? 60:40, 40, 40)];
    [albumBtn setImage:[[ThemeManager sharedThemeManager] themeImageWithName:@"import"] forState:UIControlStateNormal];
    [albumBtn addTarget:self action:@selector(onAlbum:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:albumBtn];
    
    UIButton *delBtn = [[UIButton alloc] initWithFrame:CGRectMake(_backBtn.frame.origin.x + _backBtn.frame.size.width + 50, Is_iPhoneX ? 60:40, 40, 40)];
    [delBtn setImage:[[ThemeManager sharedThemeManager] themeImageWithName:@"button-delete"] forState:UIControlStateNormal];
    [delBtn addTarget:self action:@selector(onDelete:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:delBtn];
    
    [self initCollectionView];
    
    _largeBackGroundView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    _largeBackGroundView.hidden = YES;
    [_largeBackGroundView setUserInteractionEnabled:YES];
    [self.view addSubview:_largeBackGroundView];
    if (Is_iPad) {
        [_largeBackGroundView setImage:[[ThemeManager sharedThemeManager] themeImageWithName:@"album_background_iPad"]];
    }else{
        if (Is_iPhoneX) {
            [_largeBackGroundView setImage:[[ThemeManager sharedThemeManager] themeImageWithName:@"album_background_iPhoneX"]];
        }else{
            [_largeBackGroundView setImage:[[ThemeManager sharedThemeManager] themeImageWithName:@"album_background_iPhone"]];
        }
    }
    UICollectionViewFlowLayout *largeLayout = [[UICollectionViewFlowLayout alloc] init];
    [largeLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    [largeLayout setItemSize:CGSizeMake(WIDTH * 0.8, WIDTH * 0.8/3*4)];
    [largeLayout setMinimumLineSpacing:0];
    _largeCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, WIDTH * 0.8, WIDTH * 0.8/3*4) collectionViewLayout:largeLayout];
    if (@available(iOS 11.0, *)) {
        _largeCollectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    [_largeCollectionView.layer setMasksToBounds:YES];
    [_largeCollectionView setBackgroundColor:[UIColor clearColor]];
    [_largeCollectionView.layer setCornerRadius:5];
    _largeCollectionView.alwaysBounceVertical = NO;
    [_largeCollectionView setShowsHorizontalScrollIndicator:NO];
    _largeCollectionView.center = CGPointMake(_largeBackGroundView.center.x, _largeBackGroundView.center.y - 60);
    _largeCollectionView.bounces = NO;
    [_largeCollectionView registerClass:[LargePhotoCollectionViewCell class] forCellWithReuseIdentifier:@"LargePhotoCell"];
    [_largeCollectionView setPagingEnabled:YES];
    _largeCollectionView.delegate = self;
    _largeCollectionView.dataSource = self;
    _largeCollectionView.tag = 1;
    [_largeBackGroundView addSubview:_largeCollectionView];
    
    UISwipeGestureRecognizer *recognizer;
    recognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom:)];
    [recognizer setDirection:(UISwipeGestureRecognizerDirectionDown)];
    [_largeBackGroundView addGestureRecognizer:recognizer];
    
    _shareBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
    [_shareBtn setImage:[[ThemeManager sharedThemeManager] themeImageWithName:@"share"] forState:UIControlStateNormal];
    CGRect shareTemp = _shareBtn.frame;
    shareTemp.origin.x = (WIDTH - 60)/2;
    shareTemp.origin.y = _largeCollectionView.frame.origin.y + _largeCollectionView.frame.size.height + 50;
    _shareBtn.frame = shareTemp;
    [_shareBtn addTarget:self action:@selector(onShare:) forControlEvents:UIControlEventTouchUpInside];
    [_largeBackGroundView addSubview:_shareBtn];
}

-(IBAction)onShare:(id)sender{
    if([@"1" isEqualToString:ALLOW_AD] &&[ProManager isProductPaid:AD_PRODUCT_ID] == NO){
        if ([SKPaymentQueue canMakePayments]) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tip", nil) message:NSLocalizedString(@"ShouldPayForAd", nil) preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BuySingle", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self.proManager buyProduct:AD_PRODUCT_ID];
            }];
            UIAlertAction *allAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BuyAll", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                [self.proManager buyProduct:ALL_PRODUCT_ID];
            }];
            
            [alertController addAction:okAction];
            [alertController addAction:allAction];
            [alertController addAction:cancelAction];
            
            [self presentViewController:alertController animated:YES completion:nil];
            NSLog(@"允许程序内付费购买");
        }else{
            NSLog(@"不允许程序内付费购买");
            [MBProgressHUD showErrorMessage:NSLocalizedString(@"NoPermission", nil)];
        }
        return;
    }
    //分享的标题
    NSString *textToShare = NSLocalizedString(@"Share", nil);
    NSInteger index = (NSInteger)(_largeCollectionView.contentOffset.x / (WIDTH * 0.8));
    //分享的图片
    NSString *path_document = NSHomeDirectory();
    NSString *fileName = [_imageList objectAtIndex:index];
    NSString *imagePath = [path_document stringByAppendingString:[NSString stringWithFormat:@"/Documents/%@.jpg",fileName]];
    UIImage *imageToShare = [UIImage imageWithContentsOfFile:imagePath];
    NSArray *activityItems = @[textToShare,imageToShare];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc]initWithActivityItems:activityItems applicationActivities:nil];
    //不出现在活动项目
    activityVC.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeCopyToPasteboard,UIActivityTypeAssignToContact];
    activityVC.popoverPresentationController.sourceView = _shareBtn;
    activityVC.popoverPresentationController.sourceRect = _shareBtn.bounds;
    [self presentViewController:activityVC animated:YES completion:nil];
    // 分享之后的回调
    __weak id weak_self = self;
    activityVC.completionWithItemsHandler = ^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
        
        if (completed) {
            //分享 成功
            if (activityType == UIActivityTypeSaveToCameraRoll) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedString(@"Saved", nil) preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    
                }]];
                
                [weak_self presentViewController:alert animated:YES completion:^{
                    
                }];
            }
        }
    };
}

-(void)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer{
    if(recognizer.direction==UISwipeGestureRecognizerDirectionDown) {
        [UIView animateWithDuration:0.3 animations:^{
            self->_largeBackGroundView.alpha = 0;
        } completion:^(BOOL finished) {
            self->_largeBackGroundView.hidden = YES;
            self->_largeBackGroundView.alpha = 1;
        }];
    }
}

- (void)initCollectionView{
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.minimumLineSpacing = 20;
    layout.minimumInteritemSpacing = 15;
    
    if (Is_iPad) {
        CGFloat itemWidth = (WIDTH * 0.6 - 20)/2;
        CGFloat itemHeight = itemWidth/3*4;
        [layout setItemSize:CGSizeMake(itemWidth, itemHeight)];
        self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(WIDTH * 0.2, _backBtn.frame.origin.y + _backBtn.frame.size.height + 15, WIDTH * 0.6, HEIGHT - _backBtn.frame.origin.y - _backBtn.frame.size.height - 15) collectionViewLayout:layout];
    }else{
        CGFloat itemWidth = (WIDTH * 0.8 - 20)/2;
        CGFloat itemHeight = itemWidth/3*4;
        [layout setItemSize:CGSizeMake(itemWidth, itemHeight)];
        self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(WIDTH * 0.1, _backBtn.frame.origin.y + _backBtn.frame.size.height + 15, WIDTH * 0.8, HEIGHT - _backBtn.frame.origin.y - _backBtn.frame.size.height - 15) collectionViewLayout:layout];
    }
    
    if (@available(iOS 11.0, *)) {
        self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    self.collectionView.showsVerticalScrollIndicator = NO;
    [self.collectionView setBackgroundColor:[UIColor clearColor]];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.view addSubview:self.collectionView];
    
    [self.collectionView registerClass:[PhotoListCollectionViewCell class] forCellWithReuseIdentifier:@"CellId"];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(nonnull NSIndexPath *)indexPath{
    if (collectionView.tag == 0) {
        if (_isEdit == YES) {
            _isEdit = NO;
            [self.collectionView reloadData];
        }
        
        [_largeBackGroundView setHidden:NO];
        [_largeCollectionView setContentOffset:CGPointMake(WIDTH * 0.8 *indexPath.row, 0)];
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [self.imageList count];
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (collectionView.tag == 0) {
        PhotoListCollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"CellId" forIndexPath:indexPath];
        [cell setImageWithImages:self.imageList andIndex:indexPath.row andIsEdit:_isEdit];
        [cell setDeleteBlock:^(NSInteger index) {
            index = index - 1;
            [MBProgressHUD showActivityMessageInWindow:NSLocalizedString(@"Deleting", nil)];
            NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
            NSString *path_document = NSHomeDirectory();
            NSString *fileName = [self.imageList objectAtIndex:index];
            NSString *imagePath = [path_document stringByAppendingString:[NSString stringWithFormat:@"/Documents/%@.png",fileName]];
            NSString *thumbPath = [path_document stringByAppendingString:[NSString stringWithFormat:@"/Documents/%@.jpg",fileName]];
            [self deleteFileWithUrl:imagePath];
            [self deleteFileWithUrl:thumbPath];
            [indexSet addIndex:index];
            [self.imageList removeObjectsAtIndexes:indexSet];
            [self.collectionView reloadData];
            NSString *dataString = [self.imageList objectToJSONString];
            [[NSUserDefaults standardUserDefaults] setObject:dataString forKey:@"ClassicImage_FileName"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [MBProgressHUD hideHUD];
            [MBProgressHUD showSuccessMessage:NSLocalizedString(@"Deleted", nil)];
            [self.collectionView reloadData];
        }];
        return cell;
    }else{
        NSString *path_document = NSHomeDirectory();
        NSString *fileName = [self.imageList objectAtIndex:indexPath.row];
        NSString *imagePath = [path_document stringByAppendingString:[NSString stringWithFormat:@"/Documents/%@.jpg",fileName]];
        static NSString *ID = @"LargePhotoCell";
        LargePhotoCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:ID forIndexPath:indexPath];
        [cell setImageWithUrl:imagePath];
        return cell;
    }
}

- (void)deleteFileWithUrl:(NSString *)url{
    [[NSFileManager defaultManager] removeItemAtPath:url error:nil];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    NSString *imageDetails = [[NSUserDefaults standardUserDefaults] objectForKey:@"ClassicImage_FileName"];
    self.imageList = [imageDetails objectFromJSONString];
    if (self.imageList == nil) {
        self.imageList = [NSMutableArray new];
    }
    [self.collectionView reloadData];
    [_largeCollectionView reloadData];
}

- (IBAction)onDelete:(id)sender{
    _isEdit = !_isEdit;
    [self.collectionView reloadData];
}

- (UIImage *)cropImage: (UIImage *)image{
    CGImageRef sourceImageRef = [image CGImage];//将UIImage转换成CGImageRef
    CGFloat _imageWidth = image.size.width * image.scale;
    CGFloat _imageHeight = image.size.height * image.scale;
    CGFloat _little = _imageWidth/3 > _imageHeight/4 ? _imageHeight : _imageWidth;
    CGFloat _offsetX;
    CGFloat _offsetY;
    CGRect rect;
    if (_imageHeight == _little) {
        _offsetX = (_imageWidth - _little/4*3) / 2;
        _offsetY = (_imageHeight - _little) / 2;
        rect = CGRectMake(_offsetX, _offsetY, _little/4*3, _little);
    }else{
        _offsetX = (_imageWidth - _little) / 2;
        _offsetY = (_imageHeight - _little/3*4) / 2;
        rect = CGRectMake(_offsetX, _offsetY, _little, _little/3*4);
    }
    
    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);//按照给定的矩形区域进行剪裁
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    return newImage;
}

- (IBAction)onAlbum:(id)sender{
    if (_isEdit == YES) {
        _isEdit = NO;
        [self.collectionView reloadData];
    }
    
    NSArray *themeList = [[ThemeManager sharedThemeManager] themePlistArray];
    BOOL isListPurchase = [[[themeList objectAtIndex:_selectCameraIndex] objectForKey:@"isPurchase"] boolValue];
    if(isListPurchase == NO && [ProManager isProductPaid:[[themeList objectAtIndex:self.selectCameraIndex] objectForKey:@"ProductCode"]] == NO && [ProManager isFullPaid] == NO){
        if ([[[themeList objectAtIndex:self.selectCameraIndex] objectForKey:@"isAdFree"] boolValue] == YES) {
            NSLog(@"提示看影片");
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tip", nil) message:NSLocalizedString(@"ShouldRewardVideo", nil) preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                //观看影片
                if ([[GADRewardBasedVideoAd sharedInstance] isReady]) {
                    [[GADRewardBasedVideoAd sharedInstance] presentFromRootViewController:self];
                }else{
                    [MBProgressHUD showErrorMessage:NSLocalizedString(@"RequestRewardVideo", nil)];
                }
            }];
            
            [alertController addAction:okAction];
            [alertController addAction:cancelAction];
            
            [self presentViewController:alertController animated:YES completion:nil];
            return;
        }
        
        if ([SKPaymentQueue canMakePayments]) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tip", nil) message:NSLocalizedString(@"ShouldPay", nil) preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BuySingle", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self.proManager buyProduct:[[themeList objectAtIndex:self.selectCameraIndex] objectForKey:@"ProductCode"]];
            }];
            UIAlertAction *allAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BuyAll", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                [self.proManager buyProduct:ALL_PRODUCT_ID];
            }];
            
            [alertController addAction:okAction];
            [alertController addAction:allAction];
            [alertController addAction:cancelAction];
            
            [self presentViewController:alertController animated:YES completion:nil];
            NSLog(@"允许程序内付费购买");
        }else{
            NSLog(@"不允许程序内付费购买");
            [MBProgressHUD showErrorMessage:NSLocalizedString(@"NoPermission", nil)];
        }
        return;
    }
    
    PHAuthorizationStatus authStatus = [PHPhotoLibrary authorizationStatus];
    if (PHAuthorizationStatusAuthorized == authStatus) {
        BLImagePickerViewController *imgVc = [[BLImagePickerViewController alloc]init];
        UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:imgVc];
        imgVc.imageClipping = NO;
        imgVc.showCamera = NO;
        imgVc.navColor = [UIColor blackColor];
        imgVc.maxNum = 1;
        [imgVc setFinishedBlock:^(NSArray<UIImage *> *resultAry, NSArray<PHAsset *> *assetsArry, UIImage *editedImage) {
            if([resultAry count] > 0){
                UIImage *selectImage = [resultAry firstObject];
                selectImage = [self cropImage:selectImage];
                [MBProgressHUD showActivityMessageInWindow:NSLocalizedString(@"Processing", nil)];
                
                if ([[SettingModel sharedInstance] isSound]) {
                    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(onPlayAudio) object:nil];
                    [thread start];
                }
                
                UIImage *image = [[PhotoEffectUtil alloc] getEffectImageWithOriImage:selectImage andDevice:0];
                [MBProgressHUD hideHUD];
                
                NSString *fileName = [self getFileName];
                NSLog(@"%@",fileName);
                NSString *path_document = NSHomeDirectory();
                //设置一个图片的存储路径
                NSString *imagePath = [path_document stringByAppendingString:[NSString stringWithFormat:@"/Documents/%@.png",fileName]];
                //把图片直接保存到指定的路径（同时应该把图片的路径imagePath存起来，下次就可以直接用来取）
                if (image.size.width > image.size.height) {
                    image = [image imageRotatedByDegrees:270];
                }
                [UIImagePNGRepresentation(image) writeToFile:imagePath atomically:YES];
                
                if([[SettingModel sharedInstance] isAutoSave]){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self syncSaveImage:image];
                    });
                }
                
                NSString *thumbPath = [path_document stringByAppendingString:[NSString stringWithFormat:@"/Documents/%@.jpg",fileName]];
                //把图片直接保存到指定的路径（同时应该把图片的路径imagePath存起来，下次就可以直接用来取）
                
                BOOL isSaved = [UIImageJPEGRepresentation(image, 0) writeToFile:thumbPath atomically:YES];
                
                if (![[SettingModel sharedInstance] isAutoSave]){
                    if (isSaved) {
                        [MBProgressHUD showSuccessMessage:NSLocalizedString(@"SaveSuccess", nil)];
                    }else{
                        [MBProgressHUD showErrorMessage:NSLocalizedString(@"SaveError", nil)];
                    }
                }
                
                if ([self.imageList count] == 0) {
                    [self.imageList addObject:fileName];
                }else{
                    [self.imageList insertObject:fileName atIndex:0];
                }
                
                NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(onSaveImageCache) object:nil];
                [thread start];
            }else{
                [MBProgressHUD showErrorMessage:NSLocalizedString(@"AlbumEditError", nil)];
            }
        }];
        [imgVc setCancleBlock:^(NSString *cancleStr) {
            [nav popViewControllerAnimated:YES];
        }];
        [self presentViewController:nav animated:YES completion:nil];
    }else{
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            
        }];
    }
    return;
}

- (void)onPlayAudio{
    NSString *newPath = [[NSBundle mainBundle]pathForResource:@"clean" ofType:@"mp3"];
    //由于使用音频路径的时候为NSURL类型，所以我们需要将文件路径转换为NSURL类型
    NSURL *newurl = [NSURL fileURLWithPath:newPath];
    //需要创建一个soundID，因为播放系统声音的时候，系统找寻的是soundID，soundID的范围为1000-2000之间。
    SystemSoundID soundID;
    /*根据声音的路径创建ID    （__bridge在两个框架之间强制转换类型，值转换内存，不修改内存管理的
     权限）在转换数据类型的时候，不希望该对象的内存管理权限发生改变，原来是MRC类型，转换了还是 MRC。*/
    AudioServicesCreateSystemSoundID((__bridge CFURLRef _Nonnull)(newurl), &soundID);
    AudioServicesPlaySystemSound(soundID);
}

- (void)onSaveImageCache{
    NSString *dataString = [self.imageList objectToJSONString];
    [[NSUserDefaults standardUserDefaults] setObject:dataString forKey:@"ClassicImage_FileName"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/**同步方式保存图片到系统的相机胶卷中---返回的是当前保存成功后相册图片对象集合*/
-(void)syncSaveImage:(UIImage *)image{
    __block NSString *createdAssetID = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        createdAssetID = [PHAssetChangeRequest             creationRequestForAssetFromImage:image].placeholderForCreatedAsset.localIdentifier;
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (error) {
            [MBProgressHUD hideHUD];
            [MBProgressHUD showErrorMessage:NSLocalizedString(@"SaveError", nil)];
        }else{
            PHFetchResult<PHAsset *> *assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[createdAssetID] options:nil];
            if (assets == nil)
            {
                [MBProgressHUD hideHUD];
                [MBProgressHUD showErrorMessage:NSLocalizedString(@"SaveError", nil)];
                return;
            }
            
            //2 拥有自定义相册（与 APP 同名，如果没有则创建）--调用刚才的方法
            PHAssetCollection *assetCollection = [self getAssetCollectionWithAppNameAndCreateIfNo];
            if (assetCollection == nil) {
                [MBProgressHUD hideHUD];
                [MBProgressHUD showErrorMessage:NSLocalizedString(@"CreateAlbumError", nil)];
                return;
            }
            
            [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                //--告诉系统，要操作哪个相册
                PHAssetCollectionChangeRequest *collectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
                //--添加图片到自定义相册--追加--就不能成为封面了
                //--[collectionChangeRequest addAssets:assets];
                //--插入图片到自定义相册--插入--可以成为封面
                [collectionChangeRequest insertAssets:assets atIndexes:[NSIndexSet indexSetWithIndex:0]];
            } error:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUD];
                [MBProgressHUD showSuccessMessage:NSLocalizedString(@"SaveSuccess", nil)];
            });
        }
    }];
}

/**拥有与 APP 同名的自定义相册--如果没有则创建*/
-(PHAssetCollection *)getAssetCollectionWithAppNameAndCreateIfNo
{
    //1 获取以 APP 的名称
    NSString *title = [NSBundle mainBundle].infoDictionary[(__bridge NSString *)kCFBundleNameKey];
    //2 获取与 APP 同名的自定义相册
    PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *collection in collections) {
        //遍历
        if ([collection.localizedTitle isEqualToString:title]) {
            //找到了同名的自定义相册--返回
            return collection;
        }
    }
    
    //说明没有找到，需要创建
    NSError *error = nil;
    __block NSString *createID = nil; //用来获取创建好的相册
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        //发起了创建新相册的请求，并拿到ID，当前并没有创建成功，待创建成功后，通过 ID 来获取创建好的自定义相册
        PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:title];
        createID = request.placeholderForCreatedAssetCollection.localIdentifier;
    } error:&error];
    if (error) {
        [MBProgressHUD showErrorMessage:NSLocalizedString(@"CreateAlbumError", nil)];
        return nil;
    }else{
        //通过 ID 获取创建完成的相册 -- 是一个数组
        return [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[createID] options:nil].firstObject;
    }
}

- (NSString *)getFileName{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"YYYYMMddHHmmssSSS"];
    NSTimeZone* timeZone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
    [formatter setTimeZone:timeZone];
    NSDate *datenow = [NSDate date];//现在时间,你可以输出来看下是什么格式
    NSString *fileName = [NSString stringWithFormat:@"%ld", (long)[datenow timeIntervalSince1970]*1000];
    return fileName;
}

- (IBAction)onBack:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
