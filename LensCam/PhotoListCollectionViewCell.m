//
//  PhotoListCollectionViewCell.m
//  LensCam
//
//  Created by 张文洁 on 2018/11/6.
//  Copyright © 2018 JamStudio. All rights reserved.
//

#import "PhotoListCollectionViewCell.h"
#import "ThemeManager.h"

@implementation PhotoListCollectionViewCell{
    UIButton *_delBtn;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self.layer setMasksToBounds:YES];
        [self.layer setCornerRadius:5];
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [self addSubview:self.imageView];
        
        _delBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.bounds.size.width * 0.8, 0, self.bounds.size.width * 0.2, self.bounds.size.width * 0.2)];
        [_delBtn setImage:[[ThemeManager sharedThemeManager] themeImageWithName:@"album_del"] forState:UIControlStateNormal];
        [_delBtn addTarget:self action:@selector(onDeletePhoto:) forControlEvents:UIControlEventTouchUpInside];
        _delBtn.hidden = YES;
        [self addSubview:_delBtn];
    }
    return self;
}

- (IBAction)onDeletePhoto:(UIButton *)sender{
    self.deleteBlock(sender.tag);
}

- (void)setImageWithImages:(NSArray *)images andIndex:(NSInteger)index andIsEdit:(BOOL)isEdit{
    NSString *imagePath = [images objectAtIndex:index];
    NSString *path_document = NSHomeDirectory();
    NSString *imageUrl = [path_document stringByAppendingString:[NSString stringWithFormat:@"/Documents/%@.jpg",imagePath]];
    UIImage *image = [UIImage imageWithContentsOfFile:imageUrl];
    [self.imageView setImage:image];
    if (isEdit) {
        _delBtn.hidden = NO;
    }else{
        _delBtn.hidden = YES;
    }
    _delBtn.tag = index + 1;
}

@end
