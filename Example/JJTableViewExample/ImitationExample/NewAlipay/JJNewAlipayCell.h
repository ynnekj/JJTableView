//
//  JJNewAlipayCell.h
//  JJTableViewExample
//
//  Created by jkenny on 16/8/19.
//  Copyright © 2016年 Jkenny. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger,JJNewAlipayCellStatus) {
    JJNewAlipayCellStatusDelable = 1,
    JJNewAlipayCellStatusAddable,
    JJNewAlipayCellStatusOK
};

@class JJNewAlipayCell;


@protocol JJNewAlipayCellProtocol <NSObject>

- (void)cellOperationButtonDidClick:(JJNewAlipayCell *)cell;

@end


@interface JJNewAlipayCell : UIView

@property (weak, nonatomic) IBOutlet UIButton *operationButton;
@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (nonatomic,assign) JJNewAlipayCellStatus status;

@property (nonatomic,weak) id<JJNewAlipayCellProtocol> delegate;

- (void)setEdit:(BOOL)isEditing animated:(BOOL)animated;

@end
