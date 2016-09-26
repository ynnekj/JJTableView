//
//  JJHeadlineCell.h
//  JJTableViewExample
//
//  Created by jkenny on 16/9/9.
//  Copyright © 2016年 Jkenny. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger,JJHeadlineCellStatus) {
    JJHeadlineCellStatusEditable,
    JJHeadlineCellStatusCannotEdit,
    JJHeadlineCellStatusSelected
};


@interface JJHeadlineCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (nonatomic,assign) JJHeadlineCellStatus status;

- (void)setEdit:(BOOL)isEditing animated:(BOOL)animated;

@end
