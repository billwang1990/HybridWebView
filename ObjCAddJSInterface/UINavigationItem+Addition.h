//
//  UINavigationItem+Addition.h
//  YanJiYou
//
//  Created by ikamobile-ios on 14-5-20.
//  Copyright (c) 2014年 billwang1990.github.io. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UINavigationItem (Addition)

- (UIBarButtonItem*)setNavigationBarItemWithImage:(UIImage *)image andTarget:(id)target action:(SEL)action isLeftItem:(BOOL)isLeft;

- (UIBarButtonItem *)setNavigationBarItemWithTitle:(NSString *)title andTarget:(id)target action:(SEL)action isLeftItem:(BOOL)isLeft;
@end
