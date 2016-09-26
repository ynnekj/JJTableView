//
//  JJPagingHorizentalController.m
//  JJTableViewExample
//
//  Created by jkenny on 16/9/14.
//  Copyright © 2016年 Jkenny. All rights reserved.
//

#import "JJPagingHorizentalController.h"
#import "JJBaseCell.h"

#define JJNumberOfCustomServiceItemInPage 8

@interface JJPagingHorizentalController ()

@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;

@end

static NSString *JJPagingCellIdentifier = @"JJBaseCell";

@implementation JJPagingHorizentalController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [super setDatasWithPlistName:@"paging_horizental"];
    
    self.pageControl.numberOfPages = ([[self.datas valueForKeyPath:@"@sum.@count"] intValue] + JJNumberOfCustomServiceItemInPage - 1) / JJNumberOfCustomServiceItemInPage;
    
    self.tableView.pagingEnabled = YES;
    self.tableView.layoutStyle = JJTableViewLayoutStylePagingHorizental;
    
    UINib *pagingCellNib = [UINib nibWithNibName:JJPagingCellIdentifier bundle:nil];
    [self.tableView registerNib:pagingCellNib forCellReuseIdentifier:JJPagingCellIdentifier];
}


#pragma mark - JJTableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(JJTableView *)tableView {
    return self.datas.count;
}

- (NSInteger)tableView:(JJTableView *)tableView numberOfItemsInSection:(NSInteger)section {
    return self.datas[section].count;
}

- (UIView *)tableView:(JJTableView *)tableView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    JJBaseCell *cell = [tableView dequeueReusableCellWithIdentifier:JJPagingCellIdentifier];
    
    JJBaseModel *model = self.datas[indexPath.section][indexPath.item];
    cell.titleLabel.text = model.title;
    cell.imageView.image = [UIImage imageNamed:model.icon];
    
    return cell;
}


#pragma mark - JJTableViewDelegate

- (NSUInteger)numberOfColunmsInTableView:(JJTableView *)tableView {
    return 4;
}

- (NSUInteger)numberOfRowsInTableView:(JJTableView *)tableView {
    return 2;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    double doublePage = scrollView.contentOffset.x / scrollView.frame.size.width;
    int page = doublePage + 0.5;
    self.pageControl.currentPage = page;
}

@end
