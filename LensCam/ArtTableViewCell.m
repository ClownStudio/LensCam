//
//  ArtTableViewCell.m
//  LensCam
//
//  Created by 张文洁 on 2018/10/26.
//  Copyright © 2018 JamStudio. All rights reserved.
//

#import "ArtTableViewCell.h"
#import "Macro.h"
#import <XLPhotoBrowser.h>

#define kArtGap 5

@implementation ArtTableViewCell{
    UIScrollView *_scrollView;
    NSMutableArray *_data;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self){
        [self setBackgroundColor:[UIColor blackColor]];
        
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(kArtGap, kArtGap, WIDTH - kArtGap, 250 - 2*kArtGap)];
        [self addSubview:_scrollView];
    }
    return  self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setContentWithDataSource:(NSArray *)dataSource{
    for (UIView *view in _scrollView.subviews) {
        [view removeFromSuperview];
    }
    
    _data = [NSMutableArray new];
    CGFloat distance = 0;
    for (int i = 0; i < [dataSource count]; i++) {
        UIImage *image = [UIImage imageNamed:[dataSource objectAtIndex:i]];
        [_data addObject:image];
        UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(distance, 0, (250 - 2*kArtGap)/image.size.height * image.size.width, 250 - 2*kArtGap)];
        [imageView setImage:image];
        distance += imageView.bounds.size.width;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
        [imageView addGestureRecognizer:tap];
        [imageView setUserInteractionEnabled:YES];
        imageView.tag = i+1;
        [_scrollView addSubview:imageView];
    }
    [_scrollView setContentSize:CGSizeMake(distance + kArtGap, 0)];
}

- (void)onTap:(UITapGestureRecognizer *)tap{
    if (_data && [_data count] >0) {
        [XLPhotoBrowser showPhotoBrowserWithImages:_data currentImageIndex:tap.view.tag - 1];
    }
}

@end
