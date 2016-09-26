//
//  JJHeadlineHeader.m
//  JJTableViewExample
//
//  Created by jkenny on 16/9/9.
//  Copyright © 2016年 Jkenny. All rights reserved.
//

#import "JJHeadlineHeader.h"

@interface JJHeadlineHeader ()

@property (nonatomic,assign,getter=isEditing) BOOL editing;

@end


@implementation JJHeadlineHeader

- (void)awakeFromNib {
    [super awakeFromNib];
    self.editButton.layer.borderWidth = 1 / [UIScreen mainScreen].scale;
    self.editButton.layer.borderColor = [UIColor colorWithRed:0.984 green:0.376 blue:0.337 alpha:1.000].CGColor;
    self.editButton.layer.cornerRadius = self.editButton.frame.size.height / 2;
}

- (IBAction)editButtonDidClick:(UIButton *)sender {
    self.editing = !self.isEditing;
    [self.editButton setTitle:self.isEditing ? @"完成" : @"编辑" forState:UIControlStateNormal];
    self.detailLabel.hidden = !self.editing;
    
    if ([self.delegate respondsToSelector:@selector(header:operationButtonStatusDidChanged:)]) {
        [self.delegate header:self operationButtonStatusDidChanged:self.isEditing];
    }
}



@end
