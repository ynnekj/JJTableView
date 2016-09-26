//
//  JJNewAlipayController.m
//  JJTableViewExample
//
//  Created by jkenny on 16/9/1.
//  Copyright © 2016年 Jkenny. All rights reserved.
//

#import "JJNewAlipayController.h"
#import "JJNewAlipayCell.h"

static NSString *JJNewAlipayCellIdentifier = @"JJNewAlipayCell";
static NSString *JJNewAlipaySeparatorHeaderIdentifier = @"JJNewAlipaySeparatorHeader";

@interface JJNewAlipayController () <JJNewAlipayCellProtocol>

@property (nonatomic,assign,getter=isEditing) BOOL editing;
@property (nonatomic,strong) UIButton *editButton;

@end

@implementation JJNewAlipayController

- (JJNewAlipayCellStatus)statusForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return JJNewAlipayCellStatusDelable;
    }
    
    JJBaseModel *model = self.datas[indexPath.section][indexPath.item];
    for (JJBaseModel *selectedItem in self.datas.firstObject) {
        if ([selectedItem.title isEqualToString:model.title]) {
            return JJNewAlipayCellStatusOK;
        }
    }
    
    return JJNewAlipayCellStatusAddable;
}

- (NSIndexPath *)indexPathWithDeleteModel:(JJBaseModel *)baseModel {
    if (self.datas.count <= 0) return nil;
    
    for (int sectionCount = 1; sectionCount < self.datas.count; sectionCount++) {
        for (int itemCount = 0; itemCount < self.datas[sectionCount].count; itemCount++) {
            JJBaseModel *model = self.datas[sectionCount][itemCount];
            if ([baseModel.title isEqualToString:model.title]) {
                return [NSIndexPath indexPathForItem:itemCount inSection:sectionCount];
            }
        }
    }
    return nil;
}

- (UIButton *)editButton {
    if (!_editButton) {
        UIButton *editButton = [[UIButton alloc] init];
        [editButton setTitle:@"管理" forState:UIControlStateNormal];
        [editButton setTitleColor:[UIColor colorWithRed:0.000 green:0.384 blue:1.000 alpha:1.000] forState:UIControlStateNormal];
        editButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        editButton.titleLabel.font = [UIFont systemFontOfSize:16];
        editButton.frame = CGRectMake(0, 0, 100, 30);
        [editButton addTarget:self action:@selector(editButtonDidClick:) forControlEvents:UIControlEventTouchUpInside];
        
        _editButton = editButton;
    }
    return _editButton;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.automaticallyAdjustsScrollViewInsets = NO;
    [super setDatasWithPlistName:@"new_alipay_menu"];
    
    UINib *newAlipayCell = [UINib nibWithNibName:JJNewAlipayCellIdentifier bundle:nil];
    [self.tableView registerNib:newAlipayCell forCellReuseIdentifier:JJNewAlipayCellIdentifier];
    
    UINib *oldAlipayHeaderNib = [UINib nibWithNibName:JJNewAlipaySeparatorHeaderIdentifier bundle:nil];
    [self.tableView registerNib:oldAlipayHeaderNib forHeaderViewReuseIdentifier:JJNewAlipaySeparatorHeaderIdentifier];
    
    self.tableView.separatorStyle = JJTableViewSeparatorStyleHeaderLeadingSingleLine;
    
    self.tableView.headerBackgroundColor = [UIColor whiteColor];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.editButton];
}

- (void)setEditing:(BOOL)editing {
    _editing = editing;
    self.tableView.editing = editing;
}

- (void)editButtonDidClick:(UIButton *)editButton {
    [self.editButton setTitle:self.isEditing ? @"管理" : @"完成" forState:UIControlStateNormal];
    self.editing = !self.isEditing;
    
    for (JJNewAlipayCell *cell in self.tableView.visibleCells) {
        [cell setEdit:self.editing animated:YES];
    }
}

#pragma mark - JJTableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(JJTableView *)tableView {
    return self.datas.count;
}

- (NSInteger)tableView:(JJTableView *)tableView numberOfItemsInSection:(NSInteger)section {
    return self.datas[section].count;
}

- (UIView *)tableView:(JJTableView *)tableView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    JJNewAlipayCell *cell = [tableView dequeueReusableCellWithIdentifier:JJNewAlipayCellIdentifier];
    
    JJBaseModel *model = self.datas[indexPath.section][indexPath.item];
    cell.title.text = model.title;
    cell.iconView.image = [UIImage imageNamed:model.icon];
    cell.status = model.status;
    
    [cell setEdit:self.editing animated:NO];
    
    if (!cell.delegate) {
        cell.delegate = self;
    }
    
    return cell;
}

#pragma mark JJTableViewDelegate

- (NSUInteger)numberOfColunmsInTableView:(JJTableView *)tableView {
    return 4;
}

- (CGFloat)tableView:(JJTableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return 48;
    }
    return 36;
}

- (UIView *)tableView:(JJTableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        UIView *headerView = [tableView dequeueReusableHeaderViewWithIdentifier:JJNewAlipaySeparatorHeaderIdentifier];
        return headerView;
    }
    return nil;
}
- (CGFloat)heightForCellInTableView:(JJTableView *)tableView {
    return 84;
}

- (CGFloat)tableView:(JJTableView *)tableView marginForType:(JJTableViewMarginType)type {
    switch (type) {
        case JJTableViewMarginTypeTop:
            return 0;
        case JJTableViewMarginTypeLeft:
            return 8;
        case JJTableViewMarginTypeRight:
            return 8;
        case JJTableViewMarginTypeBottom:
            return 0;
        case JJTableViewMarginTypeColumn:
            return 10;
        case JJTableViewMarginTypeRow:
            return 6;
        case JJTableViewMarginTypeHeaderLeading:
            return 0;
        case JJTableViewMarginTypeHeaderTrailing:
            return 0;
        case JJTableViewMarginTypeSectionLeading:
            return 0;
        case JJTableViewMarginTypeSectionTrailing:
            return 18;
    }
}

- (nullable NSString *)tableView:(JJTableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.titles[section];
}

- (void)tableView:(JJTableView *)tableView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath {
    JJBaseModel *baseModel = [self.datas[sourceIndexPath.section] objectAtIndex:sourceIndexPath.item];
    [self.datas[sourceIndexPath.section] removeObjectAtIndex:sourceIndexPath.item];
    [self.datas[destinationIndexPath.section] insertObject:baseModel atIndex:destinationIndexPath.item];
}

- (BOOL)tableView:(JJTableView *)tableView canLongPressAndMoveItemAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.editing) {
        [self editButtonDidClick:nil];
    }
    
    if (indexPath.section == 0) {
        return YES;
    }
    return NO;
}

- (BOOL)tableView:(JJTableView *)tableView canMoveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath {
    NSLog(@"sourceIndexPath = %@",sourceIndexPath);
    NSLog(@"destinationIndexPath = %@",destinationIndexPath);
    
    if (destinationIndexPath.section > 0) {
        return NO;
    }
    return YES;
}

#pragma mark - JJNewAlipayCellProtocol

- (void)cellOperationButtonDidClick:(JJNewAlipayCell *)cell {
    NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
    JJBaseModel *selectedModel = self.datas[cellIndexPath.section][cellIndexPath.item];
    
    if (cellIndexPath.section == 0) {
        [self.datas.firstObject removeObjectAtIndex:cellIndexPath.item];
        [self.tableView deleteItemAtIndexPath:cellIndexPath withItemAnimation:JJTableViewItemAnimationShrink];
        
        NSIndexPath *sourceIndexPath = [self indexPathWithDeleteModel:selectedModel];
        JJBaseModel *sourceModel = self.datas[sourceIndexPath.section][sourceIndexPath.item];
        sourceModel.status = JJNewAlipayCellStatusAddable;
        [self.tableView reloadItemAtIndexPath:sourceIndexPath withItemAnimation:JJTableViewItemAnimationFade];
        
    } else {
        // 无移动效果
        // JJBaseModel *newModel = [selectedModel mutableCopy];
        // newModel.status = JJNewAlipayCellStatusDelable;
        //
        // [self.datas.firstObject addObject:newModel];
        // NSIndexPath *insertIP = [NSIndexPath indexPathForItem:self.datas.firstObject.count - 1 inSection:0];
        // [self.tableView insertItemAtIndexPath:insertIP withItemAnimation:JJTableViewItemAnimationShrink];
        //
        // selectedModel.status = JJNewAlipayCellStatusOK;
        // [self.tableView reloadItemAtIndexPath:cellIndexPath withItemAnimation:JJTableViewItemAnimationNone];
        
        
        // 有移动效果
        JJBaseModel *newModel = [selectedModel mutableCopy];
        newModel.status = JJNewAlipayCellStatusDelable;
        
        [self.datas[cellIndexPath.section] insertObject:newModel atIndex:cellIndexPath.item];
        [self.tableView insertItemAtIndexPath:cellIndexPath withItemAnimation:JJTableViewItemAnimationNone];

        JJBaseModel *moveModel = self.datas[cellIndexPath.section][cellIndexPath.item];
        [self.datas.firstObject addObject:moveModel];
        [self.datas[cellIndexPath.section] removeObjectAtIndex:cellIndexPath.item];
        
        NSIndexPath *insertIP = [NSIndexPath indexPathForItem:self.datas.firstObject.count - 1 inSection:0];
        [self.tableView moveItemAtIndexPath:cellIndexPath toIndexPath:insertIP];
        
        // 未知问题，必须延时一下不然，会导致内部无法获取当前移动动画 view 的frame
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tableView reloadItemAtIndexPath:insertIP withItemAnimation:JJTableViewItemAnimationShrink];
        });
        
        JJBaseModel *reloadModel = self.datas[cellIndexPath.section][cellIndexPath.item];
        reloadModel.status = JJNewAlipayCellStatusOK;
        [self.tableView reloadItemAtIndexPath:cellIndexPath withItemAnimation:JJTableViewItemAnimationFade];
    }
    
}

@end
