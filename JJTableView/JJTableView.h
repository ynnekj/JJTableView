//
//  JJTableView.h
//  TableView
//
//  Created by Jkenny on 16/7/5.
//  Copyright © 2016年 Jkenny. All rights reserved.
//

// TODO:
// 1. 优化滚动（cell 在移动时有抖动现象）
// 2. 优化性能／代码重构
// 3. 还不支持不同高度
// 4. 考虑实现瀑布流
// 5. line 动画

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, JJTableViewLayoutStyle) {
    JJTableViewLayoutStyleVartical, // default
    JJTableViewLayoutStyleHorizental,
    /**
     *  如果选择使用这个 type 那么必须提供 delegate 的下列两个方法:
     *  1. numberOfColunmsInTableView:
     *  2. numberOfRowsInTableView:
     */
    JJTableViewLayoutStylePagingHorizental
};

typedef NS_ENUM(NSInteger, JJTableViewMarginType) {
    JJTableViewMarginTypeTop,
    JJTableViewMarginTypeLeft,
    JJTableViewMarginTypeRight,
    JJTableViewMarginTypeBottom,
    JJTableViewMarginTypeColumn,
    JJTableViewMarginTypeRow,
    JJTableViewMarginTypeHeaderLeading,     // default 0
    JJTableViewMarginTypeHeaderTrailing,    // default 0
    JJTableViewMarginTypeSectionLeading,    // default 0
    JJTableViewMarginTypeSectionTrailing    // default 0
};

typedef NS_ENUM(NSInteger, JJTableViewItemAnimation) {
    JJTableViewItemAnimationFade,
    JJTableViewItemAnimationShrink,
    JJTableViewItemAnimationNone
};

typedef NS_ENUM(NSUInteger, JJTableViewSeparatorStyle) {
    JJTableViewSeparatorStyleNone                               = 0,
    JJTableViewSeparatorStyleHeaderLeadingSingleLine            = 1 << 0,
    JJTableViewSeparatorStyleHeaderTrailingSingleLine           = 1 << 1,
    JJTableViewSeparatorStyleRowColumnSingleLine                = 1 << 2,
    JJTableViewSeparatorStyleCellOutlineBorderTopLine           = 1 << 3,
    JJTableViewSeparatorStyleCellOutlineBorderBottomLine        = 1 << 4,
    JJTableViewSeparatorStyleCellOutlineBorderLeftLine          = 1 << 5,
    JJTableViewSeparatorStyleCellOutlineBorderRightLine         = 1 << 6,
    JJTableViewSeparatorStyleHeaderLeadingTrailingSingleLine    = JJTableViewSeparatorStyleHeaderLeadingSingleLine | JJTableViewSeparatorStyleHeaderTrailingSingleLine,
    JJTableViewSeparatorStyleCellOutlineBorderTopBottomLine     = JJTableViewSeparatorStyleCellOutlineBorderTopLine | JJTableViewSeparatorStyleCellOutlineBorderBottomLine,
    JJTableViewSeparatorStyleCellOutlineBorderLeftRightLine     = JJTableViewSeparatorStyleCellOutlineBorderLeftLine | JJTableViewSeparatorStyleCellOutlineBorderRightLine,
    JJTableViewSeparatorStyleCellOutlineBorderLine              = JJTableViewSeparatorStyleCellOutlineBorderTopBottomLine | JJTableViewSeparatorStyleCellOutlineBorderLeftRightLine,
    JJTableViewSeparatorStyleAll    = JJTableViewSeparatorStyleHeaderLeadingTrailingSingleLine | JJTableViewSeparatorStyleRowColumnSingleLine | JJTableViewSeparatorStyleCellOutlineBorderLine
};

typedef NS_ENUM(NSInteger, JJTableViewCellCloseButtonLocation) {
    JJTableViewCellCloseButtonLocationTopLeft,
    JJTableViewCellCloseButtonLocationTopRight
};

@class JJTableView;


@protocol JJTableViewDataSource<NSObject>

@required

- (NSInteger)tableView:(JJTableView *)tableView numberOfItemsInSection:(NSInteger)section;
- (UIView *)tableView:(JJTableView *)tableView cellForItemAtIndexPath:(NSIndexPath *)indexPath;

@optional

- (NSInteger)numberOfSectionsInTableView:(JJTableView *)tableView;              // Default is 1 if not implemented

/**
 *  是否允许当前长按 cell 触发长按效果并且可以拖拽，default YES
 *
 *  @param tableView
 *  @param indexPath   长按的 cell 对应的 NSIndexPath
 *
 *  @return yes/no
 */
- (BOOL)tableView:(JJTableView *)tableView canLongPressAndMoveItemAtIndexPath:(NSIndexPath *)indexPath;

/** 此方法在 cell 触发长按效果后调用 */
- (void)tableView:(JJTableView *)tableView willBeginMoveItemAtIndexPath:(NSIndexPath *)indexPath;

/**
 *  必须实现这个方法才可进行拖拽
 *  在用户完成拖拽后调用这个方法
 *  注意:在这个方法中更新对应的数据源，否则在下次的处理 item 时数据源与当前显示的数据不一致导致错误发生。
 *
 *  @param tableView
 *  @param sourceIndexPath      移动的 cell 对应的 NSIndexPath,也就是在回调 gridPanView:canLongPressAndMoveItemAtIndexPath: 方法时传递的 indexPath
 *  @param destinationIndexPath 移动到目标位置对应的 NSIndexPath
 */
- (void)tableView:(JJTableView *)tableView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath;

/**
 *  是否允许 sourceIndexPath 对应的 cell 拖拽到 destinationIndexPath 对应的 cell 的位置 default YES
 *  注意:在该方法中并不需要修改数据源，因为这不是最终的移动
 *  @return yes/no
 */
- (BOOL)tableView:(JJTableView *)tableView canMoveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath;

/**
 *  返回对应 section 的 默认 header view 的 title
 *  返回的 title 将在默认的 header view 中显示，如未实现 tableView:viewForHeaderInSection: 方法或在该方法中返回 nil 都将显示默认的 header view
 *  如果在 tableView:viewForHeaderInSection 方法中返回自定义的 header view 那么这里返回的 title 将不使用
 */
- (nullable NSString *)tableView:(JJTableView *)tableView titleForHeaderInSection:(NSInteger)section;

@end


@protocol JJTableViewDelegate<NSObject, UIScrollViewDelegate>

@optional

/** 一共有多少列 */
- (NSUInteger)numberOfColunmsInTableView:(JJTableView *)tableView;

/** 一共有多少行 */
- (NSUInteger)numberOfRowsInTableView:(JJTableView *)tableView;

/**
 *  返回 cell 的高度
 *  注意:在 JJTableViewLayoutStyle 等于 JJTableViewLayoutStyleVartical 时实现这个方法才有效
 */
- (CGFloat)heightForCellInTableView:(JJTableView *)tableView;

/**
 *  返回对应 section 的 header view 高度
 *  注意:在 JJTableViewLayoutStyle 等于 JJTableViewLayoutStyleVartical 时实现这个方法才有效
 */
- (CGFloat)tableView:(JJTableView *)tableView heightForHeaderInSection:(NSInteger)section;

/**
 *  返回 cell 的宽度
 *  注意:在 JJTableViewLayoutStyle 等于 JJTableViewLayoutStyleHorizental 时实现这个方法才有效
 */
- (CGFloat)widthForCellInTableView:(JJTableView *)tableView;

/**
 *  返回对应 section 的 header view 宽度
 *  注意:在 JJTableViewLayoutStyle 等于 JJTableViewLayoutStyleHorizental 时实现这个方法才有效
 */
- (CGFloat)tableView:(JJTableView *)tableView widthForHeaderInSection:(NSInteger)section;

/**
 *  返回对应 section 的 header view
 */
- (nullable UIView *)tableView:(JJTableView *)tableView viewForHeaderInSection:(NSInteger)section;   // custom view for header. will be adjusted to default or specified header height

/**
 *  根据对应的 type 类型返回对应的 margin 大小
 */
- (CGFloat)tableView:(JJTableView *)tableView marginForType:(JJTableViewMarginType)type;

/** 点击其中一个 cell 时调用 */
- (void)tableView:(JJTableView *)tableView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;

/**
 *  必须实现这个方法 cell 上的 close button 在长按后才会显示
 *  cell 上的关闭按钮被点击时调用
 */
- (void)tableView:(JJTableView *)tableView didClickItemCloseButtonAtIndexPath:(NSIndexPath *)indexPath;

@end


@interface JJTableView : UIScrollView

/**
 *  default JJTableViewLayoutStyleVartical
 */
@property (nonatomic) JJTableViewLayoutStyle layoutStyle;

@property (nonatomic,weak,nullable) id<JJTableViewDataSource> dataSource;
@property (nonatomic,weak,nullable) id<JJTableViewDelegate> delegate;

@property (nonatomic) JJTableViewSeparatorStyle separatorStyle; // default is JJTableViewSeparatorStyleNone
@property (nonatomic) CGFloat separatorWidth; // default 1 pixel
@property (nonatomic, strong, nullable) UIColor *separatorColor; // default black

@property (nonatomic) JJTableViewCellCloseButtonLocation cellCloseButtonLocation; // default is JJTableViewCellCloseButtonLocationTopLeft

// default header
@property(null_resettable, nonatomic,strong) UIFont *headerFont;
@property(null_resettable, nonatomic,strong) UIColor *headerTextColor;
@property (nonatomic,strong) UIColor *headerBackgroundColor;

@property (nonatomic, readonly) NSArray<__kindof UIView *> *visibleCells;

/**
 *  default is NO. setting is not animated.
 *  设置为 YES 后会将所有 cell 的长按拖拽时间设置为 0.1 秒（达到类似可直接拖拽的效果）
 */
@property (nonatomic, getter=isEditing) BOOL editing;

/**
 *  重新加载所有的 cell ，之前创建的 cell 将被复用
 */
- (void)reloadData;

/**
 *  在调用这个方法进行 cell 的注册后，可以直接使用 dequeueReusableCellWithIdentifier: 方法获取缓存池中可以复用的 cell,
 *  如果缓存池中没有可复用的 cell 那么会直接创建一个新的 cell 并返回。
 *
 *  @param nib
 *  @param identifier 同一类型的 cell 的 identifier 必须与调用 dequeueReusableCellWithIdentifier: 方法时参数的 identifier 一致。
 */
- (void)registerNib:(nullable UINib *)nib forCellReuseIdentifier:(NSString *)identifier;

/**
 *  在调用这个方法进行 cell 的注册后，可以直接使用 dequeueReusableCellWithIdentifier: 方法获取缓存池中可以复用的 cell,
 *  如果缓存池中没有可复用的 cell 那么会直接创建一个新的 cell 并返回。
 *
 *  @param cellClass
 *  @param identifier 同一类型的 cell 的 identifier 必须与调用 dequeueReusableCellWithIdentifier: 方法时参数的 identifier 一致。
 */
- (void)registerClass:(nullable Class)cellClass forCellReuseIdentifier:(NSString *)identifier;

/**
 *  获取缓池中可以服用的 cell
 *  注意:
 *      1.你必须事先通过 registerNib:forCellReuseIdentifier: 或 registerClass:forCellReuseIdentifier 方法注册你使用的 cell，
 *      才可以调用该方法获取可复用的 cell，如果没有可复用的 cell 会根据 identifier 查找对应注册的 cell 如果有则自动创建一个并作为返回值。
 *      2.当你使用一个拥有 NSString 类型的 reuseIdentifier 属性的 View 作为你的 cell 时你可以不进行注册，你只需要设置它的 reuseIdentifier 属性即可，
 *      （例如使用 UITableViewCell 或 UICollectionViewCell 因为它们都有一个 reuseIdentifier 属性），
 *      但以这种方式调用该方法时，你必须判断返回的 cell 是否为 nil 如果是那么你需要自己创建一个新的 cell，因为这里只会创建注册了的 cell。
 *      (使用注册的方式时可以不设置 reuseIdentifier 属性)
 *      3.除了以上两种方式外你创建的 cell 都无法得到复用。
 */
- (nullable __kindof UIView *)dequeueReusableCellWithIdentifier:(NSString *)identifier;

// 下列三个方法作用与使用同上 cell 的作用与使用

/**
 *  在调用这个方法进行 header view 的注册后，可以直接使用 dequeueReusableHeaderViewWithIdentifier: 方法获取缓存池中可以复用的 header view,
 *  如果缓存池中没有可复用的 header view 那么会直接创建一个新的 header view 并返回。
 *
 *  @param nib
 *  @param identifier 同一类型的 header view 的 identifier 必须与调用 dequeueReusableHeaderViewWithIdentifier: 方法时参数的 identifier 一致。
 */
- (void)registerNib:(nullable UINib *)nib forHeaderViewReuseIdentifier:(NSString *)identifier;

/**
 *  在调用这个方法进行 header view 的注册后，可以直接使用 dequeueReusableHeaderViewWithIdentifier: 方法获取缓存池中可以复用的 header view,
 *  如果缓存池中没有可复用的 header view 那么会直接创建一个新的 header view 并返回。
 *
 *  @param headerViewClass
 *  @param identifier 同一类型的 header view 的 identifier 必须与调用 dequeueReusableHeaderViewWithIdentifier: 方法时参数的 identifier 一致。
 */
- (void)registerClass:(nullable Class)aClass forHeaderViewReuseIdentifier:(NSString *)identifier;

/**
 *  获取缓池中可以服用的 header view
 *  注意:
 *      1.你必须事先通过 registerNib:forHeaderViewReuseIdentifier: 或 registerClass:forHeaderViewReuseIdentifier: 方法注册你使用的 header view，
 *      才可以调用该方法获取可复用的 header view，如果没有可复用的 header view 会根据 identifier 查找对应注册的 header view 如果有则自动创建一个并作为返回值。
 *      2.当你使用一个拥有 NSString 类型的 reuseIdentifier 属性的 View 作为你的 header view 时你可以不进行注册，你只需要设置它的 reuseIdentifier 属性即可，
 *      但以这种方式调用该方法时，你必须判断返回的 header view 是否为 nil 如果是那么你需要自己创建一个新的 header view，因为这里只会创建注册了的 header view。
 *      (使用注册的方式时可以不设置 reuseIdentifier 属性)
 *      3.除了以上两种方式外你创建的 header view 都无法得到复用。
 */
- (nullable __kindof UIView *)dequeueReusableHeaderViewWithIdentifier:(NSString *)identifier;

/**
 *  移动 indexPath 对应的 cell 到指定 newIndexPath 对应的位置
 *  注意:在调用该方法前请先更新对应的数据源，是否调用时数据源与当前显示的数据不一致导致错误发生。
 *
 *  @param indexPath    要移动的 indexPath
 *  @param newIndexPath 目标 indexPath
 */
- (void)moveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath;

/**
 *  删除指定的 indexPath 对应的 cell
 *  注意:在调用该方法前请先更新对应的数据源，是否调用时数据源与当前显示的数据不一致导致错误发生。
 *
 *  @param indexPath 要删除的 cell 对应的 indexPath
 *  @param animation 删除动画类型
 */
- (void)deleteItemAtIndexPath:(NSIndexPath *)indexPath withItemAnimation:(JJTableViewItemAnimation)animation;

/**
 *  删除 indexPath 对应的 cell
 *  注意:在调用该方法前请先更新对应的数据源，是否调用时数据源与当前显示的数据不一致导致错误发生。
 *
 *  @param indexPath 要插入的 cell 对应的 indexPath
 *  @param animation 插入动画类型
 */
- (void)insertItemAtIndexPath:(NSIndexPath *)indexPath withItemAnimation:(JJTableViewItemAnimation)animation;

/**
 *  重新加载对应 indexPath 的 cell
 *
 *  @param indexPath 将要刷新的 cell 对应的 indexPath
 *  @param animation 刷新时的动画类型
 */
- (void)reloadItemAtIndexPath:(NSIndexPath *)indexPath withItemAnimation:(JJTableViewItemAnimation)animation;

/**
 *  获取 cell 现在对应的 NSIndexPath
 */
- (nullable NSIndexPath *)indexPathForCell:(UIView *)cell;

/**
 *  通过 indexPath 获取对应的 cell，如果对应的 cell 处于不可见或 indexPath 超出范围则返回 nil
 */
- (nullable __kindof UIView *)cellForItemAtIndexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END