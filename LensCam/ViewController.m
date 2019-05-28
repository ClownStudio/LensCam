//
//  ViewController.m
//  LensCam
//
//  Created by 张文洁 on 2018/10/11.
//  Copyright © 2018年 JamStudio. All rights reserved.
//

#import "ViewController.h"
#import "Macro.h"
#import "ThemeManager.h"
#import "SettingView.h"
#import <Photos/Photos.h>
#import <MBProgressHUD+JDragon.h>
#import "SettingModel.h"
#import "AlbumViewController.h"
#import "ArtTableViewCell.h"
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "PhotoEffectUtil.h"
#import "DeviceOrientation.h"
#import "UIImage+Rotate.h"
#import "YJJsonKit.h"
#import <StoreKit/StoreKit.h>
#import <QuartzCore/QuartzCore.h>

@interface ViewController () <UITableViewDelegate,UITableViewDataSource,GADRewardBasedVideoAdDelegate,DeviceOrientationDelegate,GADBannerViewDelegate>

@end

@implementation ViewController{
    UIView *_firstView;
    UIButton *_firstMaskView;
    UIView *_secondView;
    UIView *_thirdView;
    CGFloat _cameraHeight;
    CGFloat _storeHeight;
    UIImageView *_headView;
    UIImageView *_viewPortImage;
    
    UIButton *_settingBtn;
    UIButton *_flashBtn;
    UIButton *_pressBtn;
    UIButton *_changeBtn;
    UIButton *_cameraBagBtn;
    UIImageView *_albumShotCut;
    UIButton *_albumBtn;
    SettingView *_settingView;
    
    UIButton *_storeBtn;
    UIScrollView *_cameraScrollView;
    UIScrollView *_selectionScrollView;
    UIImageView *_selectIcon;
    UIImageView *_firstBackgroundImageView;
    UIImageView *_secondBackgrouondImageView;
    UIImageView *_thirdBackgrouondImageView;
    UIImageView *_unlockImageView;
    
    NSArray *_themeList;
    UITableView *_storeTableView;
    NSMutableArray *_sectionList;
    UIButton *_alphaBigViewPortBtn;
    
    BOOL _isBack;
    BOOL _isAutoFlash;
    NSString *_adProductId;
    
    DeviceOrientation *_deviceMotion;
    UIDeviceOrientation _deviceOrientation;
    
    NSMutableArray *_imageLists;
    GADBannerView *_bannerView;
    UIButton *_alphaView;
    
    NSInteger _selectCameraIndex;
    UIImageView *_shadowImageView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initParams];
    
    [self createCameraSkin];
    [self refreshCameraLayout];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:kStoreProductKey] == nil) {
        [defaults setObject:@"0" forKey:kStoreProductKey];
        [defaults synchronize];
    }else if ([@"0" isEqualToString:[defaults objectForKey:kStoreProductKey]]){
        [self loadAppStoreController];
    }
}

- (void)directionChange:(TgDirection)direction {
    switch (direction) {
        case TgDirectionPortrait:
            _deviceOrientation = UIDeviceOrientationPortrait;
            break;
            
        case TgDirectionDown:
            _deviceOrientation = UIDeviceOrientationPortraitUpsideDown;
            break;
            
        case TgDirectionRight:
            _deviceOrientation = UIDeviceOrientationLandscapeRight;
            break;
            
        case TgDirectionleft:
            _deviceOrientation = UIDeviceOrientationLandscapeLeft;
            break;
            
        default:
            break;
    }
}

- (void)initParams{
    _isBack = YES;
    _isAutoFlash = NO;
    [[ThemeManager sharedThemeManager] setThemeIndex:0];
    _cameraHeight = 130;
    _storeHeight = HEIGHT - 80;
    
    [GADRewardBasedVideoAd sharedInstance].delegate = self;
    
    if (![[GADRewardBasedVideoAd sharedInstance] isReady]) {
        [self requestRewardedVideo];
    }
    
    _themeList = [[ThemeManager sharedThemeManager] themePlistArray];
    _sectionList = [[NSMutableArray alloc] initWithArray:@[@"0"]];
    for (int i = 0; i< [_themeList count]; i++) {
        [_sectionList addObject:@"0"];
    }
    
    _deviceMotion = [[DeviceOrientation alloc] initWithDelegate:self];
}

- (void)requestRewardedVideo {
    GADRequest *request = [GADRequest request];
    [[GADRewardBasedVideoAd sharedInstance] loadRequest:request
                                           withAdUnitID:AWARD_VIDEO_ID];
}

- (void)createCameraSkin{
    _thirdView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, WIDTH, HEIGHT)];
    [self createThirdView];
    [self.view addSubview:_thirdView];
    
    _secondView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, WIDTH, HEIGHT)];
    [self createSecondView];
    [self.view addSubview:_secondView];
    
    _firstView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, WIDTH, HEIGHT)];
    [self createFirstView];
    [self.view addSubview:_firstView];
    _shadowImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, HEIGHT, WIDTH, 43)];
    [_shadowImageView setImage:[UIImage imageNamed:@"shadow"]];
    _shadowImageView.contentMode = UIViewContentModeRedraw;
    [_firstView addSubview:_shadowImageView];
    
    _firstMaskView = [[UIButton alloc] initWithFrame:_firstView.bounds];
    [_firstMaskView addTarget:self action:@selector(onHideOtherView:) forControlEvents:UIControlEventTouchUpInside];
    [_firstMaskView setHidden:YES];
    [_firstView addSubview:_firstMaskView];
}

- (IBAction)onHideOtherView:(id)sender{
    [UIView animateWithDuration:0.3 animations:^{
        CGRect temp = self->_firstView.frame;
        temp.origin.y = 0;
        self->_firstView.frame = temp;
    } completion:^(BOOL finished) {
        [self->_firstMaskView setHidden:YES];
        [self->_secondView setHidden: NO];
    }];
}

- (void)createFirstView{
    _firstBackgroundImageView = [[UIImageView alloc] initWithFrame:_firstView.bounds];
    [_firstView addSubview:_firstBackgroundImageView];
    
    _headView = [[UIImageView alloc] init];
    [_headView.layer setCornerRadius:8];
    [_headView.layer setMasksToBounds:YES];
    [_headView setAnimationRepeatCount:1];
    [_firstView addSubview:_headView];
    
    _viewPortImage = [[UIImageView alloc] init];
    [self initAVCaptureSession];
    if ([ALLOW_BIG_VIEWPORT isEqualToString:@"1"]) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onChangeViewPort:)];
        [_viewPortImage setUserInteractionEnabled:YES];
        [_viewPortImage addGestureRecognizer:tap];
        
        _alphaBigViewPortBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, WIDTH, HEIGHT*0.6)];
        [_alphaBigViewPortBtn addTarget:self action:@selector(onChangeBigViewPort:) forControlEvents:UIControlEventTouchUpInside];
        [_alphaBigViewPortBtn setBackgroundColor:[UIColor clearColor]];
        [_alphaBigViewPortBtn setHidden:YES];
        [_firstView addSubview:_alphaBigViewPortBtn];
    }
    
    _pressBtn = [[UIButton alloc] init];
    [_pressBtn addTarget:self action:@selector(onPress:) forControlEvents:UIControlEventTouchUpInside];
    [_firstView addSubview:_pressBtn];
    
    _settingBtn = [[UIButton alloc] init];
    [_settingBtn addTarget:self action:@selector(onSetting:) forControlEvents:UIControlEventTouchUpInside];
    [_firstView addSubview:_settingBtn];
    
    _flashBtn = [[UIButton alloc] init];
    [_flashBtn addTarget:self action:@selector(onFlash:) forControlEvents:UIControlEventTouchUpInside];
    [_firstView addSubview:_flashBtn];
    
    _changeBtn = [[UIButton alloc] init];
    [_changeBtn addTarget:self action:@selector(onChange:) forControlEvents:UIControlEventTouchUpInside];
    [_firstView addSubview:_changeBtn];
    
    _cameraBagBtn = [[UIButton alloc] init];
    [_cameraBagBtn addTarget:self action:@selector(onCameraBag:) forControlEvents:UIControlEventTouchUpInside];
    [_firstView addSubview:_cameraBagBtn];
    
    _albumShotCut = [[UIImageView alloc] init];
    [_albumShotCut.layer setMasksToBounds:YES];
    [_albumShotCut setContentMode:UIViewContentModeScaleAspectFill];
    [_firstView addSubview:_albumShotCut];
    
    _albumBtn = [[UIButton alloc] init];
    [_albumBtn addTarget: self action:@selector(onAlbum:) forControlEvents:UIControlEventTouchUpInside];
    [_firstView addSubview:_albumBtn];
}

- (void)createSecondView{
    _secondBackgrouondImageView = [[UIImageView alloc] initWithFrame:_secondView.bounds];
    [_secondView addSubview:_secondBackgrouondImageView];
    
    _storeBtn = [[UIButton alloc] init];
    [_storeBtn addTarget:self action:@selector(onDetialStore:) forControlEvents:UIControlEventTouchUpInside];
    [_secondView addSubview:_storeBtn];
    
    _cameraScrollView = [[UIScrollView alloc] init];
    
    int distance = 0;
    int gap = 20;
    for (int i = 0; i < [_themeList count]; i++) {
        UIButton *imageView = [[UIButton alloc] initWithFrame:CGRectMake(distance, 0, 70, 70)];
        [imageView setImage:[UIImage imageNamed:[[_themeList objectAtIndex:i] objectForKey:@"Icon"]] forState:UIControlStateNormal];
        [imageView addTarget:self action:@selector(onSelectCameraSkin:) forControlEvents:UIControlEventTouchUpInside];
        [_cameraScrollView addSubview:imageView];
        imageView.tag = i + 1;
        distance += gap + 70;
    }
    [_cameraScrollView setContentSize:CGSizeMake(distance - gap, 0)];
    [_cameraScrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    [_secondView addSubview:_cameraScrollView];
    
    _selectionScrollView = [[UIScrollView alloc] init];
    _selectIcon = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 15, 15)];
    [_selectionScrollView addSubview:_selectIcon];
    [_secondView addSubview:_selectionScrollView];
    
    [_selectionScrollView setContentSize:CGSizeMake(_cameraScrollView.contentSize.width, 0)];
    
    _selectCameraIndex = 0;
    [self selectCameraSkinAtIndex:_selectCameraIndex];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat sectionHeaderHeight = 0;
    if (Is_iPad) {
        sectionHeaderHeight =  WIDTH * 0.7/1125*307;
    }else{
        sectionHeaderHeight = WIDTH/1125*307;
    }
    if(scrollView.contentOffset.y<=sectionHeaderHeight&&scrollView.contentOffset.y>=0) {
        scrollView.contentInset = UIEdgeInsetsMake(-scrollView.contentOffset.y, 0, 0, 0);
    } else if (scrollView.contentOffset.y>=sectionHeaderHeight) {
        scrollView.contentInset = UIEdgeInsetsMake(-sectionHeaderHeight, 0, 0, 0);
    }
}

- (void)createThirdView{
    _thirdBackgrouondImageView = [[UIImageView alloc] initWithFrame:_thirdView.bounds];
    [_thirdView addSubview:_thirdBackgrouondImageView];
    
    if (Is_iPad) {
        [_thirdBackgrouondImageView setImage:[UIImage imageNamed:@"store_background_iPad"]];
    }else{
        if (Is_iPhoneX) {
            [_thirdBackgrouondImageView setImage:[UIImage imageNamed:@"store_background_iPhoneX"]];
        }else{
            [_thirdBackgrouondImageView setImage:[UIImage imageNamed:@"store_background_iPhone"]];
        }
    }
    
    _storeTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, HEIGHT - _storeHeight, WIDTH, _storeHeight)];
    _storeTableView.delegate = self;
    _storeTableView.dataSource = self;
    [_storeTableView setBackgroundColor:[UIColor clearColor]];
    [_storeTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [_thirdView addSubview:_storeTableView];
    
    if (@available(iOS 11.0, *)) {
        _storeTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }else{
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _themeList.count + 1;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 0;
    }
    return 1;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        if (Is_iPad) {
            UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, WIDTH, WIDTH*0.7/1125*782)];
            _unlockImageView = [[UIImageView alloc] initWithFrame:CGRectMake(WIDTH * 0.15, 0, WIDTH*0.7, WIDTH*0.7/1125*782)];
            [_unlockImageView setImage:[UIImage imageNamed:@"unlock"]];
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onUnlockAll:)];
            [_unlockImageView setUserInteractionEnabled:YES];
            [_unlockImageView addGestureRecognizer:tap];
            [view addSubview:_unlockImageView];
            return view;
        }else{
            _unlockImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, WIDTH, WIDTH/1125*782)];
            [_unlockImageView setImage:[UIImage imageNamed:@"unlock"]];
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onUnlockAll:)];
            [_unlockImageView setUserInteractionEnabled:YES];
            [_unlockImageView addGestureRecognizer:tap];
            return _unlockImageView;
        }
    }
    if (Is_iPad) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, WIDTH, WIDTH*0.7/1125*307)];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(WIDTH *0.15, 0, WIDTH*0.7, WIDTH*0.7/1125*307)];
        [imageView setImage:[UIImage imageNamed:[[_themeList objectAtIndex:section - 1] objectForKey:@"StoreCell"]]];
        imageView.tag = section;
        [imageView setBackgroundColor:[UIColor clearColor]];
        [imageView setUserInteractionEnabled: YES];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapStoreCell:)];
        [imageView addGestureRecognizer:tap];
        
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(imageView.frame.size.width * 0.75, 0, imageView.frame.size.width * 0.25, WIDTH*0.7/1125*307)];
        [button addTarget:self action:@selector(onBuyCamera:) forControlEvents:UIControlEventTouchUpInside];
        button.tag = section;
        [imageView addSubview: button];
        [view addSubview:imageView];
        return view;
    }else{
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, WIDTH, WIDTH/1125*307)];
        [imageView setImage:[UIImage imageNamed:[[_themeList objectAtIndex:section - 1] objectForKey:@"StoreCell"]]];
        imageView.tag = section;
        [imageView setBackgroundColor:[UIColor clearColor]];
        [imageView setUserInteractionEnabled: YES];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapStoreCell:)];
        [imageView addGestureRecognizer:tap];
        
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(WIDTH * 0.75, 0, WIDTH * 0.25, WIDTH/1125*307)];
        [button addTarget:self action:@selector(onBuyCamera:) forControlEvents:UIControlEventTouchUpInside];
        button.tag = section;
        [imageView addSubview: button];
        return imageView;
    }
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    ArtTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ArtTableViewCell"];
    if (cell == nil) {
        cell = [[ArtTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ArtTableViewCell"];
        cell.clipsToBounds = YES;
    }
    [cell setContentWithDataSource:[[_themeList objectAtIndex:indexPath.section - 1] objectForKey:@"StoreImage"]];
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([_sectionList[indexPath.section] isEqualToString:@"0"]){
        return 0;
    }else{
        return 250;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        if (Is_iPad) {
            return WIDTH * 0.7/1125*782;
        }else{
            return WIDTH/1125*782;
        }
    }
    if (Is_iPad) {
        return WIDTH * 0.7/1125*307;
    }else{
        return WIDTH/1125*307;
    }
}

- (void)onUnlockAll:(UITapGestureRecognizer *)tap{
    if ([ProManager isProductPaid:ALL_PRODUCT_ID]) {
        [MBProgressHUD showInfoMessage:NSLocalizedString(@"hasPurchase", nil)];
        return;
    }
    [MBProgressHUD showActivityMessageInView:NSLocalizedString(@"Loading", nil)];
    [self.proManager buyProduct:ALL_PRODUCT_ID];
}

- (void)onTapStoreCell:(UITapGestureRecognizer *)tap{
    NSInteger index = tap.view.tag;
    NSMutableArray *indexArray = [NSMutableArray array];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:index];
    [indexArray addObject:indexPath];
    if ([_sectionList[index] isEqualToString:@"0"]) {
        for (int i = 0; i <[_sectionList count]; i ++) {
            [_sectionList setObject:@"0" atIndexedSubscript:i];
        }
        _sectionList[index] = @"1";
        
        [self->_storeTableView reloadData];
        CGFloat offsetY = self->_storeTableView.contentOffset.y;
        CGFloat height = self->_storeTableView.bounds.size.height;
        CGFloat allHeight = 250;
        for (int i = 0; i < index; i++) {
            if (i == 0) {
                if (Is_iPad) {
                    allHeight += WIDTH * 0.7/1125*782;
                }else{
                    allHeight += WIDTH/1125*782;
                }
            }
            if (Is_iPad) {
                allHeight += WIDTH * 0.7/1125*307;
            }else{
                allHeight += WIDTH/1125*307;
            }
        }
        
        if (offsetY + height < allHeight) {
            [self->_storeTableView beginUpdates];
            [self->_storeTableView setContentOffset:CGPointMake(0, allHeight - height) animated:YES];
            [self->_storeTableView endUpdates];
        }
    }else
    {
        for (int i = 0; i <[_sectionList count]; i ++) {
            [_sectionList setObject:@"0" atIndexedSubscript:i];
        }
        [_storeTableView reloadData];
    }
}

- (IBAction)onBuyCamera:(UIButton *)sender{
    if ([ProManager isProductPaid:ALL_PRODUCT_ID]) {
        [MBProgressHUD showInfoMessage:NSLocalizedString(@"hasPurchase", nil)];
        return;
    }
    
    NSDictionary *dict = [_themeList objectAtIndex:sender.tag - 1];
    NSString *productCode = [dict objectForKey:@"ProductCode"];
    if ([@"" isEqualToString:productCode]) {
        return;
    }
    if ([[dict objectForKey:@"isPurchase"] boolValue] == YES) {
        [MBProgressHUD showInfoMessage:NSLocalizedString(@"hasPurchase", nil)];
        return;
    }
    if ([ProManager isProductPaid:productCode]) {
        [MBProgressHUD showInfoMessage:NSLocalizedString(@"hasPurchase", nil)];
        return;
    }
    
    if ([[dict objectForKey:@"isAdFree"] boolValue] == YES) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tip", nil) message:NSLocalizedString(@"ShouldRewardVideo", nil) preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            //观看影片
            if ([[GADRewardBasedVideoAd sharedInstance] isReady]) {
                self->_adProductId = productCode;
                [[GADRewardBasedVideoAd sharedInstance] presentFromRootViewController:self];
            }else{
                [MBProgressHUD showErrorMessage:NSLocalizedString(@"RequestRewardVideoError", nil)];
            }
        }];
        
        [alertController addAction:okAction];
        [alertController addAction:cancelAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
    
    [MBProgressHUD showActivityMessageInView:NSLocalizedString(@"Loading", nil)];
    [self.proManager buyProduct: productCode];
}

#pragma 奖励广告反馈
- (void)rewardBasedVideoAdDidReceiveAd:(GADRewardBasedVideoAd *)rewardBasedVideoAd {
    NSLog(@"Reward based video ad is received.");
}

- (void)rewardBasedVideoAdDidOpen:(GADRewardBasedVideoAd *)rewardBasedVideoAd {
    NSLog(@"Opened reward based video ad.");
}

- (void)rewardBasedVideoAdDidStartPlaying:(GADRewardBasedVideoAd *)rewardBasedVideoAd {
    NSLog(@"Reward based video ad started playing.");
}

- (void)rewardBasedVideoAdDidClose:(GADRewardBasedVideoAd *)rewardBasedVideoAd {
    NSLog(@"Reward based video ad is closed.");
    if (![[GADRewardBasedVideoAd sharedInstance] isReady]) {
        [self requestRewardedVideo];
    }
}

- (void)rewardBasedVideoAd:(GADRewardBasedVideoAd *)rewardBasedVideoAd
   didRewardUserWithReward:(GADAdReward *)reward {
    // Reward the user for watching the video.
    [MBProgressHUD showSuccessMessage:NSLocalizedString(@"UnlockSuccess", nil)];
    if ([@"" isEqualToString:_adProductId] == NO) {
        [ProManager addProductId:_adProductId];
        _adProductId = @"";
    }
}

- (IBAction)onDetialStore:(id)sender{
    [UIView animateWithDuration:0.3 animations:^{
        CGRect temp = self->_firstView.frame;
        temp.origin.y = 0;
        self->_firstView.frame = temp;
    } completion:^(BOOL finished) {
        [self->_secondView setHidden: YES];
        [UIView animateWithDuration:0.3 animations:^{
            CGRect temp = self->_firstView.frame;
            temp.origin.y = - self->_storeHeight;
            self->_firstView.frame = temp;
        }];
    }];
}

- (void)refreshCameraLayout{
    if (Is_iPad) {
        [_firstBackgroundImageView setImage:[[ThemeManager sharedThemeManager] themeImageWithName:@"background_iPad"]];
    }else{
        if (Is_iPhoneX) {
            [_firstBackgroundImageView setImage:[[ThemeManager sharedThemeManager] themeImageWithName:@"background_iPhoneX"]];
        }else{
            [_firstBackgroundImageView setImage:[[ThemeManager sharedThemeManager] themeImageWithName:@"background_iPhone"]];
        }
    }
    
    UIImage *headImage = [[ThemeManager sharedThemeManager]themeImageWithName:@"print"];
    if (Is_iPad) {
        [_headView setFrame:CGRectMake((WIDTH - WIDTH/6)/2, 100, WIDTH/6, WIDTH/6/headImage.size.width*headImage.size.height)];
    }else{
        [_headView setFrame:CGRectMake((WIDTH - 53)/2, Is_iPhoneX ? 74:30, 53, 15)];
    }
    [_headView setImage:headImage];
    
    UIImage *image = [[ThemeManager sharedThemeManager] themeImageWithName:@"viewfinder-frame"];
    if (Is_iPad) {
        [_viewPortImage setFrame:CGRectMake(WIDTH * 0.3, _headView.frame.origin.y + _headView.bounds.size.height + 80, WIDTH * 0.4, WIDTH * 0.4/image.size.width*image.size.height)];
    }else{
        [_viewPortImage setFrame:CGRectMake(WIDTH * 0.2, _headView.frame.origin.y + _headView.bounds.size.height + (HEIGHT * 0.5 + 20 - WIDTH * 0.6/image.size.width*image.size.height)/2, WIDTH * 0.6, WIDTH * 0.6/image.size.width*image.size.height)];
    }
    
    [_viewPortImage setImage:image];
    
    CGFloat scale = [[ThemeManager sharedThemeManager] getViewPortScale];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [self.previewLayer setFrame:CGRectMake( _viewPortImage.frame.origin.x + _viewPortImage.bounds.size.width * (1 - scale)/2, _viewPortImage.frame.origin.y + _viewPortImage.bounds.size.height * (1 - scale)/2, _viewPortImage.bounds.size.width * scale, _viewPortImage.bounds.size.height * scale)];
    [CATransaction commit];
    
    if (Is_iPad) {
        [_pressBtn setFrame:CGRectMake((WIDTH - (_viewPortImage.frame.size.width * 0.3))/2, _viewPortImage.frame.origin.y + _viewPortImage.frame.size.height + 80, _viewPortImage.frame.size.width * 0.3, _viewPortImage.frame.size.width * 0.3)];
    }else{
        [_pressBtn setFrame:CGRectMake((WIDTH - (_viewPortImage.frame.size.width * 0.4))/2, _headView.frame.origin.y + 35 + HEIGHT * 0.5, _viewPortImage.frame.size.width * 0.4, _viewPortImage.frame.size.width * 0.4)];
    }
    [_pressBtn setImage:[[ThemeManager sharedThemeManager] themeImageWithName:@"shutter-normal"] forState:UIControlStateNormal];
    [_pressBtn setImage:[[ThemeManager sharedThemeManager] themeImageWithName:@"shutter-pressed"] forState:UIControlStateHighlighted];
    
    [_settingBtn setFrame:CGRectMake(_pressBtn.center.x - _pressBtn.bounds.size.width * 1.1, _pressBtn.frame.origin.y - 20, _pressBtn.bounds.size.width * 0.5, _pressBtn.bounds.size.width * 0.5)];
    [_settingBtn setImage:[[ThemeManager sharedThemeManager] themeImageWithName:@"setting-normal"] forState:UIControlStateNormal];
    [_settingBtn setImage:[[ThemeManager sharedThemeManager] themeImageWithName:@"setting-pressed"] forState:UIControlStateHighlighted];
    
    [_flashBtn setFrame:CGRectMake(_pressBtn.center.x + _pressBtn.bounds.size.width * 0.6, _pressBtn.frame.origin.y - 20, _pressBtn.bounds.size.width * 0.5, _pressBtn.bounds.size.width * 0.5)];
    [_flashBtn setImage:[[ThemeManager sharedThemeManager] themeImageWithName:@"flash-off"] forState:UIControlStateNormal];
    
    [_changeBtn setFrame:CGRectMake((WIDTH - 70)/2, _pressBtn.frame.origin.y + _pressBtn.bounds.size.height + 15, 70, 30)];
    [_changeBtn setImage:[[ThemeManager sharedThemeManager] themeImageWithName:@"switch"] forState:UIControlStateNormal];
    [_changeBtn setImage:[[ThemeManager sharedThemeManager] themeImageWithName:@"switch-pressed"] forState:UIControlStateHighlighted];
    
    if (Is_iPad) {
        [_cameraBagBtn setFrame:CGRectMake(_viewPortImage.frame.origin.x - 15 - _pressBtn.frame.size.width * 0.8, HEIGHT - _pressBtn.frame.size.width * 0.8 - 20, _pressBtn.frame.size.width * 0.8, _pressBtn.frame.size.width * 0.8)];
    }else{
        [_cameraBagBtn setFrame:CGRectMake(_viewPortImage.frame.origin.x - _pressBtn.frame.size.width * 0.6, HEIGHT - _pressBtn.frame.size.width * 0.6 - 20, _pressBtn.frame.size.width * 0.6, _pressBtn.frame.size.width * 0.6)];
    }
    
    [_cameraBagBtn setImage:[[ThemeManager sharedThemeManager] themeImageWithName:@"camerabag"] forState:UIControlStateNormal];
    
    if (Is_iPad) {
        [_albumBtn setFrame:CGRectMake(_viewPortImage.frame.origin.x + 15 + _viewPortImage.frame.size.width, HEIGHT - _pressBtn.frame.size.width * 0.8 - 20, _pressBtn.frame.size.width * 0.8, _pressBtn.frame.size.width * 0.8)];
    }else{
        [_albumBtn setFrame:CGRectMake(_viewPortImage.frame.origin.x + _viewPortImage.frame.size.width, HEIGHT - _pressBtn.frame.size.width * 0.6 - 20, _pressBtn.frame.size.width * 0.6, _pressBtn.frame.size.width * 0.6)];
    }
    [_albumBtn setImage:[[ThemeManager sharedThemeManager] themeImageWithName:@"album-bonder"] forState:UIControlStateNormal];
    
    [_albumShotCut setFrame:_albumBtn.frame];
    [_albumShotCut setFrame:CGRectMake(0, 0, _albumBtn.frame.size.width/178*148, _albumBtn.frame.size.height/178*148)];
    [_albumShotCut.layer setCornerRadius:_albumShotCut.frame.size.width/2];
    _albumShotCut.center = _albumBtn.center;
    if ([_imageLists count] >0) {
        [self refreshAlbumImage];
    }else{
        [_albumShotCut setImage:[[ThemeManager sharedThemeManager] themeImageWithName:@"album-image"]];
    }
    
    if (Is_iPad) {
        [_secondBackgrouondImageView setImage:[[ThemeManager sharedThemeManager] themeImageWithName:@"background_iPad"]];
    }else{
        if (Is_iPhoneX) {
            [_secondBackgrouondImageView setImage:[[ThemeManager sharedThemeManager] themeImageWithName:@"background_iPhoneX"]];
        }else{
            [_secondBackgrouondImageView setImage:[[ThemeManager sharedThemeManager] themeImageWithName:@"background_iPhone"]];
        }
    }
    
    [_storeBtn setFrame:CGRectMake(_cameraBagBtn.frame.origin.x + _cameraBagBtn.frame.size.width * 0.2, HEIGHT - _cameraHeight + 35, _cameraBagBtn.frame.size.width * 0.6, _cameraBagBtn.frame.size.width * 0.6)];
    [_storeBtn setImage:[[ThemeManager sharedThemeManager] themeImageWithName:@"store"] forState:UIControlStateNormal];
    
    [_cameraScrollView setFrame: CGRectMake(_storeBtn.frame.origin.x + _storeBtn.frame.size.width + 35, HEIGHT - _cameraHeight + 15, _albumBtn.frame.size.width + _albumBtn.frame.origin.x - _storeBtn.frame.origin.x - _storeBtn.frame.size.width - 35, 70)];
    
    [_selectionScrollView setFrame: CGRectMake(_storeBtn.frame.origin.x + _storeBtn.frame.size.width + 35, HEIGHT - _cameraHeight + 85, _albumBtn.frame.size.width + _albumBtn.frame.origin.x - _storeBtn.frame.origin.x - _storeBtn.frame.size.width - 35, 70)];
    
    [_selectIcon setImage:[[ThemeManager sharedThemeManager] themeImageWithName:@"selected"]];
}

- (void)refreshAlbumImage{
    if ([_imageLists count] > 0) {
        NSString *path_document = NSHomeDirectory();
        NSString *thumbPath = [path_document stringByAppendingString:[NSString stringWithFormat:@"/Documents/%@.jpg",[_imageLists firstObject]]];
        UIImage *image = [UIImage imageWithContentsOfFile:thumbPath];
        [_albumShotCut setImage:image];
    }
}

- (void)onChangeViewPort:(UITapGestureRecognizer *)tap{
    if (Is_iPad) {
        [self.previewLayer setFrame: CGRectMake(0, 0, WIDTH, _viewPortImage.frame.origin.y + _viewPortImage.frame.size.height)];
    }else{
        [self.previewLayer setFrame: CGRectMake(0, 0, WIDTH, HEIGHT * 0.55)];
    }
    [_headView setHidden:YES];
    [_viewPortImage setHidden:YES];
    [_alphaBigViewPortBtn setHidden:NO];
}

- (IBAction)onChangeBigViewPort:(id)sender{
    [_alphaBigViewPortBtn setHidden:YES];
    [_headView setHidden:NO];
    [_viewPortImage setHidden:NO];
    CGFloat scale = [[ThemeManager sharedThemeManager] getViewPortScale];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [self.previewLayer setFrame:CGRectMake(_viewPortImage.frame.origin.x + _viewPortImage.bounds.size.width * (1 - scale)/2, _viewPortImage.frame.origin.y + _viewPortImage.bounds.size.height * (1 - scale)/2, _viewPortImage.bounds.size.width * scale, _viewPortImage.bounds.size.height * scale)];
    [CATransaction commit];
}

- (IBAction)onAlbum:(id)sender{
    AlbumViewController *albumViewController = [[AlbumViewController alloc] init];
    albumViewController.imageList = _imageLists;
    albumViewController.selectCameraIndex = _selectCameraIndex;
    [self presentViewController:albumViewController animated:YES completion:^{
        
    }];
}

- (IBAction)onFlash:(id)sender{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [device lockForConfiguration:nil];
    if (_isAutoFlash) {
        if ([device isFlashModeSupported:AVCaptureFlashModeOff]) {
            [device setFlashMode:AVCaptureFlashModeOff];
            _isAutoFlash = NO;
            [_flashBtn setImage:[[ThemeManager sharedThemeManager] themeImageWithName:@"flash-off"] forState:UIControlStateNormal];
        }else{
            [MBProgressHUD showErrorMessage:NSLocalizedString(@"NoSupportLight", nil)];
        }
    }else{
        if ([device isFlashModeSupported:AVCaptureFlashModeAuto]) {
            _isAutoFlash = YES;
            [_flashBtn setImage:[[ThemeManager sharedThemeManager] themeImageWithName:@"flash-on"] forState:UIControlStateNormal];
            [device setFlashMode:AVCaptureFlashModeAuto];
        }else{
            [MBProgressHUD showErrorMessage:NSLocalizedString(@"NoSupportLight", nil)];
        }
    }
}

- (IBAction)onChange:(id)sender{
    //切换至前置摄像头
    if(_isBack)
    {
        _isBack = NO;
        AVCaptureDevice *device;
        NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for(AVCaptureDevice *tmp in devices)
        {
            if(tmp.position == AVCaptureDevicePositionFront)
                device = tmp;
        }
        [_session beginConfiguration];
        [_session removeInput:self.videoInput];
        self.videoInput = nil;
        self.videoInput = [[AVCaptureDeviceInput alloc]initWithDevice:device error:nil];
        if([_session canAddInput:self.videoInput])
            [_session addInput:self.videoInput];
        [_session commitConfiguration];
    }
    //切换至后置摄像头
    else
    {
        _isBack = YES;
        AVCaptureDevice *device;
        NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for(AVCaptureDevice *tmp in devices)
        {
            if(tmp.position == AVCaptureDevicePositionBack)
                device = tmp;
        }
        [_session beginConfiguration];
        [_session removeInput:self.videoInput];
        self.videoInput = nil;
        self.videoInput=[[AVCaptureDeviceInput alloc]initWithDevice:device error:nil];
        if([_session canAddInput:self.videoInput])
            [_session addInput:self.videoInput];
        [_session commitConfiguration];
    }
}

- (GADBannerView *)createAndLoadBannerView{
    GADBannerView *bannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeSmartBannerPortrait];
    bannerView.hidden = YES;
    bannerView.rootViewController = self;
    [bannerView setAdUnitID:AD_BANNER_ID];
    bannerView.delegate = self;
    [bannerView loadRequest:[GADRequest request]];
    return bannerView;
}

- (IBAction)onSetting:(id)sender{
    _alphaView = [[UIButton alloc] initWithFrame:self.view.bounds];
    [_alphaView setBackgroundColor:[UIColor clearColor]];
    [_alphaView addTarget:self action:@selector(onCloseSettingView:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_alphaView];
    
    _settingView = [[[NSBundle mainBundle] loadNibNamed:@"SettingView" owner:self options:nil] lastObject];
    [_alphaView addSubview:_settingView];
    
    if ([ProManager isProductPaid:AD_PRODUCT_ID] == NO && [ProManager isFullPaid] == NO && [@"1" isEqualToString:ALLOW_AD]){
        int tall = 50;
        if (Is_iPad || Is_iPhoneX) {
            tall = 70;
        }
        
        if (Is_iPad) {
            [_settingView setFrame:CGRectMake(- self.view.bounds.size.width * 0.4, 0, self.view.bounds.size.width * 0.4, self.view.bounds.size.height - tall)];
        }else{
            [_settingView setFrame:CGRectMake(- self.view.bounds.size.width, 0, self.view.bounds.size.width, self.view.bounds.size.height - tall)];
        }
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, HEIGHT - tall, _settingView.frame.size.width, tall)];
        [view setBackgroundColor:[UIColor colorWithRed:0.937 green:0.937 blue:0.958 alpha:1.000]];
        [_settingView addSubview:view];
        
        _bannerView = [self createAndLoadBannerView];
        CGRect bannerTemp = _bannerView.frame;
        bannerTemp.origin.y = _settingView.frame.size.height;
        _bannerView.frame = bannerTemp;
        [_alphaView addSubview:_bannerView];
    }else{
        if (Is_iPad) {
            [_settingView setFrame:CGRectMake(- self.view.bounds.size.width * 0.4, 0, self.view.bounds.size.width * 0.4, self.view.bounds.size.height)];
        }else{
            [_settingView setFrame:CGRectMake(- self.view.bounds.size.width, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
        }
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        CGRect temp = self->_settingView.frame;
        temp.origin.x = 0;
        self->_settingView.frame = temp;
    } completion:^(BOOL finished) {
        
    }];
}

- (IBAction)onCloseSettingView:(id)sender{
    [UIView animateWithDuration:0.3 animations:^{
        CGRect temp = self->_settingView.frame;
        temp.origin.x = - self->_settingView.frame.size.width;
        self->_settingView.frame = temp;
    } completion:^(BOOL finished) {
        if (self->_bannerView) {
            [self->_bannerView removeFromSuperview];
            self->_bannerView.delegate = nil;
            self->_bannerView = nil;
        }
        if (self->_settingView) {
            [self->_settingView removeFromSuperview];
            self->_settingView = nil;
        }
        [self->_alphaView removeFromSuperview];
        self->_alphaView = nil;
    }];
}

- (void)adViewDidReceiveAd:(GADBannerView *)bannerView{
    if ([ProManager isProductPaid:AD_PRODUCT_ID] || [ProManager isFullPaid]) {
        bannerView.hidden = YES;
    }else{
        bannerView.hidden = NO;
    }
}

- (void)adView:(GADBannerView *)adView didFailToReceiveAdWithError:(GADRequestError *)error {
    NSLog(@"adView:didFailToReceiveAdWithError: %@", error.localizedDescription);
}

- (IBAction)onCameraBag:(id)sender{
    [_firstMaskView setHidden:NO];
    [UIView animateWithDuration:0.3 animations:^{
        CGRect temp = self->_firstView.frame;
        temp.origin.y = - self->_cameraHeight;
        self->_firstView.frame = temp;
    } completion:^(BOOL finished) {
        
    }];
}

- (UIImage *)getAnimateGifImage{
    NSString * themePath = [[ThemeManager sharedThemeManager] themePath];
    NSString * themeImagePath = [themePath stringByAppendingPathComponent:@"printing.gif"];
    NSData *data = [NSData dataWithContentsOfFile:themeImagePath];
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    
    size_t count = CGImageSourceGetCount(source);
    
    UIImage *animatedImage;
    
    if (count <= 1) {
        animatedImage = [[UIImage alloc] initWithData:data];
    }
    else {
        NSMutableArray *images = [NSMutableArray array];
        NSTimeInterval duration = 0.0f;
        
        for (size_t i = 0; i < count; i++) {
            CGImageRef image = CGImageSourceCreateImageAtIndex(source, i, NULL);
            
            duration += [self frameDurationAtIndex:i source:source];
            
            [images addObject:[UIImage imageWithCGImage:image scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp]];
            
            CGImageRelease(image);
        }
        
        if (!duration) {
            duration = (1.0f / 10.0f) * count;
        }
        animatedImage = [UIImage animatedImageWithImages:images duration:duration];
    }
    
    CFRelease(source);
    return animatedImage;
}

- (float)frameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source {
    float frameDuration = 0.1f;
    CFDictionaryRef cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil);
    NSDictionary *frameProperties = (__bridge NSDictionary *)cfFrameProperties;
    NSDictionary *gifProperties = frameProperties[(NSString *)kCGImagePropertyGIFDictionary];
    
    NSNumber *delayTimeUnclampedProp = gifProperties[(NSString *)kCGImagePropertyGIFUnclampedDelayTime];
    if (delayTimeUnclampedProp) {
        frameDuration = [delayTimeUnclampedProp floatValue];
    }
    else {
        
        NSNumber *delayTimeProp = gifProperties[(NSString *)kCGImagePropertyGIFDelayTime];
        if (delayTimeProp) {
            frameDuration = [delayTimeProp floatValue];
        }
    }
    
    if (frameDuration < 0.011f) {
        frameDuration = 0.100f;
    }
    
    CFRelease(cfFrameProperties);
    return frameDuration;
}

- (IBAction)onPress:(id)sender{
    BOOL isListPurchase = [[[_themeList objectAtIndex:_selectCameraIndex] objectForKey:@"isPurchase"] boolValue];
    if(isListPurchase == NO && [ProManager isProductPaid:[[_themeList objectAtIndex:_selectCameraIndex] objectForKey:@"ProductCode"]] == NO && [ProManager isFullPaid] == NO){
        if ([[[_themeList objectAtIndex:_selectCameraIndex] objectForKey:@"isAdFree"] boolValue] == YES) {
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
                [self.proManager buyProduct:[[self->_themeList objectAtIndex:self->_selectCameraIndex] objectForKey:@"ProductCode"]];
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
    
    AVAuthorizationStatus authorStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authorStatus == AVAuthorizationStatusAuthorized){
        if ([[SettingModel sharedInstance] isAutoSave]) {
            PHAuthorizationStatus authStatus = [PHPhotoLibrary authorizationStatus];
            if (PHAuthorizationStatusAuthorized == authStatus) {
                [self takePhoto];
            }else{
                [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                    
                }];
            }
        }else{
            [self takePhoto];
        }
        
    }else{
        [MBProgressHUD showErrorMessage:NSLocalizedString(@"NoAccessCamera", nil)];
    }
}

- (void)takePhoto{
    if (_headView.hidden == NO) {
        [_headView setImage:[self getAnimateGifImage]];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self->_headView setImage:[[ThemeManager sharedThemeManager] themeImageWithName:@"print"]];
        });
    }
    
    [MBProgressHUD showActivityMessageInWindow:NSLocalizedString(@"Processing", nil)];
    AVCaptureConnection *connect = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    if(connect.supportsVideoMirroring && !_isBack){
        connect.videoMirrored = YES;
    }
    connect.videoOrientation = AVCaptureVideoOrientationPortrait;
    
    NSLog(@"拍摄方向:%zd",connect.videoOrientation);
    if(!connect)
    {
        NSLog(@"拍照失败");
        [MBProgressHUD hideHUD];
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:connect completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if(imageDataSampleBuffer==NULL){
            [MBProgressHUD hideHUD];
            return;
        }
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage *image = [UIImage imageWithData:imageData];
        [weakSelf savePhotoWithImage:image];
    }];
    
    if ([[SettingModel sharedInstance] isSound]) {
        NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(onPlayAudio) object:nil];
        [thread start];
    }
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

- (void)savePhotoWithImage:(UIImage *)resultImage{
    PhotoEffectUtil *effectImage = [[PhotoEffectUtil alloc] init];
    UIImage *image = [effectImage getEffectImageWithOriImage:resultImage andDevice:_deviceOrientation];
    [MBProgressHUD hideHUD];
    
    NSString *fileName = [self getFileName];
    NSLog(@"%@",fileName);
    NSString *path_document = NSHomeDirectory();
    //设置一个图片的存储路径
    NSString *imagePath = [path_document stringByAppendingString:[NSString stringWithFormat:@"/Documents/%@.png",fileName]];
    //把图片直接保存到指定的路径（同时应该把图片的路径imagePath存起来，下次就可以直接用来取）
    if (image.size.width > image.size.height) {
        image = [image imageRotatedByDegrees:90];
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
    
    if ([_imageLists count] == 0) {
        [_imageLists addObject:fileName];
    }else{
        [_imageLists insertObject:fileName atIndex:0];
    }
    
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(onSaveImageCache) object:nil];
    [thread start];
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

- (void)onSaveImageCache{
    NSString *dataString = [_imageLists objectToJSONString];
    [[NSUserDefaults standardUserDefaults] setObject:dataString forKey:@"ClassicImage_FileName"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self refreshAlbumImage];
}

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

//初始化多媒体
- (void)initAVCaptureSession{
    self.session = [[AVCaptureSession alloc] init];
    [self.session setSessionPreset:AVCaptureSessionPresetPhoto];
    NSError *error;
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //更改这个设置的时候必须先锁定设备，修改完后再解锁，否则崩溃
    [device lockForConfiguration:nil];
    //设置闪光灯为自动
    if ([device isFlashModeSupported:AVCaptureFlashModeOff]) {
        [device setFlashMode:AVCaptureFlashModeOff];
    }
    [device unlockForConfiguration];
    
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
    if (error) {
        NSLog(@"%@",error);
    }
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    //输出设置。AVVideoCodecJPEG   输出jpeg格式图片
    NSDictionary * outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
    
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    if ([self.session canAddOutput:self.stillImageOutput]) {
        [self.session addOutput:self.stillImageOutput];
    }
    
    //初始化预览图层
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResize];
    self.previewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    [_firstView.layer addSublayer:self.previewLayer];
    [_firstView addSubview:_viewPortImage];
}

- (IBAction)onSelectCameraSkin:(UIButton *)sender{
    [self selectCameraSkinAtIndex:sender.tag - 1];
    [[ThemeManager sharedThemeManager] setThemeIndex:sender.tag - 1];
    [self refreshCameraLayout];
}

- (void)selectCameraSkinAtIndex:(NSInteger) index{
    _selectCameraIndex = index;
    UIButton *selectBtn = (UIButton *)[_cameraScrollView viewWithTag:index + 1];
    int distance = selectBtn.frame.origin.x + selectBtn.frame.size.width/2;
    CGRect temp = _selectIcon.frame;
    temp.origin.x = distance - 6;
    _selectIcon.frame = temp;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([object isEqual:_cameraScrollView]){
        [_selectionScrollView setContentOffset:_cameraScrollView.contentOffset];
    }
}

- (void)onPayForAd{
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
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onCloseSettingView:) name:HIDE_SETTING_ANIMATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onPayForAd) name:PAY_AD_PRODUCT object:nil];
    [_deviceMotion startMonitor];
    
    //照片名数组
    NSString *imageDetails = [[NSUserDefaults standardUserDefaults] objectForKey:@"ClassicImage_FileName"];
    _imageLists = [imageDetails objectFromJSONString];
    if (_imageLists == nil) {
        _imageLists = [NSMutableArray new];
    }
    
    [self refreshAlbumImage];
    
    if (self.session) {
        [self.session startRunning];
    }
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HIDE_SETTING_ANIMATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PAY_AD_PRODUCT object:nil];
    [_deviceMotion stop];
    if (self.session) {
        [self.session stopRunning];
    }
}

- (void)loadAppStoreController{
    if (@available(iOS 10.3, *)) {
        if([SKStoreReviewController respondsToSelector:@selector(requestReview)]) {
            [[UIApplication sharedApplication].keyWindow endEditing:YES];
            [SKStoreReviewController requestReview];
        }else{
            [self layoutAlertOrder];
        }
    } else {
        [self layoutAlertOrder];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"1" forKey:kStoreProductKey];
    [defaults synchronize];
}

- (void)layoutAlertOrder{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tip", nil) message:NSLocalizedString(@"Evaluate", nil) preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0) {
            [self goToAppStore];
        }else{
            NSString *urlStr = [NSString stringWithFormat:@"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@&pageNumber=0&sortOrdering=2&mt=8", APP_ID];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlStr]];
        }
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

-(void)goToAppStore{
    NSString *itunesurl = [NSString stringWithFormat:@"itms-apps://itunes.apple.com/cn/app/id%@?mt=8&action=write-review",APP_ID];;
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:itunesurl]];
}

@end
