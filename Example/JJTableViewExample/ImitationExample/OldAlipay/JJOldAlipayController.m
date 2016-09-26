//
//  JJViewController.m
//  JJTableViewExample
//
//  Created by jkenny on 16/8/19.
//  Copyright © 2016年 Jkenny. All rights reserved.
//

#import "JJOldAlipayController.h"
#import "JJTableView.h"
#import "JJOldAlipayCell.h"
#import "JJOldAlipayController.h"

@interface JJOldAlipayController ()

@end

static NSString *JJOldAlipayCellIdentifier = @"JJOldAlipayCell";
static NSString *JJOldAlipayBannerHeaderIdentifier = @"JJOldAlipayBannerHeader";

@implementation JJOldAlipayController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = false;
    [super setDatasWithPlistName:@"old_alipay_menu"];
    
    // 注册 cell
    UINib *oldAlipayCellNib = [UINib nibWithNibName:JJOldAlipayCellIdentifier bundle:nil];
    [self.tableView registerNib:oldAlipayCellNib forCellReuseIdentifier:JJOldAlipayCellIdentifier];
    
    // 注册 header view
    UINib *oldAlipayHeaderNib = [UINib nibWithNibName:JJOldAlipayBannerHeaderIdentifier bundle:nil];
    [self.tableView registerNib:oldAlipayHeaderNib forHeaderViewReuseIdentifier:JJOldAlipayBannerHeaderIdentifier];
    
    self.tableView.separatorStyle = JJTableViewSeparatorStyleCellOutlineBorderTopBottomLine | JJTableViewSeparatorStyleRowColumnSingleLine;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - JJTableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(JJTableView *)tableView {
    return self.datas.count;
}

- (NSInteger)tableView:(JJTableView *)tableView numberOfItemsInSection:(NSInteger)section {
    return self.datas[section].count;
}

- (UIView *)tableView:(JJTableView *)tableView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    JJOldAlipayCell *cell = [tableView dequeueReusableCellWithIdentifier:JJOldAlipayCellIdentifier];
    
    JJBaseModel *model = self.datas[indexPath.section][indexPath.item];
    cell.title.text = model.title;
    cell.iconView.image = [UIImage imageNamed:model.icon];
    
    return cell;
}

#pragma mark - JJTableViewDelegate

- (NSUInteger)numberOfColunmsInTableView:(JJTableView *)tableView {
    return 4;
}

- (NSUInteger)numberOfRowsInTableView:(JJTableView *)tableView {
    return 2;
}

- (CGFloat)heightForCellInTableView:(JJTableView *)tableView {
    return 100;
}

- (CGFloat)tableView:(JJTableView *)tableView marginForType:(JJTableViewMarginType)type {
    switch (type) {
        case JJTableViewMarginTypeTop:
            return 0;
        case JJTableViewMarginTypeLeft:
            return 0;
        case JJTableViewMarginTypeRight:
            return 0;
        case JJTableViewMarginTypeBottom:
            return 0;
        case JJTableViewMarginTypeColumn:
            return 0;
        case JJTableViewMarginTypeRow:
            return 0;
        case JJTableViewMarginTypeHeaderLeading:
            return 0;
        case JJTableViewMarginTypeHeaderTrailing:
            return 0;
        case JJTableViewMarginTypeSectionLeading:
            return 0;
        case JJTableViewMarginTypeSectionTrailing:
            return 0;
    }
}

- (CGFloat)tableView:(JJTableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 0;
    }
    return 130;
}

- (UIView *)tableView:(JJTableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        UIView *headerView = [tableView dequeueReusableHeaderViewWithIdentifier:JJOldAlipayBannerHeaderIdentifier];
        return headerView;
    }
    return nil;
}

- (void)tableView:(JJTableView *)tableView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath {
    JJBaseModel *baseModel = [self.datas[sourceIndexPath.section] objectAtIndex:sourceIndexPath.item];
    [self.datas[sourceIndexPath.section] removeObjectAtIndex:sourceIndexPath.item];
    [self.datas[destinationIndexPath.section] insertObject:baseModel atIndex:destinationIndexPath.item];
}

- (void)tableView:(JJTableView *)tableView didClickItemCloseButtonAtIndexPath:(NSIndexPath *)indexPath {
    [self.datas[indexPath.section] removeObjectAtIndex:indexPath.item];
    [tableView deleteItemAtIndexPath:indexPath withItemAnimation:JJTableViewItemAnimationShrink];
}

@end
