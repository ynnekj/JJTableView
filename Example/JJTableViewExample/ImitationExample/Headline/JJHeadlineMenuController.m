//
//  JJHeadlineMenuController.m
//  JJTableViewExample
//
//  Created by jkenny on 16/9/9.
//  Copyright © 2016年 Jkenny. All rights reserved.
//

#import "JJHeadlineMenuController.h"
#import "JJHeadlineCell.h"
#import "JJHeadlineHeader.h"

static NSString *JJHeadlineCellIdentifier = @"JJHeadlineCell";
static NSString *JJHeadlineHeaderIdentifier = @"JJHeadlineHeader";

@interface JJHeadlineMenuController () <JJHeadlineHeaderProtocol>

@end

@implementation JJHeadlineMenuController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.automaticallyAdjustsScrollViewInsets = NO;
    [super setDatasWithPlistName:@"headline_menu"];
    
    UIButton *closeButton = [[UIButton alloc] init];
    [closeButton setTitle:@"✕" forState:UIControlStateNormal];
    [closeButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    closeButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    closeButton.titleLabel.font = [UIFont systemFontOfSize:24];
    closeButton.frame = CGRectMake(0, 0, 100, 30);
    [closeButton addTarget:self action:@selector(closeButtonDidClick:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
    
    UINib *headlineCellNib = [UINib nibWithNibName:JJHeadlineCellIdentifier bundle:nil];
    [self.tableView registerNib:headlineCellNib forCellReuseIdentifier:JJHeadlineCellIdentifier];
    
    UINib *headerNib = [UINib nibWithNibName:JJHeadlineHeaderIdentifier bundle:nil];
    [self.tableView registerNib:headerNib forHeaderViewReuseIdentifier:JJHeadlineHeaderIdentifier];
    
    self.tableView.cellCloseButtonLocation = JJTableViewCellCloseButtonLocationTopRight;
}

- (void)closeButtonDidClick:(UIButton *)button {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - JJTableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(JJTableView *)tableView {
    return self.datas.count;
}

- (NSInteger)tableView:(JJTableView *)tableView numberOfItemsInSection:(NSInteger)section {
    return self.datas[section].count;
}

- (UIView *)tableView:(JJTableView *)tableView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    JJHeadlineCell *cell = [tableView dequeueReusableCellWithIdentifier:JJHeadlineCellIdentifier];
    
    JJBaseModel *model = self.datas[indexPath.section][indexPath.item];
    cell.titleLabel.text = model.title;
    
    [cell setEdit:(self.tableView.editing && (indexPath.section == 0 && indexPath.item != 0)) animated:NO];
    
    if ([self.navigationItem.title isEqualToString:model.title]) {
        cell.status = JJHeadlineCellStatusSelected;
        
    } else if (indexPath.section == 0 && indexPath.item == 0) {
        cell.status = JJHeadlineCellStatusCannotEdit;
        
    } else {
        cell.status = JJHeadlineCellStatusEditable;
    }
    
    
    return cell;
}

#pragma mark - JJTableViewDelegate

- (NSUInteger)numberOfColunmsInTableView:(JJTableView *)tableView {
    return 4;
}

- (CGFloat)heightForCellInTableView:(JJTableView *)tableView {
    return 40;
}

- (nullable UIView *)tableView:(JJTableView *)tableView viewForHeaderInSection:(NSInteger)section {
    JJHeadlineHeader *headerView = [tableView dequeueReusableHeaderViewWithIdentifier:JJHeadlineHeaderIdentifier];
    
    if (section == 0) {
        headerView.titleLabel.text = @"我的频道";
        headerView.editButton.hidden = NO;
        headerView.delegate = self;
    } else {
        headerView.titleLabel.text = @"频道推荐";
        headerView.editButton.hidden = YES;
        headerView.detailLabel.hidden = YES;
    }
    
    return headerView;
}

- (CGFloat)tableView:(JJTableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 34;
}

- (CGFloat)tableView:(JJTableView *)tableView marginForType:(JJTableViewMarginType)type {
    switch (type) {
        case JJTableViewMarginTypeTop:
            return 18;
        case JJTableViewMarginTypeLeft:
            return 20;
        case JJTableViewMarginTypeRight:
            return 20;
        case JJTableViewMarginTypeBottom:
            return 0;
        case JJTableViewMarginTypeColumn:
            return 6;
        case JJTableViewMarginTypeRow:
            return 6;
        case JJTableViewMarginTypeHeaderLeading:
            return 0;
        case JJTableViewMarginTypeHeaderTrailing:
            return 0;
        case JJTableViewMarginTypeSectionLeading:
            return 18;
        case JJTableViewMarginTypeSectionTrailing:
            return 16;
    }
}

- (BOOL)tableView:(JJTableView *)tableView canMoveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath {
    if (destinationIndexPath.section == 0 && destinationIndexPath.item == 0) {
        return NO;
    }
    return YES;
}

- (BOOL)tableView:(JJTableView *)tableView canLongPressAndMoveItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1 || (indexPath.section == 0 && indexPath.item == 0)) {
        return NO;
    }
    return YES;
}

- (void)tableView:(JJTableView *)tableView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    [self moveItemAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
    
    if (sourceIndexPath.section == 0 && destinationIndexPath.section == 1) {
        JJHeadlineCell *selectedCell = [self.tableView cellForItemAtIndexPath:destinationIndexPath];
        [selectedCell setEdit:NO animated:YES];
    }
}

- (void)tableView:(JJTableView *)tableView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    JJHeadlineCell *selectedCell = [self.tableView cellForItemAtIndexPath:indexPath];
    
    if (indexPath.section == 1) {
        if (self.tableView.isEditing) {
            [selectedCell setEdit:YES animated:YES];
        }
        
        NSIndexPath *destinationIndexPath = [NSIndexPath indexPathForItem:self.datas.firstObject.count inSection:0];
        [self moveItemAtIndexPath:indexPath toIndexPath:destinationIndexPath];
        
        NSIndexPath *toIndexPath = [NSIndexPath indexPathForItem:self.datas.firstObject.count - 1 inSection:0];
        [self.tableView moveItemAtIndexPath:indexPath toIndexPath:toIndexPath];
        
    } else if (self.tableView.isEditing) {
        if (indexPath.section == 0 && indexPath.item == 0) {
            return;
        }
        
        [selectedCell setEdit:NO animated:YES];
        
        NSIndexPath *destinationIndexPath = [NSIndexPath indexPathForItem:0 inSection:self.datas.count - 1];
        [self moveItemAtIndexPath:indexPath toIndexPath:destinationIndexPath];
        
        [self.tableView moveItemAtIndexPath:indexPath toIndexPath:destinationIndexPath];
        
    } else {
        JJBaseModel *baseModel = self.datas[indexPath.section][indexPath.item];
        self.navigationItem.title = baseModel.title;
    }
}

#pragma mark - JJHeadlineHeaderProtocol

- (void)header:(JJHeadlineHeader *)header operationButtonStatusDidChanged:(BOOL)editing {
    self.tableView.editing = editing;
    
    for (JJHeadlineCell *cell in self.tableView.visibleCells) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        
        if (indexPath.section == 0 && indexPath.item != 0) {
            [cell setEdit:editing animated:YES];
        }
    }

}

- (void)moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    JJBaseModel *baseModel = [self.datas[sourceIndexPath.section] objectAtIndex:sourceIndexPath.item];
    [self.datas[sourceIndexPath.section] removeObjectAtIndex:sourceIndexPath.item];
    [self.datas[destinationIndexPath.section] insertObject:baseModel atIndex:destinationIndexPath.item];
}

@end
