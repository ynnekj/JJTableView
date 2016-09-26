//
//  JJBaseViewController.m
//  JJTableViewExample
//
//  Created by jkenny on 16/8/19.
//  Copyright © 2016年 Jkenny. All rights reserved.
//

#import "JJBaseViewController.h"

@interface JJBaseViewController ()

@end

@implementation JJBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}

- (NSMutableArray<NSMutableArray<JJBaseModel *> *> *)setDatasWithPlistName:(NSString *)name {
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:name ofType:@"plist"];
    NSArray *customServiceList = [NSArray arrayWithContentsOfFile:filePath];
    
    NSMutableArray<NSMutableArray<JJBaseModel *> *> *arrays = [NSMutableArray array];
    
    for (NSMutableArray<JJBaseModel *> *dicts in customServiceList) {
        NSMutableArray<JJBaseModel *> *models = [NSMutableArray arrayWithCapacity:dicts.count];
        
        for (NSDictionary *dict in dicts) {
            JJBaseModel *baseModel = [JJBaseModel modelWithDict:dict];
            [models addObject:baseModel];
        }
        [arrays addObject:models];
    }
    self.datas = arrays;
    
    return self.datas;
}

- (NSMutableArray<NSString *> *)titles {
    if (!_titles) {
        _titles = [NSMutableArray arrayWithObjects:@"我的应用", @"便民生活", @"资金往来", @"购物娱乐", @"财富管理", @"教育公益", @"第三方提供服务", nil];
    }
    return _titles;
}

#pragma mark - JJTableViewDelegate

- (void)tableView:(JJTableView *)tableView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    JJBaseModel *baseModel = [self.datas[indexPath.section] objectAtIndex:indexPath.item];
    self.navigationItem.title = baseModel.title;
}

@end
