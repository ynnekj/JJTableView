//
//  JJHeadlineCell.m
//  JJTableViewExample
//
//  Created by jkenny on 16/9/9.
//  Copyright © 2016年 Jkenny. All rights reserved.
//

#import "JJHeadlineCell.h"

#define JJDuration 0.3

@interface JJHeadlineCell ()

@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIView *borderlineView;
@property (nonatomic,assign,getter=isEditing) BOOL editing;

@end

@implementation JJHeadlineCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.borderlineView.layer.borderColor = [UIColor colorWithRed:0.836 green:0.844 blue:0.844 alpha:1.000].CGColor;
    self.borderlineView.layer.borderWidth = 1 / [UIScreen mainScreen].scale;
    
    self.closeButton.transform = CGAffineTransformMakeScale(0.01, 0.01);
    self.editing = NO;
}

- (void)setEdit:(BOOL)isEditing animated:(BOOL)animated {
    if (isEditing == self.isEditing) return;
    self.editing = isEditing;
    
    [self setOperationButtonVisible:isEditing animated:animated];
}

- (void)setOperationButtonVisible:(BOOL)visible animated:(BOOL)animated {
    if (animated) {
        if (visible) {
            self.closeButton.hidden = !visible;
            self.closeButton.transform = CGAffineTransformMakeScale(0.01, 0.01);
        }
        
        [UIView animateWithDuration:JJDuration animations:^{
            if (visible) {
                self.closeButton.transform = CGAffineTransformIdentity;
            } else {
                self.closeButton.transform = CGAffineTransformMakeScale(0.01, 0.01);
            }
            
        } completion:^(BOOL finished) {
            if (!visible) {
                self.closeButton.hidden = !visible;
            }
        }];
        
    } else {
        self.closeButton.transform = CGAffineTransformIdentity;
        self.closeButton.hidden = !visible;
    }
}

- (void)setStatus:(JJHeadlineCellStatus)status {
    if (_status == status) return;
    
    _status = status;
    switch (status) {
        case JJHeadlineCellStatusEditable:
            self.titleLabel.textColor = [UIColor blackColor];
            break;
            
        case JJHeadlineCellStatusCannotEdit:
            self.titleLabel.textColor = [UIColor lightGrayColor];
            break;
            
        case JJHeadlineCellStatusSelected:
            self.titleLabel.textColor = [UIColor redColor];
            break;
    }
}

@end
