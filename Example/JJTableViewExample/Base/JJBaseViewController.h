//
//  JJBaseViewController.h
//  JJTableViewExample
//
//  Created by jkenny on 16/8/19.
//  Copyright © 2016年 Jkenny. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JJBaseModel.h"
#import "JJTableView.h"

@interface JJBaseViewController : UIViewController <JJTableViewDataSource, JJTableViewDelegate>

@property (weak, nonatomic) IBOutlet JJTableView *tableView;
@property (nonatomic,strong) NSMutableArray<NSMutableArray<JJBaseModel *> *> *datas;

@property (nonatomic,copy) NSMutableArray<NSString *> *titles;

- (NSMutableArray<NSMutableArray<JJBaseModel *> *> *)setDatasWithPlistName:(NSString *)name;

@end
