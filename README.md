# JJTableView
Support Interactive Reordering TableView


# 中文介绍
支持拖拽重排简单易用，你可以将它当作 UITableView、UICollectionView 来使用。

<img src="https://raw.github.com/ynnekj/JJTableView/master/Example/ExampleSnapshot/snapshot_fast.gif" width="320">


# 特性
- 支持拖拽重排
- 支持控制单个 cell 是否支持拖拽重排
- 支持控制正在拖拽的 cell 是否允许拖拽到指定位置
- 每个 cell 自带一个删除按钮
- 支持行数列数控制
- 适当情况下支持 cell 的宽高控制
- 支持各位置的 margin 控制
- 内部自带分界线可控制
- 支持所有 UIView 及其子类作为 cell 或 header view
- 支持 cell 和 header view 的复用
- 支持三种布局排列

# 用法

### 基本使用

	// 设置数据源
    self.tableView.dataSource = self;
    
    // 使用 nib 或 class 注册 cell
    static NSString *JKCellIdentifier = @"JKBaseCell";
    UINib *pagingCellNib = [UINib nibWithNibName:@"JKBaseCell" bundle:nil];
    [self.tableView registerNib:pagingCellNib forCellReuseIdentifier:JKCellIdentifier];

	// 实现数据源方法
	- (NSInteger)tableView:(JJTableView *)tableView numberOfItemsInSection:(NSInteger)section {
		return self.datas.count;
	}

	- (UIView *)tableView:(JJTableView *)tableView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
		JKBaseCell *cell = [tableView dequeueReusableCellWithIdentifier:JKCellIdentifier];
		return cell;
	}

### 拖拽重排

	// 实现数据源的这个方法来支持拖拽重排
	- (void)tableView:(JJTableView *)tableView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath {
	    // 必须在该方法中更新数据源，否则可能发生数据源与当前显示的数据不一致导致错误发生。
	    JKBaseModel *baseModel = self.datas[sourceIndexPath.item];
	    [self.datas removeObjectAtIndex:sourceIndexPath.item];
	    [self.datas insertObject:baseModel atIndex:destinationIndexPath.item];
	}

### 拖拽重排控制

	// 实现数据源这个方法来控制单个 cell 是否支持拖拽
	- (BOOL)tableView:(JJTableView *)tableView canLongPressAndMoveItemAtIndexPath:(NSIndexPath *)indexPath {
	    // 禁止第一个 cell 进行拖拽
	    if (indexPath.item == 0) {
	        return NO;
	    }
	    return YES;
	}

	// 实现数据源这个方法来控制正在拖拽的 cell 是否允许拖拽到指定位置
	- (BOOL)tableView:(JJTableView *)tableView canMoveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath {
	    // 禁止其它位置的 cell 拖拽到第一个 cell 的位置
	    if (destinationIndexPath.item == 0) {
	        return NO;
	    }
	    return YES;
	}

### 显示 header view
    // 设置代理
    self.tableView.delegate = self;
    // 使用 nib 或 class 注册 header view
    static NSString *JKHeaderIdentifier = @"JKHeaderView";
    UINib *headerNib = [UINib nibWithNibName:@"JKHeaderView" bundle:nil];
    [self.tableView registerNib:headerNib forHeaderViewReuseIdentifier:JKHeaderIdentifier];

	// 实现下列代理方法中的任何一个都可以导致 header view 显示
	
	// 返回对应 section 的自定义 header view
	- (UIView *)tableView:(JJTableView *)tableView viewForHeaderInSection:(NSInteger)section {
	    JKHeaderView *headerView = [tableView dequeueReusableHeaderViewWithIdentifier:JKHeaderIdentifier];
	    return headerView;
	}
	
	// 返回对应 section 的 默认 header view 的 title
	- (nullable NSString *)tableView:(JJTableView *)tableView titleForHeaderInSection:(NSInteger)section {
	    return self.titles[section];
	}
	
	// 在 JJTableViewLayoutStyle 等于 JJTableViewLayoutStyleVartical 时实现这个方法才有效
	- (CGFloat)tableView:(JJTableView *)tableView heightForHeaderInSection:(NSInteger)section {
	    return 44;
	}
	
	// 在 JJTableViewLayoutStyle 等于 JJTableViewLayoutStyleHorizental 时实现这个方法才有效
	- (CGFloat)tableView:(JJTableView *)tableView widthForHeaderInSection:(NSInteger)section {
	    return 44;
	}

### 控制行列宽高边距

    // 设置代理
    self.tableView.delegate = self;
    
	// 一共有多少行，在 JJTableViewLayoutStyle 等于 JJTableViewLayoutStyleHorizental 时实现这个方法才有效
	- (NSUInteger)numberOfRowsInTableView:(JJTableView *)tableView {
	    return 4;
	}
	
	// 一共有多少列，在 JJTableViewLayoutStyle 等于 JJTableViewLayoutStyleVartical 时实现这个方法才有效
	- (NSUInteger)numberOfColunmsInTableView:(JJTableView *)tableView {
	    return 3;
	}
	
	// 返回 cell 的宽度，在 JJTableViewLayoutStyle 等于 JJTableViewLayoutStyleHorizental 时实现这个方法才有效
	- (CGFloat)widthForCellInTableView:(JJTableView *)tableView {
	    return 180;
	}
	
	// 返回 cell 的高度，在 JJTableViewLayoutStyle 等于 JJTableViewLayoutStyleVartical 时实现这个方法才有效
	- (CGFloat)heightForCellInTableView:(JJTableView *)tableView {
	    return 44;
	}
	
	// 根据对应的 type 类型返回对应的 margin 大小
	- (CGFloat)tableView:(JJTableView *)tableView marginForType:(JJTableViewMarginType)type {
	    switch (type) {
	        case JJTableViewMarginTypeTop:
	            return 10;
	        case JJTableViewMarginTypeLeft:
	            return 10;
	        case JJTableViewMarginTypeRight:
	            return 10;
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

### 设置样式

    // 设置布局样式
    self.tableView.layoutStyle = JJTableViewLayoutStyleVartical;
    // 设置分割线样式
    self.tableView.separatorStyle = JJTableViewSeparatorStyleAll;

### 更多示例
查看演示工程 `Example/JJTableViewExample.xcodeproj`

# 许可证
JJTableView 使用 MIT 许可证，详情见 LICENSE 文件。

