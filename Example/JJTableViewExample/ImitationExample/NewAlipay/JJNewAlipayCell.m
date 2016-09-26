//
//  JJNewAlipayCell.m
//  JJTableViewExample
//
//  Created by jkenny on 16/8/19.
//  Copyright © 2016年 Jkenny. All rights reserved.
//

#import "JJNewAlipayCell.h"

#define JJDuration 0.3

@interface JJNewAlipayCell ()

@property (nonatomic,strong) CALayer *borderLayer;
@property (nonatomic,assign,getter=isEditing) BOOL editing;

@end

@implementation JJNewAlipayCell

- (IBAction)operationButtonDidclick:(UIButton *)sender {
    if (self.status != JJNewAlipayCellStatusOK && [self.delegate respondsToSelector:@selector(cellOperationButtonDidClick:)]) {
        [self.delegate cellOperationButtonDidClick:self];
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code    
    self.operationButton.transform = CGAffineTransformMakeScale(0.01, 0.01);
    self.editing = NO;
}

- (void)setEditing:(BOOL)editing {
    _editing = editing;
}

- (CALayer *)borderLayer {
    if (!_borderLayer) {
        CALayer *lineLayer = [CALayer layer];
        lineLayer.borderWidth = 1 / [UIScreen mainScreen].scale;
        lineLayer.borderColor = [UIColor lightGrayColor].CGColor;
        lineLayer.frame = self.layer.bounds;
        lineLayer.opacity = 0;
        [self.layer addSublayer:lineLayer];
        
        _borderLayer = lineLayer;
    }
    return _borderLayer;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.borderLayer.frame = self.layer.bounds;
}

- (void)setStatus:(JJNewAlipayCellStatus)status {
    if (_status == status) return;
    
    _status = status;
    switch (status) {
        case JJNewAlipayCellStatusAddable:
            [self.operationButton setImage:[UIImage imageNamed:@"app_add"] forState:UIControlStateNormal];
            break;
            
        case JJNewAlipayCellStatusDelable:
            [self.operationButton setImage:[UIImage imageNamed:@"app_del"] forState:UIControlStateNormal];
            break;
            
        case JJNewAlipayCellStatusOK:
            [self.operationButton setImage:[UIImage imageNamed:@"app_ok"] forState:UIControlStateNormal];
            break;
    }
}

- (void)setEdit:(BOOL)isEditing animated:(BOOL)animated {
    if (isEditing == self.isEditing) return;
    self.editing = isEditing;
    
    [self setborderLayerVisible:isEditing animated:animated];
    [self setOperationButtonVisible:isEditing animated:animated];
}

- (void)setborderLayerVisible:(BOOL)visible animated:(BOOL)animated {
    [self.borderLayer removeAnimationForKey:@"opacityAnim"];
    
    if (animated) {
        self.borderLayer.opacity = 0;
        CABasicAnimation* bAnim = [CABasicAnimation animationWithKeyPath:@"opacity"];
        bAnim.removedOnCompletion = NO;
        bAnim.fillMode = kCAFillModeForwards;
        bAnim.duration = JJDuration;
        bAnim.delegate = self;
    
        if (visible) {
            bAnim.toValue = @(1);
        } else {
            bAnim.fromValue = @(1);
        }
        [self.borderLayer addAnimation:bAnim forKey:@"opacityAnim"];
    
    } else {
        if (visible) {
            self.borderLayer.opacity = 1;
        } else {
            self.borderLayer.opacity = 0;
        }
    }
}

- (void)setOperationButtonVisible:(BOOL)visible animated:(BOOL)animated {
    if (animated) {
        if (visible) {
            self.operationButton.hidden = !visible;
            self.operationButton.transform = CGAffineTransformMakeScale(0.01, 0.01);
        }
        
        [UIView animateWithDuration:JJDuration animations:^{
            if (visible) {
                self.operationButton.transform = CGAffineTransformIdentity;
            } else {
                self.operationButton.transform = CGAffineTransformMakeScale(0.01, 0.01);
            }
            
        } completion:^(BOOL finished) {
            if (!visible) {
                self.operationButton.hidden = !visible;
            }
        }];
        
    } else {
        self.operationButton.transform = CGAffineTransformIdentity;
        self.operationButton.hidden = !visible;
    }
}

#pragma mark - CAAnimationDelegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    self.borderLayer.opacity = self.isEditing ? 1 : 0;
}

@end
