//
//  JJClickEffectView.m
//  JJTableViewExample
//
//  Created by jkenny on 16/9/12.
//  Copyright © 2016年 Jkenny. All rights reserved.
//

#import "JJClickEffectView.h"

#define JJDuration 0.35

@implementation JJClickEffectView

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self alphaChanage];
}

- (void)alphaChanage {
    [UIView animateWithDuration:JJDuration animations:^{
        self.alpha = 0.5;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:JJDuration animations:^{
            self.alpha = 1;
        }];
    }];
}

@end