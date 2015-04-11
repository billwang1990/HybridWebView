//
//  UINavigationItem+Addition.m
//  YanJiYou
//
//  Created by ikamobile-ios on 14-5-20.
//  Copyright (c) 2014年 billwang1990.github.io. All rights reserved.
//

#import "UINavigationItem+Addition.h"

@implementation UINavigationItem (Addition)

- (UIBarButtonItem *)setNavigationBarItemWithTitle:(NSString *)title andTarget:(id)target action:(SEL)action isLeftItem:(BOOL)isLeft
{
    UIBarButtonItem *item;
    
    CGSize constraint = CGSizeMake(CGFLOAT_MAX,24);
    NSDictionary * tdic = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:17] , NSFontAttributeName,nil];
    
    CGSize size =[title boundingRectWithSize:constraint options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:tdic context:nil].size;
    
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setFrame:CGRectMake(0, 0, MIN(ceilf(size.width)+3, 100), 30)];
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    [button.titleLabel setFont:[UIFont systemFontOfSize:17]];

    item = [[UIBarButtonItem alloc] initWithCustomView:button];

    if (isLeft) {
        self.leftBarButtonItem = item;
    }
    else
    {
        self.rightBarButtonItem = item;
    }
    
    return item;
}

- (UIBarButtonItem *)setNavigationBarItemWithImage:(UIImage *)image andTarget:(id)target action:(SEL)action isLeftItem:(BOOL)isLeft
{
    UIBarButtonItem *item;
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 20, 20)];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.clipsToBounds = YES;
    [imageView setImage:image];
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc]initWithTarget:target action:action];
    imageView.userInteractionEnabled = YES;
    [imageView addGestureRecognizer:tapGes];
    
    item = [[UIBarButtonItem alloc] initWithCustomView:imageView];
    
    if (isLeft) {
        self.leftBarButtonItem = item;
    }
    else
    {
        self.rightBarButtonItem = item;
    }
    return item;
}
@end
