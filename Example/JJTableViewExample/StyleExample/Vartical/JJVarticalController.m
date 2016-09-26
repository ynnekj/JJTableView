//
//  JJVarticalController.m
//  JJTableViewExample
//
//  Created by jkenny on 16/9/18.
//  Copyright © 2016年 Jkenny. All rights reserved.
//

#import "JJVarticalController.h"
#import "JJBaseCell.h"

@interface JJVarticalController ()

@end

static NSString *JJHorizentalCellIdentifier = @"JJBaseCell";

@implementation JJVarticalController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [super setDatasWithPlistName:@"vartical"];
    
    UINib *pagingCellNib = [UINib nibWithNibName:JJHorizentalCellIdentifier bundle:nil];
    [self.tableView registerNib:pagingCellNib forCellReuseIdentifier:JJHorizentalCellIdentifier];
    
    self.tableView.separatorStyle = JJTableViewSeparatorStyleAll;
}

#pragma mark - JJTableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(JJTableView *)tableView {
    return self.datas.count;
}

- (NSInteger)tableView:(JJTableView *)tableView numberOfItemsInSection:(NSInteger)section {
    return self.datas[section].count;
}

- (UIView *)tableView:(JJTableView *)tableView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    JJBaseCell *cell = [tableView dequeueReusableCellWithIdentifier:JJHorizentalCellIdentifier];
    JJBaseModel *model = self.datas[indexPath.section][indexPath.item];
    cell.titleLabel.text = model.title;
    cell.imageView.image = [UIImage imageNamed:model.icon];
    
    return cell;
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


#pragma mark - JJTableViewDelegate

- (NSUInteger)numberOfColunmsInTableView:(JJTableView *)tableView {
    return 3;
}

- (nullable NSString *)tableView:(JJTableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.titles[section];
}

- (CGFloat)heightForCellInTableView:(JJTableView *)tableView {
    return 100;
}

- (CGFloat)tableView:(JJTableView *)tableView marginForType:(JJTableViewMarginType)type {
    switch (type) {
        case JJTableViewMarginTypeTop:
            return 10;
        case JJTableViewMarginTypeLeft:
            return 8;
        case JJTableViewMarginTypeRight:
            return 8;
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
            return 10;
        case JJTableViewMarginTypeSectionTrailing:
            return 10;
    }
}

@end
