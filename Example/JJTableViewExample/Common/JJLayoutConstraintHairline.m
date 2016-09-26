//
//  JJLayoutConstraintHairline.m
//  JJTableViewExample
//
//  Created by jkenny on 16/8/24.
//  Copyright © 2016年 Jkenny. All rights reserved.
//

#import "JJLayoutConstraintHairline.h"

#define SINGLE_LINE_WIDTH           (1 / [UIScreen mainScreen].scale)
#define SINGLE_LINE_ADJUST_OFFSET   ((1 / [UIScreen mainScreen].scale) / 2)

@implementation JJLayoutConstraintHairline

- (void) awakeFromNib{
    [super awakeFromNib];
    if(self.constant == 1)self.constant = (1 / [UIScreen mainScreen].scale);
}

@end
