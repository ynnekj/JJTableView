//
//  JJHeadlineHeader.h
//  JJTableViewExample
//
//  Created by jkenny on 16/9/9.
//  Copyright © 2016年 Jkenny. All rights reserved.
//

#import <UIKit/UIKit.h>

@class JJHeadlineHeader;

@protocol JJHeadlineHeaderProtocol <NSObject>

- (void)header:(JJHeadlineHeader *)header operationButtonStatusDidChanged:(BOOL)editing;

@end


@interface JJHeadlineHeader : UIView

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;
@property (weak, nonatomic) IBOutlet UIButton *editButton;

@property (nonatomic,weak) id<JJHeadlineHeaderProtocol> delegate;

@end
