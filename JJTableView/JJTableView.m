//
//  JJTableView.m
//  TableView
//
//  Created by Jkenny on 16/7/5.
//  Copyright © 2016年 Jkenny. All rights reserved.
//

#import "JJTableView.h"
#import <objc/runtime.h>

#define JJLog(...)// NSLog(__VA_ARGS__)
#define JJException(condition, reason) do { if (!(condition)) { [NSException raise:NSInternalInconsistencyException format:reason]; } } while(0)

#define JJTableViewDefaultMargin 8
#define JJTableViewAnimateDuration 0.25

#define JJTableViewDefaultColumn 3
#define JJTableViewDefaultRow 4

#define JJTableViewDefaultHeaderHeight 28
#define JJTableViewDefaultHeaderWidth 28

#define JJTableViewDefaultItemHeight 70
#define JJTableViewDefaultItemWidth 100

#define SINGLE_LINE_WIDTH           (1 / [UIScreen mainScreen].scale)
#define SINGLE_LINE_ADJUST_OFFSET   ((1 / [UIScreen mainScreen].scale) / 2)

@protocol JJTableViewCellDelegate <NSObject>

- (void)didClickCloseButtonInCell:(UIView *)cell;
- (void)cell:(UIView *)cell didLongPressedWithGestureRecognizer:(UILongPressGestureRecognizer *)longPressGesture;
- (void)cell:(UIView *)cell didSingleTapWithGestureRecognizer:(UITapGestureRecognizer *)singleTapGesture;

@end

@interface UIView (JJTableViewCell)

@property (nonatomic,assign) NSInteger jj_keyIndex;
@property (nonatomic,strong) NSIndexPath *jj_indexPath;
@property (nonatomic,strong) NSIndexPath *jj_fromIndexPath;
@property (nonatomic,copy) NSString *jj_identifier;
@property (nonatomic,weak) UILongPressGestureRecognizer *jj_longPressGressRecognizer;

@property (nonatomic,weak) id<JJTableViewCellDelegate> jj_delegate;
- (void)jj_setCloseButtonVisible:(BOOL)visible animated:(BOOL)animated;

@property (nonatomic,strong) UIButton *jj_closeButton;
@property (nonatomic,strong) NSLayoutConstraint *jj_leftRightConstraint;
@property (nonatomic,assign) JJTableViewCellCloseButtonLocation jj_closeButtonLocation; // default JJTableViewCellCloseButtonLocationTopLeft

- (void)jj_prepareCellUseCloseButton:(BOOL)useCloseButton closeButtonLocation:(JJTableViewCellCloseButtonLocation)location;

@property (nonatomic, assign,getter=jj_isCellView) BOOL jj_cellView;

@end

static NSString *JJTableViewHeaderViewIdentifier = @"headerViewIdentifier";

@interface JJTableView () <JJTableViewCellDelegate>{
    // 记录当前移动坐标
    CGPoint _lastPoint;
    // 当前选中的 cell
    UIView *_selectedCell;
    
    // 缓存 <section : items>
    NSInteger _cacheSection;
    NSMutableDictionary<NSNumber *, NSNumber *> *_cacheSectionItems;
    
    // 滚动回调
    void (^scrollContentBlock)();
    // 当前 self 的 frame
    CGRect _currentRect;
}

@property (nonatomic,strong) NSMutableArray<NSIndexPath *> *originalIndexPaths;
@property (nonatomic,strong) NSMutableArray<NSIndexPath *> *indexPaths;
@property (nonatomic,strong) NSMutableArray<NSValue *> *frames;

/** 已经显示在屏幕的 view 包含 cell 和 header view */
@property (nonatomic,strong) NSMutableDictionary<NSNumber * ,UIView *> *displayCells;

/** 缓存池 用于存放离开屏幕的 cell */
@property (nonatomic,strong) NSMutableSet<UIView *> *reusableItemCells;
/** 缓存池 用于存放离开屏幕的 headerView */
@property (nonatomic,strong) NSMutableSet<UIView *> *reusableHeaderViews;

@property (nonatomic,strong) NSTimer *scrollTimer;

/** cell 是否处于拖拽状态(拖拽中) */
@property(nonatomic,getter=isCellDragging) BOOL cellDragging;

@property (nonatomic,strong) NSDictionary<NSString *, UINib *> *registerNibs;
@property (nonatomic,strong) NSDictionary<NSString *, Class> *registerClasss;

@property (nonatomic,strong) NSDictionary<NSString *, UINib *> *registerHeaderNibs;
@property (nonatomic,strong) NSDictionary<NSString *, Class> *registerHeaderClasss;

// line
@property (nonatomic,strong) CAShapeLayer *backgroundLineLayer;

@property (nonatomic,strong) NSMutableArray<NSValue *> *lineHeadersRanges;
@property (nonatomic,strong) NSMutableArray<NSValue *> *lineCellsRanges;
@property (nonatomic,strong) NSMutableArray<NSNumber *> *lineRows;
@property (nonatomic,strong) NSMutableArray<NSNumber *> *lineColumns;

@end


@implementation JJTableView
//@synthesize delegate = _delegate;
@dynamic delegate;

- (NSTimer *)scrollTimer {
    if (!_scrollTimer) {
        _scrollTimer = [NSTimer timerWithTimeInterval:0.02 target:self selector:@selector(scrollContent) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_scrollTimer forMode:NSRunLoopCommonModes];
        [_scrollTimer setFireDate:[NSDate distantFuture]];
    }
    return _scrollTimer;
}

- (CAShapeLayer *)backgroundLineLayer {
    if (!_backgroundLineLayer) {
        _backgroundLineLayer = [CAShapeLayer layer];
        [self.layer addSublayer:self.backgroundLineLayer];
        self.backgroundLineLayer.zPosition = 1;
        self.separatorWidth = SINGLE_LINE_WIDTH;
        self.separatorColor = [UIColor colorWithRed:0.737 green:0.729 blue:0.757 alpha:1.000];
    }
    return _backgroundLineLayer;
}

- (NSMutableArray<NSValue *> *)lineHeadersRanges {
    if (!_lineHeadersRanges) {
        _lineHeadersRanges = [NSMutableArray array];
    }
    return _lineHeadersRanges;
}

- (NSMutableArray<NSValue *> *)lineCellsRanges {
    if (!_lineCellsRanges) {
        _lineCellsRanges = [NSMutableArray array];
    }
    return _lineCellsRanges;
}

- (NSMutableArray<NSNumber *> *)lineRows {
    if (!_lineRows) {
        _lineRows = [NSMutableArray array];
    }
    return _lineRows;
}

- (NSMutableArray<NSNumber *> *)lineColumns {
    if (!_lineColumns) {
        _lineColumns = [NSMutableArray array];
    }
    return _lineColumns;
}

- (NSDictionary<NSString *,UINib *> *)registerNibs {
    if (!_registerNibs) {
        _registerNibs = [NSMutableDictionary dictionary];
    }
    return _registerNibs;
}

- (NSDictionary<NSString *,Class> *)registerClasss {
    if (!_registerClasss) {
        _registerClasss = [NSMutableDictionary dictionary];
    }
    return _registerClasss;
}

- (NSDictionary<NSString *,UINib *> *)registerHeaderNibs {
    if (!_registerHeaderNibs) {
        _registerHeaderNibs = [NSMutableDictionary dictionary];
    }
    return _registerHeaderNibs;
}

- (NSDictionary<NSString *,Class> *)registerHeaderClasss {
    if (!_registerHeaderClasss) {
        _registerHeaderClasss = [NSMutableDictionary dictionary];
    }
    return _registerHeaderClasss;
}

- (NSMutableArray<NSIndexPath *> *)originalIndexPaths {
    if (!_originalIndexPaths) {
        _originalIndexPaths = [NSMutableArray array];
    }
    return _originalIndexPaths;
}

- (NSMutableArray<NSIndexPath *> *)indexPaths {
    if (!_indexPaths) {
        _indexPaths = [NSMutableArray array];
    }
    return _indexPaths;
}

- (NSMutableDictionary<NSNumber * ,UIView *> *)displayCells {
    if (!_displayCells) {
        _displayCells = [NSMutableDictionary dictionary];
    }
    return _displayCells;
}

- (NSMutableSet<UIView *> *)reusableItemCells {
    if (!_reusableItemCells) {
        _reusableItemCells = [NSMutableSet set];
    }
    return _reusableItemCells;
}

- (NSMutableSet<UIView *> *)reusableHeaderViews{
    if (!_reusableHeaderViews) {
        _reusableHeaderViews = [NSMutableSet set];
    }
    return _reusableHeaderViews;
}

- (NSMutableArray<NSValue *> *)frames {
    if (!_frames) {
        _frames = [NSMutableArray array];
    }
    return _frames;
}

- (void)setCellDragging:(BOOL)cellDragging {
    _cellDragging = cellDragging;
    if (cellDragging) {
        [self.originalIndexPaths addObjectsFromArray:self.indexPaths];
    } else {
        [self.originalIndexPaths removeAllObjects];
    }
}

- (void)setSeparatorStyle:(JJTableViewSeparatorStyle)separatorStyle {
    _separatorStyle = separatorStyle;
    
    // != JJTableViewSeparatorStyleNone 时加载 backgroundLineLayer
    if (self.separatorStyle != JJTableViewSeparatorStyleNone && self.backgroundLineLayer) {}
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupInitProperty];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupInitProperty];
    }
    return self;
}

- (void)setupInitProperty {
    _currentRect = self.frame;
    self.layoutStyle = JJTableViewLayoutStyleVartical;
    self.separatorStyle = JJTableViewSeparatorStyleNone;
    self.cellCloseButtonLocation = JJTableViewCellCloseButtonLocationTopLeft;
}

- (void)refreshMinimumPressDurationWithCell:(UIView *)cell {
        CFTimeInterval minimumPressDuration;
        if (self.editing) {
            minimumPressDuration = 0.1;
        } else {
            minimumPressDuration = 0.5;
        }
        cell.jj_longPressGressRecognizer.minimumPressDuration = minimumPressDuration;
}

#pragma mark - 外部方法

- (void)setEditing:(BOOL)editing {
    if (_editing == editing) return;
    
    _editing = editing;
    
    for (UIView *visiableCell in self.visibleCells) {
        [self refreshMinimumPressDurationWithCell:visiableCell];
    }
    
    for (UIView *invisiableCell in self.reusableItemCells) {
        [self refreshMinimumPressDurationWithCell:invisiableCell];
    }
}

- (NSArray<UIView *> *)visibleCells {
    NSMutableArray<UIView *> *visiableCells = [NSMutableArray array];
    for (UIView *view in self.displayCells.allValues) {
        if (view.jj_isCellView) {
            [visiableCells addObject:view];
        }
    }
    return visiableCells;
}

- (void)registerNib:(nullable UINib *)nib forCellReuseIdentifier:(NSString *)identifier {
    [self.registerNibs setValue:nib forKey:identifier];
}

- (void)registerClass:(nullable Class)cellClass forCellReuseIdentifier:(NSString *)identifier {
    [self.registerClasss setValue:cellClass forKey:identifier];
}

- (void)registerNib:(nullable UINib *)nib forHeaderViewReuseIdentifier:(NSString *)identifier {
    [self.registerHeaderNibs setValue:nib forKey:identifier];
}

- (void)registerClass:(nullable Class)aClass forHeaderViewReuseIdentifier:(NSString *)identifier {
    [self.registerHeaderClasss setValue:aClass forKey:identifier];
}

- (nullable __kindof UIView *)dequeueReusableCellWithIdentifier:(NSString *)identifier; {
    __block UIView *cell = nil;
    
    [self.reusableItemCells enumerateObjectsUsingBlock:^(UIView * _Nonnull iv, BOOL * _Nonnull stop) {
        if ([iv.jj_identifier isEqualToString:identifier]) {
            cell = iv;
            *stop = YES;
        }
    }];
    
    if (cell) {
        [self.reusableItemCells removeObject:cell];
        [cell jj_setCloseButtonVisible:NO animated:NO];
        return cell;
    }
    
    // 缓存池中没有，查找注册
    UINib *nib = [self.registerNibs objectForKey:identifier];
    if (nib) {
        cell = [[nib instantiateWithOwner:nil options:nil] firstObject];
    } else {
        Class class = [self.registerClasss objectForKey:identifier];
        cell = [[class alloc] init];
    }
    
    if (cell) {
        cell.jj_identifier = identifier;
        cell.jj_delegate = self;
        BOOL isUseCloseButton = [self.delegate respondsToSelector:@selector(tableView:didClickItemCloseButtonAtIndexPath:)];
        [cell jj_prepareCellUseCloseButton:isUseCloseButton closeButtonLocation:self.cellCloseButtonLocation];
    }
    
    return cell;
}

/**
 *  获取缓池中可以服用的 headerView
 */
- (nullable __kindof UIView *)dequeueReusableHeaderViewWithIdentifier:(NSString *)identifier {
    __block UIView *headerView = nil;
    [self.reusableHeaderViews enumerateObjectsUsingBlock:^(UIView * _Nonnull hv, BOOL * _Nonnull stop) {
        if ([hv.jj_identifier isEqualToString:identifier]) {
            headerView = hv;
            *stop = YES;
        }
    }];
    if (headerView) {
        [self.reusableHeaderViews removeObject:headerView];
        return headerView;
    }
    
    // 缓存池中没有，查找注册
    UINib *nib = [self.registerHeaderNibs objectForKey:identifier];
    if (nib) {
        headerView = [[nib instantiateWithOwner:nil options:nil] firstObject];
    } else {
        Class class = [self.registerHeaderClasss objectForKey:identifier];
        headerView = [[class alloc] init];
    }
    if (headerView) {
        headerView.jj_identifier = identifier;
    }
    
    return headerView;
}

- (nullable NSIndexPath *)indexPathForCell:(UIView *)cell {
    if (cell) {
        return cell.jj_indexPath;
    }
    return nil;
}

- (nullable __kindof UIView *)cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    __block UIView *cellView = nil;
    [self.displayCells enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, UIView * _Nonnull view, BOOL * _Nonnull stop) {
        if (view.jj_isCellView && [view.jj_indexPath isEqual:indexPath]) {
            cellView = view;
            *stop = YES;
        }
    }];
    return cellView;
}

- (void)setDataSource:(id<JJTableViewDataSource>)dataSource {
    _dataSource = dataSource;
    [self reloadData];
}

- (void)setDelegate:(id<JJTableViewDelegate>)delegate {
    [super setDelegate:delegate];
    
    // JJTableViewLayoutStylePagingHorizental type 必须提供以下两个方法
    if (self.layoutStyle == JJTableViewLayoutStylePagingHorizental && delegate) {
        NSAssert([delegate respondsToSelector:@selector(numberOfColunmsInTableView:)] && [delegate respondsToSelector:@selector(numberOfRowsInTableView:)],
                 @"layoutStyle 为 JJTableViewLayoutStylePagingHorizental 时必须提供 delegate 的 numberOfColunmsInTableView: 和 numberOfRowsInTableView: 方法!");
    }
}

- (void)reloadData {
    if (!self.dataSource) return;
    
    // 初始化 cache
    _cacheSection = 1;
    _cacheSectionItems = [NSMutableDictionary dictionary];
    
    [self.displayCells.allValues makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    for (UIView *cellView in self.displayCells.allValues) {
        if (cellView.jj_identifier) {
            [self.reusableItemCells addObject:cellView];
        }
    }
    [self.displayCells removeAllObjects];
    
    [self refreshFrameUseCache:NO];
}

#pragma mark -

/**
 *  加载 subviews
 */
- (void)layoutSubviews{
    [super layoutSubviews];
    
    if (!CGRectEqualToRect(_currentRect, self.frame)) {
        _currentRect = self.frame;
        [self refreshFrameUseCache:NO];
        [self refreshLayoutSubviews];
    }
    
    // 获取有多少组数据
    NSInteger numberOfSections = [self numberOfSectionsUseCache:YES];
    
    int cellViewIndex = 0;
    for (int section=0; section<numberOfSections; section++) {
        if ([self isSetSectionHeader]) {
            CGRect headerFrame = [self.frames[cellViewIndex] CGRectValue];
            UIView *headerView = [self.displayCells objectForKey:@(cellViewIndex)];
            
            if ([self isInScreenWithFrame:headerFrame]) {
                if (!headerView) {
                    headerView = [self viewForHeaderInSection:section];
                    headerView.frame = headerFrame;
                    NSIndexPath *headerIndexPath = self.indexPaths[cellViewIndex];
                    headerView.jj_indexPath = headerIndexPath;
                    [self insertSubview:headerView atIndex:0];
                    
                    [self.displayCells setObject:headerView forKey:@(cellViewIndex)];
                    headerView.jj_keyIndex = cellViewIndex;
                }
            } else {
                if (headerView) {
                    [headerView removeFromSuperview];
                    [self.displayCells removeObjectForKey:@(cellViewIndex)];
                    if (headerView.jj_identifier) {
                        [self.reusableHeaderViews addObject:headerView];
                    }
                }
            }
            cellViewIndex++;
        }
        
        // 当前 section 组下有多少数据
        NSInteger numberOfItems = [self numberOfItemsInSection:section useCache:YES];
        
        for (int index=0; index<numberOfItems; index++) {
            CGRect itemFrame = [self.frames[cellViewIndex] CGRectValue];
            UIView *cellView = (UIView *)[self.displayCells objectForKey:@(cellViewIndex)];
            
            if ([self isInScreenWithFrame:itemFrame]) {
                // 添加 != 判断是正在移动的 cellView 则不处理，不然会在加载一次。但要注意在没有移动 cellView时设置 _selectedCell = nil
                // 好像已经不移除 正在移动到 cellView 了所以不需要在加 && 判断 // 因为没有从 displayCells 中移除了所以不会为 nil
                if (!cellView /*&& (!_selectedCell || cellViewIndex != _selectedCell.jj_keyIndex)*/) {
                    NSIndexPath *cellViewIndexPath = self.isCellDragging ? self.originalIndexPaths[cellViewIndex] : self.indexPaths[cellViewIndex];
                    cellView = [self cellForIndexPath:cellViewIndexPath];
                    
                    cellView.jj_indexPath = self.indexPaths[cellViewIndex]; // 这个 jj_indexPath 需要从 indexPaths 中取
                    cellView.frame = itemFrame;
                    [self insertSubview:cellView atIndex:0];
                    
                    [self.displayCells setObject:cellView forKey:@(cellViewIndex)];
                    cellView.jj_keyIndex = cellViewIndex;
                }
            } else {
                if (cellView && cellViewIndex != _selectedCell.jj_keyIndex) {
                    [cellView removeFromSuperview];
                    [self.displayCells removeObjectForKey:@(cellViewIndex)];
                    if (cellView.jj_identifier) {
                        [self.reusableItemCells addObject:cellView];
                    }
                }
            }
            cellViewIndex++;
        }
        [self bringSubviewToFront:_selectedCell];
    }
}

#pragma mark - line

- (void)refreshBackgroundLine {
    if (self.separatorStyle == JJTableViewSeparatorStyleNone) return;
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGFloat marginTop = [self marginForType:JJTableViewMarginTypeTop];
    CGFloat marginLeft = [self marginForType:JJTableViewMarginTypeLeft];
    CGFloat marginColumn = [self marginForType:JJTableViewMarginTypeColumn];
    CGFloat marginRow = [self marginForType:JJTableViewMarginTypeRow];
    
    CGFloat itemW = 0;
    CGFloat itemH = 0;
    
    CGFloat pixelAdjustOffset = 0;
    if (((int)(self.separatorWidth * [UIScreen mainScreen].scale) + 1) % 2 == 0) {
        pixelAdjustOffset = SINGLE_LINE_ADJUST_OFFSET;
        JJLog(@"SINGLE_LINE_ADJUST_OFFSET = %f",pixelAdjustOffset);
    }
    
    if (self.layoutStyle == JJTableViewLayoutStyleVartical) {
        itemW = [self itemWidth];
        itemH = [self heightForItemAtIndexPath:nil];
        
    } else if (self.layoutStyle == JJTableViewLayoutStyleHorizental) {
        itemW = [self widthForItemAtIndexPath:nil];
        itemH = [self itemHeight];
        
    } else if (self.layoutStyle == JJTableViewLayoutStylePagingHorizental) {
        itemW = [self itemWidth];
        itemH = [self itemHeight];
    }
    
    for (int i=0; i<self.lineCellsRanges.count; i++) {
        CGRect rect = [self.lineCellsRanges[i] CGRectValue];
        
        if (self.separatorStyle & JJTableViewSeparatorStyleRowColumnSingleLine) {
            NSInteger row = [self.lineRows[i] integerValue];
            NSInteger column = [self.lineColumns[i] integerValue];
            
            for (int i=1; i<column; i++) {
                CGFloat startEndX = 0;
                CGFloat startY = 0;
                CGFloat endY = 0;
                
                if (self.layoutStyle == JJTableViewLayoutStyleVartical) {
                    startEndX = marginLeft + i * (itemW + marginColumn) - marginColumn * 0.5;
                    startY = rect.origin.y;
                    endY = rect.origin.y + rect.size.height;
                    
                } else if (self.layoutStyle == JJTableViewLayoutStyleHorizental || self.layoutStyle == JJTableViewLayoutStylePagingHorizental) {
                    startEndX = rect.origin.x + i * (marginColumn + itemW) - marginColumn * 0.5;
                    startY = rect.origin.y;
                    endY = rect.origin.y + rect.size.height;
                }
                
                CGPathMoveToPoint(path, NULL, (int)startEndX - pixelAdjustOffset, startY);
                CGPathAddLineToPoint(path, NULL, (int)startEndX - pixelAdjustOffset, endY);
            }
            
            for (int i=1; i<row; i++) {
                CGFloat startEndY = 0;
                CGFloat startX = 0;
                CGFloat endX = 0;
                
                if (self.layoutStyle == JJTableViewLayoutStyleVartical) {
                    startEndY = rect.origin.y + i * (itemH + marginRow) - marginRow * 0.5;
                    startX = rect.origin.x;
                    endX = rect.origin.x + rect.size.width;
                    
                } else if (self.layoutStyle == JJTableViewLayoutStyleHorizental || self.layoutStyle == JJTableViewLayoutStylePagingHorizental) {
                    startEndY = marginTop + i * (itemH + marginRow) - marginRow * 0.5;
                    startX = rect.origin.x;
                    endX = rect.origin.x + rect.size.width;
                }
                
                CGPathMoveToPoint(path, NULL, startX, (int)startEndY - pixelAdjustOffset);
                CGPathAddLineToPoint(path, NULL, endX, (int)startEndY - pixelAdjustOffset);
            }
        }
        
        CGFloat rectX = [self integralMultipleWithNumber:rect.origin.x];
        CGFloat rectY = [self integralMultipleWithNumber:rect.origin.y];
        CGFloat rectXW = [self integralMultipleWithNumber:(rect.origin.x + rect.size.width)];
        CGFloat rectYH = [self integralMultipleWithNumber:(rect.origin.y + rect.size.height)];
        
        // 防止部分起始点缺失一个像素
        CGFloat sourceX = rect.origin.x;
        CGFloat sourceY = rect.origin.y;
        
        if (self.separatorStyle & JJTableViewSeparatorStyleCellOutlineBorderTopLine) {
            CGPathMoveToPoint(path, NULL, sourceX, rectY - pixelAdjustOffset);
            CGPathAddLineToPoint(path, NULL, rectXW, rectY - pixelAdjustOffset);
        }
        
        if (self.separatorStyle & JJTableViewSeparatorStyleCellOutlineBorderBottomLine) {
            CGPathMoveToPoint(path, NULL, sourceX, rectYH - pixelAdjustOffset);
            CGPathAddLineToPoint(path, NULL, rectXW, rectYH - pixelAdjustOffset);
        }
        
        if (self.separatorStyle & JJTableViewSeparatorStyleCellOutlineBorderLeftLine) {
            CGPathMoveToPoint(path, NULL, rectX - pixelAdjustOffset, sourceY);
            CGPathAddLineToPoint(path, NULL, rectX - pixelAdjustOffset, rectYH);
        }
        
        if (self.separatorStyle & JJTableViewSeparatorStyleCellOutlineBorderRightLine) {
            CGPathMoveToPoint(path, NULL, rectXW - pixelAdjustOffset, sourceY);
            CGPathAddLineToPoint(path, NULL, rectXW - pixelAdjustOffset, rectYH);
        }

    }
    
    if (self.separatorStyle & JJTableViewSeparatorStyleHeaderLeadingTrailingSingleLine) {
        [self.lineHeadersRanges removeAllObjects];
        [self.indexPaths enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull indexPath, NSUInteger idx, BOOL * _Nonnull stop) {
            if (indexPath.item == NSNotFound) {
                [self.lineHeadersRanges addObject:[self.frames objectAtIndex:idx]];
            }
        }];
        
        for (int i=0; i<self.lineHeadersRanges.count; i++) {
            CGRect rect = [self.lineHeadersRanges[i] CGRectValue];
            
            CGFloat rectX = [self integralMultipleWithNumber:rect.origin.x];
            CGFloat rectY = [self integralMultipleWithNumber:rect.origin.y];
            CGFloat rectXW = [self integralMultipleWithNumber:(rect.origin.x + rect.size.width)];
            CGFloat rectYH = [self integralMultipleWithNumber:(rect.origin.y + rect.size.height)];
            
            // 防止部分起始点缺失一个像素
            CGFloat sourceX = rect.origin.x;
            CGFloat sourceY = rect.origin.y;
            
            if (self.separatorStyle & JJTableViewSeparatorStyleHeaderLeadingSingleLine) {
                if (self.layoutStyle == JJTableViewLayoutStyleVartical) {
                    CGPathMoveToPoint(path, NULL, sourceX, rectY - pixelAdjustOffset);
                    CGPathAddLineToPoint(path, NULL, rectXW, rectY - pixelAdjustOffset);
                    
                } else if (self.layoutStyle == JJTableViewLayoutStyleHorizental) {
                    CGPathMoveToPoint(path, NULL, rectX - pixelAdjustOffset, sourceY);
                    CGPathAddLineToPoint(path, NULL, rectX - pixelAdjustOffset, rectYH);
                }
            }
            
            if (self.separatorStyle & JJTableViewSeparatorStyleHeaderTrailingSingleLine) {
                if (self.layoutStyle == JJTableViewLayoutStyleVartical) {
                    CGPathMoveToPoint(path, NULL, sourceX, rectYH - pixelAdjustOffset);
                    CGPathAddLineToPoint(path, NULL, rectXW, rectYH - pixelAdjustOffset);
                    
                } else if (self.layoutStyle == JJTableViewLayoutStyleHorizental) {
                    CGPathMoveToPoint(path, NULL, rectXW - pixelAdjustOffset, sourceY);
                    CGPathAddLineToPoint(path, NULL, rectXW - pixelAdjustOffset, rectYH);
                }
            }
        }
    }
    
    self.backgroundLineLayer.path = path;
    self.backgroundLineLayer.lineWidth = self.separatorWidth;
    self.backgroundLineLayer.fillColor = [UIColor clearColor].CGColor;
    self.backgroundLineLayer.strokeColor = self.separatorColor.CGColor;
    
    CGPathRelease(path);
}

/**
 *  转换为可以给 SINGLE_LINE_ADJUST_OFFSET 减的数值
 *  如果不需要转换则取 SINGLE_LINE_ADJUST_OFFSET 的整数倍（防止多余小数部分依然偏移）
 */
- (CGFloat)integralMultipleWithNumber:(CGFloat)number {
    CGFloat offset = number - (int)number;
    int multiple = offset / SINGLE_LINE_ADJUST_OFFSET;
    
    if (multiple % 2 == 1) {
        number = (int)number + (multiple + 1) * SINGLE_LINE_ADJUST_OFFSET;
    } else {
        number = (int)number + multiple * SINGLE_LINE_ADJUST_OFFSET;
    }
    
    // 处理 top 因为是 0 而减 SINGLE_LINE_ADJUST_OFFSET 看不见的问题，并使最外框线显示在 self 内
    if (number == 0) {
        number = SINGLE_LINE_ADJUST_OFFSET * 2;
    }
    return number;
}

#pragma mark - 拖拽滚动排序处理

/**
 *  判断是否在屏幕中
 */
- (BOOL)isInScreenWithFrame:(CGRect)rect {
    return CGRectGetMaxY(rect) > self.contentOffset.y && CGRectGetMinY(rect) < self.contentOffset.y + self.bounds.size.height
    && CGRectGetMaxX(rect) > self.contentOffset.x && CGRectGetMinX(rect) < self.contentOffset.x + self.bounds.size.width;
}

/**
 *  计算 subviews frame
 */
- (void)refreshFrameUseCache:(BOOL)useCache {
    if (self.layoutStyle == JJTableViewLayoutStyleVartical) {
        [self verticalRefreshFrameUseCache:useCache];
    } else if (self.layoutStyle == JJTableViewLayoutStyleHorizental) {
        [self horizentalRefreshFrameUseCache:useCache];
    } else if (self.layoutStyle == JJTableViewLayoutStylePagingHorizental) {
        [self pagingHorizentalRefreshFrameUseCache:useCache];
    }
}

/**
 *  vertical 计算 subviews frame
 */
- (void)verticalRefreshFrameUseCache:(BOOL)useCache {
    [self.indexPaths removeAllObjects];
    [self.frames removeAllObjects];
    
    //获取间距
    CGFloat marginTop = [self marginForType:JJTableViewMarginTypeTop];
    CGFloat marginLeft = [self marginForType:JJTableViewMarginTypeLeft];
    CGFloat marginRight = [self marginForType:JJTableViewMarginTypeRight];
    CGFloat marginBottom = [self marginForType:JJTableViewMarginTypeBottom];
    CGFloat marginColumn = [self marginForType:JJTableViewMarginTypeColumn];
    CGFloat marginRow = [self marginForType:JJTableViewMarginTypeRow];
    CGFloat headerTop = [self marginForType:JJTableViewMarginTypeHeaderLeading];
    CGFloat headerBottom = [self marginForType:JJTableViewMarginTypeHeaderTrailing];
    
    CGFloat sectionLeading = [self marginForType:JJTableViewMarginTypeSectionLeading];
    CGFloat sectionTrailing = [self marginForType:JJTableViewMarginTypeSectionTrailing];
    
    NSInteger numberOfColumns = [self numberOfColumns];
    
    // 起始 Y
    CGFloat maxY = marginTop;
    
    if (self.separatorStyle != JJTableViewSeparatorStyleNone) {
        [self.lineCellsRanges removeAllObjects];
        [self.lineRows removeAllObjects];
        [self.lineColumns removeAllObjects];
    }
    CGFloat cellStartY = 0;
    CGFloat cellEndY = 0;
    
    // 获取有多少组数据
    NSInteger numberOfSections = [self numberOfSectionsUseCache:useCache];
    
    for (int section=0; section<numberOfSections; section++) {
        
        // 当前 section 组下有多少数据
        NSInteger numberOfItems = [self numberOfItemsInSection:section useCache:useCache];
        
        if ([self isSetSectionHeader]) {
            maxY += headerTop;
            
            CGFloat headerX = 0;
            CGFloat headerY = maxY; // TODO
            CGFloat headerW = self.bounds.size.width;
            CGFloat headerH = [self heightForHeaderInSection:section];
            
            CGRect headerFrame = CGRectMake(headerX, headerY, headerW, headerH);
            
            [self.frames addObject:[NSValue valueWithCGRect:headerFrame]];
            [self.indexPaths addObject:[NSIndexPath indexPathForItem:NSNotFound inSection:section]]; // 设置item为当前section组的总count数(可能与子item重复indexPath)  // 取消总数设置，改为-1
            
            // 更新整体 Y
            maxY += headerH;
            maxY += headerBottom;
            maxY += sectionLeading;
        }
        cellStartY = maxY;
        
        CGFloat itemW = [self itemWidth];
        CGFloat itemH = [self heightForItemAtIndexPath:nil];
        for (int index=0; index<numberOfItems; index++) {
            NSInteger useIndex = [self isSetSectionHeader] ? index : self.frames.count;
            
            NSInteger row = useIndex / numberOfColumns;
            NSInteger column = useIndex % numberOfColumns;
            
            CGFloat itemX = marginLeft + column * (itemW + marginColumn);
            CGFloat itemY = maxY + row * (itemH + marginRow);
            
            CGRect itemFrame = CGRectMake(itemX, itemY, itemW, itemH);
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:section];
            
            [self.frames addObject:[NSValue valueWithCGRect:itemFrame]];
            [self.indexPaths addObject:indexPath];
        }
        
        // 更新整体 Y
        if (numberOfItems > 0 && [self isSetSectionHeader]) {
            float rowCount = (numberOfItems + numberOfColumns - 1) / numberOfColumns;
            maxY += rowCount * (itemH + marginRow) - marginRow;
            
            if (self.separatorStyle != JJTableViewSeparatorStyleNone) {
                cellEndY = maxY;
                CGRect rect = CGRectMake(marginLeft, cellStartY, self.bounds.size.width - marginLeft - marginRight, cellEndY - cellStartY);
                [self.lineCellsRanges addObject:[NSValue valueWithCGRect:rect]];
                [self.lineRows addObject:@(rowCount)];
                [self.lineColumns addObject:@(numberOfColumns)];
            }
            
            maxY += sectionTrailing;
        }
    }
    
    if (![self isSetSectionHeader]) {
        float rowCount = (self.frames.count + numberOfColumns - 1) / numberOfColumns;
        maxY += rowCount * ([self heightForItemAtIndexPath:nil] + marginRow) - marginRow;
        
        if (self.separatorStyle != JJTableViewSeparatorStyleNone) {
            cellEndY = maxY;
            CGRect rect = CGRectMake(marginLeft, cellStartY, self.bounds.size.width - marginLeft - marginRight, cellEndY - cellStartY);
            [self.lineCellsRanges addObject:[NSValue valueWithCGRect:rect]];
            [self.lineRows addObject:@(rowCount)];
            [self.lineColumns addObject:@(numberOfColumns)];
        }
    }
    
    // 更新整体 Y
    maxY += marginBottom;
    self.contentSize = CGSizeMake(self.bounds.size.width, maxY);

    [self refreshBackgroundLine];
}

/**
 *  horizental 计算 subviews frame
 */
- (void)horizentalRefreshFrameUseCache:(BOOL)useCache {
    [self.indexPaths removeAllObjects];
    [self.frames removeAllObjects];
    
    //获取间距
    CGFloat marginTop = [self marginForType:JJTableViewMarginTypeTop];
    CGFloat marginLeft = [self marginForType:JJTableViewMarginTypeLeft];
    CGFloat marginBottom = [self marginForType:JJTableViewMarginTypeBottom];
    CGFloat marginRight = [self marginForType:JJTableViewMarginTypeRight];
    CGFloat marginColumn = [self marginForType:JJTableViewMarginTypeColumn];
    CGFloat marginRow = [self marginForType:JJTableViewMarginTypeRow];
    CGFloat headerTop = [self marginForType:JJTableViewMarginTypeHeaderLeading];
    CGFloat headerBottom = [self marginForType:JJTableViewMarginTypeHeaderTrailing];
    
    CGFloat sectionLeading = [self marginForType:JJTableViewMarginTypeSectionLeading];
    CGFloat sectionTrailing = [self marginForType:JJTableViewMarginTypeSectionTrailing];
    
    NSInteger numberOfRows = [self numberOfRows];
    
    // 起始 X
    CGFloat maxX = marginLeft;
    
    if (self.separatorStyle != JJTableViewSeparatorStyleNone) {
        [self.lineCellsRanges removeAllObjects];
        [self.lineRows removeAllObjects];
        [self.lineColumns removeAllObjects];
    }
    CGFloat cellStartX = 0;
    CGFloat cellEndX = 0;
    
    // 获取有多少组数据
    NSInteger numberOfSections = [self numberOfSectionsUseCache:useCache];
    
    for (int section=0; section<numberOfSections; section++) {
        
        // 当前 section 组下有多少数据
        NSInteger numberOfItems = [self numberOfItemsInSection:section useCache:useCache];
        
        if ([self isSetSectionHeader]) {
            maxX += headerTop;
            
            CGFloat headerX = maxX; // TODO
            CGFloat headerY = 0;
            CGFloat headerW = [self widthForHeaderInSection:section];
            CGFloat headerH = self.bounds.size.height;
            
            CGRect headerFrame = CGRectMake(headerX, headerY, headerW, headerH);
            
            [self.frames addObject:[NSValue valueWithCGRect:headerFrame]];
            [self.indexPaths addObject:[NSIndexPath indexPathForItem:NSNotFound inSection:section]]; // 设置item为当前section组的总count数(可能与子item重复indexPath)实际上不会重复因为下标从0开始 // 取消总数设置，改为-1
            
            // 更新整体 X
            maxX += headerW;
            maxX += headerBottom;
            maxX += sectionLeading;
        }
        cellStartX = maxX;
        
        CGFloat itemW = [self widthForItemAtIndexPath:nil];
        CGFloat itemH = [self itemHeight];
        for (int index=0; index<numberOfItems; index++) {
            NSInteger useIndex = [self isSetSectionHeader] ? index : self.frames.count;
            
            NSInteger row = useIndex % numberOfRows;
            NSInteger column = useIndex / numberOfRows;
            
            CGFloat itemX = maxX + column * (marginColumn + itemW);
            CGFloat itemY = marginTop + row * (itemH + marginRow);
            
            CGRect itemFrame = CGRectMake(itemX, itemY, itemW, itemH);
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:section];
            
            [self.frames addObject:[NSValue valueWithCGRect:itemFrame]];
            [self.indexPaths addObject:indexPath];
        }
        
        // 更新整体 X
        if (numberOfItems > 0 && [self isSetSectionHeader]) {
            float columnCount = (numberOfItems + numberOfRows - 1) / numberOfRows;
            maxX += columnCount * (itemW + marginColumn) - marginColumn;
            
            if (self.separatorStyle != JJTableViewSeparatorStyleNone) {
                cellEndX = maxX;
                CGRect rect = CGRectMake(cellStartX, marginTop, cellEndX - cellStartX, self.bounds.size.height - marginTop - marginBottom);
                [self.lineCellsRanges addObject:[NSValue valueWithCGRect:rect]];
                [self.lineRows addObject:@(numberOfRows)];
                [self.lineColumns addObject:@(columnCount)];
            }
            
            maxX += sectionTrailing;
        }
    }
    
    if (![self isSetSectionHeader]) {
        float columnCount = (self.frames.count + numberOfRows - 1) / numberOfRows;
        maxX += columnCount * ([self widthForItemAtIndexPath:nil] + marginColumn) - marginColumn;
        
        if (self.separatorStyle != JJTableViewSeparatorStyleNone) {
            cellEndX = maxX;
            CGRect rect = CGRectMake(cellStartX, marginTop, cellEndX - cellStartX, self.bounds.size.height - marginTop - marginBottom);
            [self.lineCellsRanges addObject:[NSValue valueWithCGRect:rect]];
            [self.lineRows addObject:@(numberOfRows)];
            [self.lineColumns addObject:@(columnCount)];
        }
    }
    
    // 更新整体 X
    maxX += marginRight;
    self.contentSize = CGSizeMake(maxX, self.bounds.size.height);
    
    [self refreshBackgroundLine];
}

/**
 *  vertical 计算 subviews frame
 */
- (void)pagingHorizentalRefreshFrameUseCache:(BOOL)useCache {
    [self.indexPaths removeAllObjects];
    [self.frames removeAllObjects];
    
    //获取间距
    CGFloat marginTop = [self marginForType:JJTableViewMarginTypeTop];
    CGFloat marginLeft = [self marginForType:JJTableViewMarginTypeLeft];
    CGFloat marginBottom = [self marginForType:JJTableViewMarginTypeBottom];
    CGFloat marginRight = [self marginForType:JJTableViewMarginTypeRight];
    CGFloat marginColumn = [self marginForType:JJTableViewMarginTypeColumn];
    CGFloat marginRow = [self marginForType:JJTableViewMarginTypeRow];
    
    NSInteger numberOfRows = [self numberOfRows];
    NSInteger numberOfColumns = [self numberOfColumns];
    NSInteger pageItemCount = numberOfRows * numberOfColumns;
    
    CGFloat itemW = [self itemWidth];
    CGFloat itemH = [self itemHeight];
    CGFloat pageW = self.bounds.size.width;
    
    // 起始 X
    CGFloat maxX = marginLeft;
    
    if (self.separatorStyle != JJTableViewSeparatorStyleNone) {
        [self.lineCellsRanges removeAllObjects];
        [self.lineRows removeAllObjects];
        [self.lineColumns removeAllObjects];
    }
    
    // 获取有多少组数据
    NSInteger numberOfSections = [self numberOfSectionsUseCache:useCache];
    
    for (int section=0; section<numberOfSections; section++) {
        
        // 当前 section 组下有多少数据
        NSInteger numberOfItems = [self numberOfItemsInSection:section useCache:useCache];
        
        for (int index=0; index<numberOfItems; index++) {
            NSInteger useIndex = self.frames.count;
            
            NSInteger currentPage = useIndex / pageItemCount;
            
            NSInteger row = useIndex / numberOfColumns;
            NSInteger column = useIndex % numberOfColumns;
            
            CGFloat itemX = maxX + (itemW + marginColumn) * column + (currentPage * pageW);
            CGFloat itemY = marginTop + (itemH + marginRow) * (row - currentPage * numberOfRows);
            
            CGRect itemFrame = CGRectMake(itemX, itemY, itemW, itemH);
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:section];
            
            [self.frames addObject:[NSValue valueWithCGRect:itemFrame]];
            [self.indexPaths addObject:indexPath];
        }
    }
    
    NSInteger sumPageCount = (self.frames.count + pageItemCount - 1) / pageItemCount;
    maxX += sumPageCount * pageW - (marginLeft + marginRight);
    
    // 更新整体 X
    maxX += marginRight;
    
    self.contentSize = CGSizeMake(maxX, self.bounds.size.height);
    
    if (self.separatorStyle != JJTableViewSeparatorStyleNone) {
        for (int i=0; i<sumPageCount; i++) {
            CGFloat x = marginLeft + i * pageW;
            CGRect rect = CGRectMake(x, marginTop, pageW - marginLeft - marginRight, self.bounds.size.height - marginTop - marginBottom);
            [self.lineCellsRanges addObject:[NSValue valueWithCGRect:rect]];
            [self.lineRows addObject:@(numberOfRows)];
            [self.lineColumns addObject:@(numberOfColumns)];
        }
        
        [self refreshBackgroundLine];
    }
}

/**
 *  刷新 subviews frame
 */
- (void)refreshLayoutSubviews {
    [self.displayCells enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, UIView * _Nonnull cellView, BOOL * _Nonnull stop) {
        NSInteger idx = [key integerValue];
        cellView.jj_indexPath = self.indexPaths[idx];
        cellView.jj_keyIndex = idx;
        if (_selectedCell != cellView) {
            cellView.frame = [self.frames[idx] CGRectValue];
        }
    }];
}

/**
 *  item 发生长按事件
 */
- (void)itemDidLongPressed:(UILongPressGestureRecognizer *)longPressGesture {
    UIView *pressedView = (UIView *)longPressGesture.view;
    CGPoint newPoint = [longPressGesture locationInView:self];
    
    if (longPressGesture.state == UIGestureRecognizerStateBegan) {
        // 与数据源对比检测数据一致性
        [self refreshCacheSectionItemsWithAddIndexPath:nil subtractIndexPath:nil checkEqual:YES];
        
        // 设置隐藏 cellView closeButton
        [self hiddenCloseButtonInDisplayCells];
        [pressedView jj_setCloseButtonVisible:YES animated:YES];
        
        // 备份 indexPaths
        self.cellDragging = YES;
        
        _lastPoint = newPoint;
        _selectedCell = pressedView;
        pressedView.jj_fromIndexPath = pressedView.jj_indexPath;
        
        // [self.displayCells removeObjectForKey:@(pressedView.jj_keyIndex)];
        // pressedView.transform = CGAffineTransformMakeScale(1.1, 1.1);
        [self animateWithCellView:pressedView duration:JJTableViewAnimateDuration pressed:YES];
        
        // [self bringSubviewToFront:pressedView];
        pressedView.layer.zPosition = 2;
        
        if ([self.dataSource respondsToSelector:@selector(tableView:willBeginMoveItemAtIndexPath:)]) {
            [self.dataSource tableView:self willBeginMoveItemAtIndexPath:pressedView.jj_indexPath];
        }
    }
    
    // 移动 cellView
    CGRect tempRect = longPressGesture.view.frame;
    if (!(self.layoutStyle == JJTableViewLayoutStyleVartical && [self numberOfColumns] == 1)) {
        tempRect.origin.x += newPoint.x - _lastPoint.x;
    }
    if (!(self.layoutStyle == JJTableViewLayoutStyleHorizental && [self numberOfRows] == 1)) {
        tempRect.origin.y += newPoint.y - _lastPoint.y;
    }
    pressedView.frame = tempRect;
    _lastPoint = newPoint;
    
    [self handlerScrollContentForPressedView:pressedView];
    
    [self refreshDisplayCellsWithPoint:newPoint inPressedView:pressedView];
    
    if (longPressGesture.state == UIGestureRecognizerStateEnded || longPressGesture.state == UIGestureRecognizerStateCancelled) {
        // 这里一定要注意设置 _selectedCell = nil 其它地方有使用到，不设置会引起一些逻辑错误
        _selectedCell = nil;
        
        // 取消防止在 UIGestureRecognizerStateCancelled 时定时器还一直启动着
        self.scrollTimer.fireDate = [NSDate distantFuture];
        scrollContentBlock = nil;
        
        // 清除在 UIGestureRecognizerStateBegan 时备份的 indexPaths
        self.cellDragging = NO;
        
        [UIView animateWithDuration:JJTableViewAnimateDuration animations:^{
            // pressedView.transform = CGAffineTransformIdentity;
            [self animateWithCellView:pressedView duration:JJTableViewAnimateDuration pressed:NO];
            
            pressedView.frame = [self.frames[pressedView.jj_keyIndex] CGRectValue];
            pressedView.jj_indexPath = self.indexPaths[pressedView.jj_keyIndex];
            
        } completion:^(BOOL finished) {
            
            if (![pressedView.jj_indexPath isEqual:pressedView.jj_fromIndexPath]) {
                // 设置隐藏或显示 cellView closeButton
                [pressedView jj_setCloseButtonVisible:NO animated:YES];
                
                if ([self.dataSource respondsToSelector:@selector(tableView:moveItemAtIndexPath:toIndexPath:)]) {
                    [self.dataSource tableView:self moveItemAtIndexPath:pressedView.jj_fromIndexPath toIndexPath:pressedView.jj_indexPath];
                }
            }
            
            pressedView.jj_fromIndexPath = nil;
            pressedView.layer.zPosition = 0;
        }];
    }
}

/**
 *  调用 refreshFrameUseCache: 方法然后在使用 UIView 动画调用 refreshLayoutSubviews 方法
 *
 *  @param useCache 是否使用缓存的 _cacheSectionItems
 */
- (void)refreshFrameUseCacheAndUseAnimateCallRefreshLayoutSubviewsUseCache:(BOOL)useCache
                                                                completion:(void (^ __nullable)(BOOL finished))completion {
    [self refreshFrameUseCacheAndUseAnimateCallRefreshLayoutSubviewsUseCache:useCache animateBeforeRefreshFramesAfterPrepare:nil animateAlongsideTransition:nil completion:completion];
}

- (void)refreshFrameUseCacheAndUseAnimateCallRefreshLayoutSubviewsUseCache:(BOOL)useCache
                                    animateBeforeRefreshFramesAfterPrepare:(void (^)())prepareAnimation
                                                animateAlongsideTransition:(void (^)())animation
                                                                completion:(void (^ __nullable)(BOOL finished))completion {
    [self refreshFrameUseCache:useCache];
    if (prepareAnimation) prepareAnimation();
    [UIView animateWithDuration:JJTableViewAnimateDuration animations:^{
        if (animation) animation(); // 这里有个问题改变 transform 后修改 frame 会出现问题
        [self refreshLayoutSubviews];
        
    } completion:completion];

}

/**
 *  刷新 缓存的 _cacheSectionItems
 *
 *  @param addIndexPath      item + 1 的 section
 *  @param subtractIndexPath item - 1 的 section
 */
- (void)refreshCacheSectionItemsWithAddIndexPath:(NSIndexPath *)addIndexPath subtractIndexPath:(NSIndexPath *)subtractIndexPath{
    [self refreshCacheSectionItemsWithAddIndexPath:addIndexPath subtractIndexPath:subtractIndexPath checkEqual:NO];
}

- (void)refreshCacheSectionItemsWithAddIndexPath:(NSIndexPath *)addIndexPath subtractIndexPath:(NSIndexPath *)subtractIndexPath checkEqual:(BOOL)isCheckEqual{
    if (addIndexPath) {
        if (addIndexPath.item != NSNotFound) {
            JJException([_cacheSectionItems[@(addIndexPath.section)] integerValue] >= addIndexPath.item, @"操作的 NSIndexPath 的 section 或 item 数越界。");
        }
        
        NSInteger newitems = [_cacheSectionItems[@(addIndexPath.section)] integerValue] + 1;
        _cacheSectionItems[@(addIndexPath.section)] = @(newitems);
    }
    
    if (subtractIndexPath) {
        NSInteger pNewitems = [_cacheSectionItems[@(subtractIndexPath.section)] integerValue] - 1;
        _cacheSectionItems[@(subtractIndexPath.section)] = @(pNewitems);
    }
    
    if (!isCheckEqual) return;
    
    // check section
    NSInteger numberOfSection = 1; // default 1
    if ([self.dataSource respondsToSelector:@selector(numberOfSectionsInTableView:)]) {
        numberOfSection = [self.dataSource numberOfSectionsInTableView:self];
    }
    JJException(numberOfSection == _cacheSection, @"dataSource 的 numberOfSectionsInTableView: 方法返回的 section 数与当前的不一致！你需要确保在(增、删、改)之前更新对应的数据源。除非是用户进行拖拽后修改的数据，但你也需要在 tableView:moveItemAtIndexPath:toIndexPath: 回调方法中修改对应的数据源否则一样会导致错误发生。");

    // check items
    for (int section=0; section<numberOfSection; section++) {

        NSInteger numberOfItems = [self.dataSource tableView:self numberOfItemsInSection:section];
        JJException([_cacheSectionItems[@(section)] integerValue] == numberOfItems, @"dataSource 的 gridPanView:numberOfItemsInSection: 方法返回的 items 数与当前的不一致！你需要确保在(增、删、改)之前更新对应的数据源。除非是用户进行拖拽后修改的数据，但你也需要在 tableView:moveItemAtIndexPath:toIndexPath: 回调方法中修改对应的数据源否则一样会导致错误发生。");
    }
}

/**
 *  刷新 displayCells 的 key 移动 item 的位置
 *
 *  @param fromIndex      需要移动的 item 或当前拖拽的 item 的 keyIndex
 *  @param toIndex        需要移动位置的 keyIndex
 *  @param isToHeaderView 是否处理移动到一个空的 section 的情况（这种情况在向前移动时需要移动到 headerView 的后面 +1 的位置）
 */
- (void)refreshDisplayCellsWithFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex isToHeaderView:(BOOL)isToHeaderView{
    if (fromIndex == toIndex) return;
    // 刷新 displayCells 的 key
    if (fromIndex < toIndex) {
        // 先移除
        UIView *fromView = self.displayCells[@(fromIndex)];
        [self.displayCells removeObjectForKey:@(fromIndex)];
        // 递归修改其他 key
        [self reverseStartIndex:toIndex endIndex:fromIndex inDisplayCells:self.displayCells];
        // 将自己添加到 toIndex
        [self.displayCells setObject:fromView forKey:@(toIndex)];
        
    } else {
        // 拖拽到（headerView）并且是往前拖拽时，要 +1（在 headerView 后一个到位置）
        if (isToHeaderView) {
            toIndex++;
        }
        
        UIView *fromView = self.displayCells[@(fromIndex)];
        [self.displayCells removeObjectForKey:@(fromIndex)];
        
        [self orderStartIndex:toIndex endIndex:fromIndex inDisplayCells:self.displayCells];
        
        [self.displayCells setObject:fromView forKey:@(toIndex)];
    }
}

/**
 *  刷新 displayCells 的 key 插入一个 item
 *
 *  @param insertIndex 插入的 key (对应 cell 在 indexPaths 中的 index)
 *  @param cellView
 */
- (void)refreshDisplayCellsWithInsertIndex:(NSInteger)insertIndex view:(UIView *)cell {
    [self orderStartIndex:insertIndex endIndex:self.indexPaths.count inDisplayCells:self.displayCells];
    [self.displayCells setObject:cell forKey:@(insertIndex)];
}

/**
 *  倒序从 startIndex 开始到 endIndex 将字典中的 key -1 (不包含 endIndex)
 *  递归方式
 *  @param startIndex       必须比 endIndex 大
 *  @param endIndex         必须比 startIndex 小
 *  @param displayCells
 */
- (void)reverseStartIndex:(NSInteger)startIndex endIndex:(NSInteger)endIndex inDisplayCells:(NSMutableDictionary<NSNumber * ,UIView *> *)displayCells {
    UIView *view = displayCells[@(startIndex)];
    if (startIndex <= endIndex) {
        return;
    } else {
        startIndex--;
        [self reverseStartIndex:startIndex endIndex:endIndex inDisplayCells:displayCells];
        if (view) {
            [displayCells setObject:view forKey:@(startIndex)];
        } else {
            [displayCells removeObjectForKey:@(startIndex)];
        }
    }
}

/**
 *  顺序从 startIndex 开始到 endIndex 将字典中的 key +1 (不包含 endIndex)
 *  递归方式
 *  @param startIndex       必须比 endIndex 小
 *  @param endIndex         必须比 startIndex 大
 *  @param displayCells
 */
- (void)orderStartIndex:(NSInteger)startIndex endIndex:(NSInteger)endIndex inDisplayCells:(NSMutableDictionary<NSNumber * ,UIView *> *)displayCells {
    UIView *view = displayCells[@(startIndex)];
    if (startIndex >= endIndex) {
        return;
    } else {
        startIndex++;
        [self orderStartIndex:startIndex endIndex:endIndex inDisplayCells:displayCells];
        if (view) {
            [displayCells setObject:view forKey:@(startIndex)];
        } else {
            [displayCells removeObjectForKey:@(startIndex)];
        }
    }
}

/**
 *  开始滚动 content
 */
- (void)scrollContent {
    if (scrollContentBlock) {
        scrollContentBlock();
        [self refreshDisplayCellsWithPoint:_lastPoint inPressedView:_selectedCell];
    }
}

/**
 *  处理长按并移动 pressedView 到边边时 scrollView 到滚动
 */
- (void)handlerScrollContentForPressedView:(UIView *)pressedView {
    // __weak typeof(self) weakSelf = self;
    __weak JJTableView *weakSelf = self;
    
    if (self.layoutStyle == JJTableViewLayoutStyleVartical) {
        float upDy = self.contentOffset.y -  CGRectGetMinY(pressedView.frame);
        float downDy = CGRectGetMaxY(pressedView.frame) - (self.contentOffset.y + self.bounds.size.height);
        
        if (_selectedCell && (upDy > 0 || downDy > 0)) {
            float percent = MAX(upDy, downDy) / pressedView.bounds.size.height;
            float step = percent * 100;
            step = (upDy < downDy ? step : -step);
            
            scrollContentBlock = ^(){
                BOOL stopTime = NO;
                
                float offsetY = weakSelf.contentOffset.y + step;
                if (upDy > downDy) {
                    if (offsetY <= 0) {
                        offsetY = 0;
                        stopTime = YES;
                    }
                } else {
                    if (offsetY >= (self.contentSize.height - self.bounds.size.height)) {
                        offsetY = (self.contentSize.height - self.bounds.size.height);
                        stopTime = YES;
                    }
                }
                
                CGPoint newPoint = CGPointMake(weakSelf.contentOffset.x, offsetY);
                [weakSelf setContentOffset:newPoint animated:NO];
                
                if (stopTime) {
                    weakSelf.scrollTimer.fireDate = [NSDate distantFuture];
                } else {
                    // 调整移动的 item frame
                    CGRect moveRect = pressedView.frame;
                    moveRect.origin.y += step;
                    pressedView.frame = moveRect;
                    
                    // 调整记录的 _lastPoint 相对于 scrollview 滚动后的位置
                    _lastPoint.y += step;
                }
            };
            self.scrollTimer.fireDate = [NSDate distantPast];
            
        } else {
            self.scrollTimer.fireDate = [NSDate distantFuture];
        }
    } else if (self.layoutStyle == JJTableViewLayoutStyleHorizental || self.layoutStyle == JJTableViewLayoutStylePagingHorizental) {
        float leftDy = self.contentOffset.x - CGRectGetMinX(pressedView.frame);
        float rightDy = CGRectGetMaxX(pressedView.frame) - (self.contentOffset.x + self.bounds.size.width);
        
        if (_selectedCell && (leftDy > 0 || rightDy > 0)) {
            float percent = MAX(leftDy, rightDy) / pressedView.bounds.size.width;
            float step = percent * 100;
            step = (leftDy < rightDy ? step : -step);
            
            scrollContentBlock = ^(){
                BOOL stopTime = NO;
                
                float offsetX = weakSelf.contentOffset.x + step;
                if (leftDy > rightDy) {
                    if (offsetX <= 0) {
                        offsetX = 0;
                        stopTime = YES;
                    }
                } else {
                    if (offsetX >= (self.contentSize.width - self.bounds.size.width)) {
                        offsetX = (self.contentSize.width - self.bounds.size.width);
                        stopTime = YES;
                    }
                }
                
                CGPoint newPoint = CGPointMake(offsetX, weakSelf.contentOffset.y);
                [weakSelf setContentOffset:newPoint animated:NO];
                
                if (stopTime) {
                    weakSelf.scrollTimer.fireDate = [NSDate distantFuture];
                } else {
                    // 调整移动的 item frame
                    CGRect moveRect = pressedView.frame;
                    moveRect.origin.x += step;
                    pressedView.frame = moveRect;
                    
                    // 调整记录的 _lastPoint 相对于 scrollview 滚动后的位置
                    _lastPoint.x += step;
                }
            };
            self.scrollTimer.fireDate = [NSDate distantPast];
            
        } else {
            self.scrollTimer.fireDate = [NSDate distantFuture];
        }
    }
}

/**
 *  根据 pressedView 所在新的 Point 刷新 displayCells
 */
- (void)refreshDisplayCellsWithPoint:(CGPoint)newPoint inPressedView:(UIView *)pressedView {
    [self.displayCells enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, UIView * _Nonnull cellView, BOOL * _Nonnull stop) {
        if (CGRectContainsPoint(cellView.frame, newPoint) && cellView != _selectedCell &&
            [self canMoveItemAtIndexPath:pressedView.jj_fromIndexPath toIndexPath:self.originalIndexPaths[cellView.jj_keyIndex]]) {
            
            NSIndexPath *containindexPath = cellView.jj_indexPath;
            NSInteger containViewKeyIndex = cellView.jj_keyIndex;
            NSInteger pressedViewKeyIndex = pressedView.jj_keyIndex;
            
            // Notice: 1.在 headerView 并且这个 section 下 item 不为 0 时不处理
            //         2.refreshOriginalIndexPathsWithFromIndexPath: 方法必须在调用 layoutSubViews 之前调用
            if (self.isCellDragging && (cellView.jj_isCellView || [_cacheSectionItems[@(containindexPath.section)] integerValue] <= 0)) {
                [self refreshOriginalIndexPathsWithFromIndexPath:pressedView.jj_indexPath toIndexPath:containindexPath isToHeaderView:[_cacheSectionItems[@(containindexPath.section)] integerValue] <= 0];
            }
            
            if (cellView.jj_isCellView) {
                // 往后移动，插入到 toIndex 前要 -1 插入到后不用 -1
                NSInteger toIndex = (containindexPath.section != pressedView.jj_indexPath.section && containViewKeyIndex > pressedViewKeyIndex) ? containViewKeyIndex - 1 : containViewKeyIndex;
                
                // 刷新 displayCells 的 key
                [self refreshDisplayCellsWithFromIndex:pressedViewKeyIndex toIndex:toIndex isToHeaderView:NO];
                // 刷新缓存的 _cacheSectionItems
                if (containindexPath.section != pressedView.jj_indexPath.section) {
                    [self refreshCacheSectionItemsWithAddIndexPath:containindexPath subtractIndexPath:pressedView.jj_indexPath];
                }
                [self refreshFrameUseCacheAndUseAnimateCallRefreshLayoutSubviewsUseCache:YES completion:^(BOOL finished) {
                    [self setNeedsLayout];
                }];
                
            } else {
                // 当 section headerView 显示时且这个 section 下 item 为 0 时处理
                NSInteger sectionItemCount = [_cacheSectionItems[@(containindexPath.section)] integerValue];
                if (sectionItemCount <= 0) {
                    // 刷新 displayCells 的 key
                    [self refreshDisplayCellsWithFromIndex:pressedViewKeyIndex toIndex:containViewKeyIndex isToHeaderView:YES];
                    // 刷新缓存的 _cacheSectionItems
                    [self refreshCacheSectionItemsWithAddIndexPath:containindexPath subtractIndexPath:pressedView.jj_indexPath];
                    [self refreshFrameUseCacheAndUseAnimateCallRefreshLayoutSubviewsUseCache:YES completion:^(BOOL finished) {
                        [self setNeedsLayout];
                    }];
                }
            }
            *stop = YES;
        }
    }];
}

- (BOOL)canMoveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath {
    if ([self.dataSource respondsToSelector:@selector(tableView:canMoveItemAtIndexPath:toIndexPath:)]) {
        return [self.dataSource tableView:self canMoveItemAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
    }
    return YES;
}

/**
 *  根据移动位置刷新 originalIndexPaths 内对应的 IndexPath 的位置
 *
 *  @param fromIndexPath  正在拖拽的 item 对应的 IndexPath
 *  @param toIndexPath    包含拖拽 point 的 item 对应的 IndexPath
 *  @param isToHeaderView 是否拖拽到 headerView 并且 section 下 item 为 0
 */
- (void)refreshOriginalIndexPathsWithFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath isToHeaderView:(BOOL)isToHeaderView {
    NSInteger fromIndex = [self.indexPaths indexOfObject:fromIndexPath];
    NSInteger toIndex = [self.indexPaths indexOfObject:toIndexPath];
    
    // 不同 section 移动
    if (fromIndexPath.section != toIndexPath.section) {
        if (isToHeaderView) {
            if (fromIndex > toIndex) {
                toIndex++; // 往前移动并且是移动到空 section 的头部时要 -1 。
            }
        } else {
            if (fromIndex < toIndex) {
                toIndex--; // 往后移动时要 -1 因为下面改变 originalIndexPaths 元素位置时是先删除在插入。
            }
        }
    }
    
    // Notice:下面的 moveIndexPath 和方法参数 fromIndexPath 并不相同，fromIndexPath 是 _indexPaths 内对应的 IndexPath,而 moveIndexPath 是 originalIndexPaths 中对应 fromIndex 的 IndexPath。
    NSIndexPath *moveIndexPath = self.originalIndexPaths[fromIndex];
    [self.originalIndexPaths removeObjectAtIndex:fromIndex];
    [self.originalIndexPaths insertObject:moveIndexPath atIndex:toIndex];
}

#pragma mark - UI 动画处理

/**
 *  隐藏所有显示的 cell closeButton
 */
- (void)hiddenCloseButtonInDisplayCells {
    if (![self.delegate respondsToSelector:@selector(tableView:didClickItemCloseButtonAtIndexPath:)])return;
    
    [self.displayCells enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, UIView * _Nonnull view, BOOL * _Nonnull stop) {
        if (view.jj_isCellView) {
            [view jj_setCloseButtonVisible:NO animated:NO];
        }
    }];
}

/**
 *  初始化 cell 在动画开始前的属性
 */
- (void)animateBeforeInitCell:(UIView *)cell animationType:(JJTableViewItemAnimation)animationType{
    if (animationType == JJTableViewItemAnimationFade) {
        cell.alpha = 0;
    } else if (animationType == JJTableViewItemAnimationShrink) {
        cell.transform = CGAffineTransformMakeScale(0.01, 0.01); // 没有使用 core animation 好多坑
    } else {
        cell.hidden = YES;
    }
}

/**
 *  恢复 cell 在动画之后的属性
 */
- (void)animateAfterRestoreCell:(UIView *)cell animationType:(JJTableViewItemAnimation)animationType {
    if (animationType == JJTableViewItemAnimationFade) {
        cell.alpha = 1;
    } else if (animationType == JJTableViewItemAnimationShrink) {
        cell.transform = CGAffineTransformIdentity;
    } else {
        cell.hidden = NO;
    }
}

- (void)animateWithCellView:(UIView *)cellView duration:(NSTimeInterval)duration pressed:(BOOL)isPressed {
    // 使用 core animation 可以避免 view 大小发生改变导致这个 view 内部重新调用一系列方法
    CABasicAnimation* bAnim = [CABasicAnimation animationWithKeyPath:@"transform"];
    bAnim.removedOnCompletion = NO;
    bAnim.fillMode = kCAFillModeForwards;
    bAnim.duration = duration;
    
    if (isPressed) {
        bAnim.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.1, 1.1, 1)];
    } else {
        bAnim.fromValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.1, 1.1, 1)];
    }
    
    [cellView.layer addAnimation:bAnim forKey:@"pressedAnim"];
}

#pragma mark - 获取一些加载所需的 元素

/**
 *  是否设置 section header
 */
- (BOOL)isSetSectionHeader {
    return self.layoutStyle != JJTableViewLayoutStylePagingHorizental && ([self.delegate respondsToSelector:@selector(tableView:viewForHeaderInSection:)] ||
                                                                          [self.delegate respondsToSelector:@selector(tableView:heightForHeaderInSection:)] ||
                                                                        [self.delegate respondsToSelector:@selector(tableView:widthForHeaderInSection:)] ||
                                                                        [self.dataSource respondsToSelector:@selector(tableView:titleForHeaderInSection:)]);
}

/**
 *  获取有多少 section
 *  default 1
 */
- (NSInteger)numberOfSectionsUseCache:(BOOL)useCache {
    if (useCache) {
        return _cacheSection;
    }
    if ([self.dataSource respondsToSelector:@selector(numberOfSectionsInTableView:)]) {
        _cacheSection = [self.dataSource numberOfSectionsInTableView:self];
        return _cacheSection;
    }
    return 1;
}

/**
 *  获取有多少 items
 */
- (NSInteger)numberOfItemsInSection:(NSInteger)section useCache:(BOOL)useCache {
    if (useCache) {
        return [_cacheSectionItems[@(section)] integerValue];
    }
    
    if ([self.dataSource respondsToSelector:@selector(tableView:numberOfItemsInSection:)]) {
        NSInteger numberOfItems = [self.dataSource tableView:self numberOfItemsInSection:section];
        _cacheSectionItems[@(section)] = @(numberOfItems);
        return numberOfItems;
    }
    return 0;
}

- (UIView *)cellForIndexPath:(NSIndexPath *)indexPath {
    UIView *cellView = [self.dataSource tableView:self cellForItemAtIndexPath:indexPath];
    JJException(cellView != nil, @"在 collectionView:cellForItemAtIndexPath: 方法没有返回一个有效的 view。");
    
    // 处理不是通过注册方法创建的 cell ，如果有reuseIdentifier属性并且都设置了 reuseIdentifier 依然支持复用
    if (cellView.jj_identifier == nil) {
        SEL reuseIdentifierSEL = NSSelectorFromString(@"reuseIdentifier");
        if ([cellView respondsToSelector:reuseIdentifierSEL]) {
            NSString *reuseIdentifier = [cellView valueForKey:@"reuseIdentifier"];
            
            if ([reuseIdentifier isKindOfClass:[NSString class]] && ![reuseIdentifier isEqualToString:@""]) {
                cellView.jj_identifier = reuseIdentifier;
                cellView.jj_delegate = self;
                BOOL isUseCloseButton = [self.delegate respondsToSelector:@selector(tableView:didClickItemCloseButtonAtIndexPath:)];
                [cellView jj_prepareCellUseCloseButton:isUseCloseButton closeButtonLocation:self.cellCloseButtonLocation];
            }
        }
    }
    
    cellView.jj_indexPath = indexPath;
    [self refreshMinimumPressDurationWithCell:cellView];
    
    return cellView;
}

/**
 *  获取 section 对应的 headerView
 */
- (UIView *)viewForHeaderInSection:(NSInteger)section {
    UIView *defaultHeaderView = nil;
    if ([self.delegate respondsToSelector:@selector(tableView:viewForHeaderInSection:)]) {
        defaultHeaderView = [self.delegate tableView:self viewForHeaderInSection:section];
        
        if (defaultHeaderView && defaultHeaderView.jj_identifier == nil) {
            SEL reuseIdentifierSEL = NSSelectorFromString(@"reuseIdentifier");
            if ([defaultHeaderView respondsToSelector:reuseIdentifierSEL]) {
                NSString *reuseIdentifier = [defaultHeaderView valueForKey:@"reuseIdentifier"];
                
                if ([reuseIdentifier isKindOfClass:[NSString class]] && ![reuseIdentifier isEqualToString:@""]) {
                    defaultHeaderView.jj_identifier = reuseIdentifier;
                }
            }
        }
    }
    
    if (!defaultHeaderView) {
        // 创建默认 headerView
        defaultHeaderView = [self dequeueReusableHeaderViewWithIdentifier:JJTableViewHeaderViewIdentifier];
        if (!defaultHeaderView) {
            UILabel *headerLabel = [[UILabel alloc] init];
            headerLabel.jj_identifier = JJTableViewHeaderViewIdentifier;
            headerLabel.backgroundColor = self.headerBackgroundColor;
            headerLabel.font = self.headerFont;
            headerLabel.textColor = self.headerTextColor;
            headerLabel.numberOfLines = 0;
            
            defaultHeaderView = headerLabel;
        }
        if ([defaultHeaderView isKindOfClass:[UILabel class]] && [self.dataSource respondsToSelector:@selector(tableView:titleForHeaderInSection:)]) {
            NSString *title = [self.dataSource tableView:self titleForHeaderInSection:section];
            UILabel *headerLabel = (UILabel *)defaultHeaderView;
            if (title) {
                if (self.layoutStyle == JJTableViewLayoutStyleVartical) {
                    headerLabel.text = [@"   " stringByAppendingString:title];
                } else if (self.layoutStyle == JJTableViewLayoutStyleHorizental) {
                    headerLabel.textAlignment = NSTextAlignmentCenter;
                    headerLabel.text = [self VerticalWithString:title];
                }
                
            } else {
                headerLabel.text = nil;
            }
        }
    }
    return defaultHeaderView;
}

- (NSString *)VerticalWithString:(NSString *)string {
    NSMutableString * str = [[NSMutableString alloc] initWithString:string];
    NSInteger count = str.length;
    for (int i = 1; i < count; i ++) {
        [str insertString:@"\n" atIndex: i * 2 - 1];
    }
    return str;
}

/**
 *  获取对应类型的 margin
 */
- (CGFloat)marginForType:(JJTableViewMarginType)type {
    if ([self.delegate respondsToSelector:@selector(tableView:marginForType:)]) {
        return [self.delegate tableView:self marginForType:type];
    } else {
        if (type == JJTableViewMarginTypeHeaderLeading || type == JJTableViewMarginTypeHeaderTrailing ||
            type == JJTableViewMarginTypeSectionLeading || type == JJTableViewMarginTypeSectionTrailing) {
            return 0;
        }
        return JJTableViewDefaultMargin;
    }
}

#pragma mark - header 

- (UIFont *)headerFont {
    if (!_headerFont) {
        _headerFont = [UIFont systemFontOfSize:14];
    }
    return _headerFont;
}

- (UIColor *)headerTextColor {
    if (!_headerTextColor) {
        _headerTextColor = [UIColor colorWithWhite:0.043 alpha:1.000];
    }
    return _headerTextColor;
}

- (UIColor *)headerBackgroundColor  {
    if (!_headerBackgroundColor) {
        _headerBackgroundColor = [UIColor colorWithWhite:0.961 alpha:1.000];
    }
    return _headerBackgroundColor;
}

#pragma mark - V 垂直
/**
 * 获取对应 section header的高度
 */
- (CGFloat)heightForHeaderInSection:(NSInteger)section {
    if ([self.delegate respondsToSelector:@selector(tableView:heightForHeaderInSection:)]) {
        return [self.delegate tableView:self heightForHeaderInSection:section];
    }
    return JJTableViewDefaultHeaderHeight;
}

/**
 * 获取对应 indexPath item的高度
 */
- (CGFloat)heightForItemAtIndexPath:(NSIndexPath *)indexPath; {
    if ([self.delegate respondsToSelector:@selector(heightForCellInTableView:)]) {
        return [self.delegate heightForCellInTableView:self];
    } else {
        return [self itemHeight];
    }
    return JJTableViewDefaultItemHeight;
}

/**
 *  返回每一列的宽度
 */
- (CGFloat)itemWidth {
    NSInteger numberOfColumns = [self numberOfColumns];
    
    CGFloat marginLeft = [self marginForType:JJTableViewMarginTypeLeft];
    CGFloat marginRight = [self marginForType:JJTableViewMarginTypeRight];
    CGFloat marginColumn = [self marginForType:JJTableViewMarginTypeColumn];
    
    CGFloat width = (self.bounds.size.width - marginLeft - marginRight - (numberOfColumns - 1) * marginColumn) / numberOfColumns;
    return width;
}

/**
 *  返回有多少列
 */
- (NSInteger)numberOfColumns {
    if ([self.delegate respondsToSelector:@selector(numberOfColunmsInTableView:)]) {
        return [self.delegate numberOfColunmsInTableView:self];
    }
    return JJTableViewDefaultColumn;
}

#pragma mark - H 水平
/**
 * 获取对应 section header的宽度
 */
- (CGFloat)widthForHeaderInSection:(NSInteger)section {
    if ([self.delegate respondsToSelector:@selector(tableView:widthForHeaderInSection:)]) {
        return [self.delegate tableView:self widthForHeaderInSection:section];
    }
    return JJTableViewDefaultHeaderWidth;
}

/**
 * 获取对应 indexPath item的宽度
 */
- (CGFloat)widthForItemAtIndexPath:(NSIndexPath *)indexPath; {
    if ([self.delegate respondsToSelector:@selector(widthForCellInTableView:)]) {
        return [self.delegate widthForCellInTableView:self];
    } else {
        return [self itemWidth];
    }
    return JJTableViewDefaultItemWidth;
}

/**
 *  返回每一列的高度度
 */
- (CGFloat)itemHeight {
    NSInteger numberOfColumns = [self numberOfRows];
    
    CGFloat marginTop = [self marginForType:JJTableViewMarginTypeTop];
    CGFloat marginBottom = [self marginForType:JJTableViewMarginTypeBottom];
    CGFloat marginRow = [self marginForType:JJTableViewMarginTypeRow];
    
    CGFloat height = (self.bounds.size.height - marginTop - marginBottom - (numberOfColumns - 1) * marginRow) / numberOfColumns;
    return height;
}

/**
 *  返回有多少行
 */
- (NSInteger)numberOfRows {
    if ([self.delegate respondsToSelector:@selector(numberOfRowsInTableView:)]) {
        return [self.delegate numberOfRowsInTableView:self];
    }
    return JJTableViewDefaultRow;
}


#pragma mark - JJTableViewCellDelegate

/**
 *  在不同 section 移动时并且找不到对应的 NSIndexPath 时，调用此方法获取 toIndexPath 相应的位置
 */
- (NSInteger)toIndexOfEmptySectionIndexPath:(NSIndexPath *)toIndexPath {
    
    NSInteger toIndex = NSNotFound;
    
    for (NSInteger section=toIndexPath.section + 1; section < _cacheSection; section++) {
        if ([_cacheSectionItems[@(section)] integerValue] > 0) {
            toIndex = [self.indexPaths indexOfObject:[NSIndexPath indexPathForItem:([self isSetSectionHeader] ? NSNotFound : 0) inSection:section]];
            break;
        }
    }
    if (toIndex == NSNotFound) {
        toIndex = self.indexPaths.count; // 这里不做 -1 处理，逻辑就是要插入到最后一个
    }
    return toIndex;
}

- (void)moveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath {
    NSIndexPath *fromIndexPath = indexPath;
    NSIndexPath *toIndexPath = newIndexPath;
    
    if ((!fromIndexPath && !toIndexPath) || [fromIndexPath isEqual:toIndexPath]) {
        return;
    }
    
    NSInteger index = [self.indexPaths indexOfObject:fromIndexPath];
    UIView *cell = self.displayCells[@(index)];
    
    if (!cell) {
        return;
    }
    
    cell.layer.zPosition = 2;
    
    // 修改 cell 在数组中的位置
    NSInteger toIndex = [self.indexPaths indexOfObject:toIndexPath];
    if (toIndex == NSNotFound) {
        if ([self isSetSectionHeader]) {
            // 处理移动到一个空的 section 中时 toIndex = NSNotFound 的情况
            toIndex = [self.indexPaths indexOfObject:[NSIndexPath indexPathForItem:NSNotFound inSection:toIndexPath.section]];
        } else {
            toIndex = [self toIndexOfEmptySectionIndexPath:toIndexPath];
        }
    }
    
    NSInteger fromIndex = [self.indexPaths indexOfObject:fromIndexPath];
    
    // 不同 section
    NSInteger toSectionItemCount = [_cacheSectionItems[@(toIndexPath.section)] integerValue];
    
    if (fromIndexPath.section != toIndexPath.section) {
        
        // 可以小于，并且等于(添加到最后)
        JJException(toIndexPath.item <= toSectionItemCount && toIndexPath.section < _cacheSectionItems.count, @"toIndexPath 下标越界，不同 section 下 toIndexPath 最大值为最后一个 item + 1 的位置。");
        
        // 处理是最后一个 item
        if (toIndexPath.item == toSectionItemCount && [self isSetSectionHeader]) {
            toIndex += toSectionItemCount + 1;//在最后的后面添加所以+1
        }
        
        // 处理前 后
        if (toIndex > fromIndex) {
            toIndex--; // 前面移动到后面(前面的数量少1)
        }
        
    } else {
        // 同 section
        
        // 可以小于，并且等于(添加到最后)
        JJException(toIndexPath.item != toSectionItemCount, @"toIndexPath 下标越界，同 section 下不允许移动到最后一个 item + 1 的位置。");
    }
    
    // 刷新 displayCells 的 key
    [self refreshDisplayCellsWithFromIndex:fromIndex toIndex:toIndex isToHeaderView:NO];
    
    // 修改 cache section items 并与数据源对比检测数据一致性
    [self refreshCacheSectionItemsWithAddIndexPath:toIndexPath subtractIndexPath:fromIndexPath checkEqual:YES];
    
    [self refreshFrameUseCacheAndUseAnimateCallRefreshLayoutSubviewsUseCache:YES completion:^(BOOL finished) {
        // 设置隐藏 cell closeButton
        [cell jj_setCloseButtonVisible:NO animated:YES];
        cell.layer.zPosition = 0;
        
        // 直接点击 item 改变位置不会触发 layoutsubviews 方法，这样导致有些未加载到 displayCells 中的 item 无法显示。所以手动触发一次
        [self setNeedsLayout];
    }];
}

- (void)deleteItemAtIndexPath:(NSIndexPath *)indexPath withItemAnimation:(JJTableViewItemAnimation)animation {
    // 刷新缓存的 _cacheSectionItems 并与数据源对比检测数据一致性
    [self refreshCacheSectionItemsWithAddIndexPath:nil subtractIndexPath:indexPath checkEqual:YES];
    
    NSInteger deleteIndex = [self.indexPaths indexOfObject:indexPath];
    NSInteger lastIndex = self.indexPaths.count - 1;
    
    // 刷新 displayCells 的 key
    [self refreshDisplayCellsWithFromIndex:deleteIndex toIndex:lastIndex isToHeaderView:NO];
    
    // 移除
    UIView *cell = [self.displayCells objectForKey:@(lastIndex)];
    [self.displayCells removeObjectForKey:@(lastIndex)];
    
    [self refreshFrameUseCacheAndUseAnimateCallRefreshLayoutSubviewsUseCache:YES animateBeforeRefreshFramesAfterPrepare:nil animateAlongsideTransition:^{
        [self animateBeforeInitCell:cell animationType:animation];
        
    } completion:^(BOOL finished) {
        [self animateAfterRestoreCell:cell animationType:animation];
        [cell removeFromSuperview];
        [self.reusableItemCells addObject:cell];
    }];
}

- (void)insertItemAtIndexPath:(NSIndexPath *)indexPath withItemAnimation:(JJTableViewItemAnimation)animation {
    // 刷新缓存的 _cacheSectionItems 并与数据源对比检测数据一致性
    [self refreshCacheSectionItemsWithAddIndexPath:indexPath subtractIndexPath:nil checkEqual:YES];

    // 获取将要插入的位置 index
    NSInteger toIndex = [self.indexPaths indexOfObject:indexPath];
    if (toIndex == NSNotFound) {
        toIndex = [self toIndexOfEmptySectionIndexPath:indexPath];
    }
    
    // 获取 cell
    UIView *cell = [self cellForIndexPath:indexPath];
    
    [self refreshDisplayCellsWithInsertIndex:toIndex view:cell];
    // cell.jj_delegate = self;
    [self addSubview:cell];
    
    
    [self refreshFrameUseCacheAndUseAnimateCallRefreshLayoutSubviewsUseCache:YES animateBeforeRefreshFramesAfterPrepare:^{
        cell.frame = [[self.frames objectAtIndex:[self.indexPaths indexOfObject:indexPath]] CGRectValue];
        [self animateBeforeInitCell:cell animationType:animation];
        
    } animateAlongsideTransition:^{
        [self animateAfterRestoreCell:cell animationType:animation];
        
    } completion:nil];
}

- (void)reloadItemAtIndexPath:(NSIndexPath *)indexPath withItemAnimation:(JJTableViewItemAnimation)animation {
    // 与数据源对比检测数据一致性
    [self refreshCacheSectionItemsWithAddIndexPath:nil subtractIndexPath:nil checkEqual:YES];
    
    NSUInteger index = [self.indexPaths indexOfObject:indexPath];
    UIView *oldCell = self.displayCells[@(index)];
    
    if (!oldCell) return;
    
    // 获取 cell
    UIView *newCell = [self cellForIndexPath:indexPath];
    
    // 使用动画过程中的 frame 防止因在 reload 前调用了其它操作 oldCell 的方法改变了 frame
    CGRect curRect = [[oldCell.layer presentationLayer] frame];
    newCell.frame = curRect;
    
    newCell.jj_keyIndex = oldCell.jj_keyIndex;
    newCell.jj_indexPath = oldCell.jj_indexPath;
    newCell.jj_fromIndexPath = oldCell.jj_fromIndexPath;
    [self.displayCells setObject:newCell forKey:@(index)];
    
    [self addSubview:newCell];
    
    [self animateBeforeInitCell:newCell animationType:animation];
    [UIView animateWithDuration:JJTableViewAnimateDuration animations:^{
        newCell.center = oldCell.center;
        [self animateAfterRestoreCell:newCell animationType:animation];
        [self animateBeforeInitCell:oldCell animationType:animation];
        
    } completion:^(BOOL finished) {
        [self animateAfterRestoreCell:oldCell animationType:animation];
        [oldCell removeFromSuperview];
        [self.reusableItemCells addObject:oldCell];
    }];
}

- (void)cell:(UIView *)cell didLongPressedWithGestureRecognizer:(UILongPressGestureRecognizer *)longPressGesture {
    if (_selectedCell != cell && [self.dataSource respondsToSelector:@selector(tableView:canLongPressAndMoveItemAtIndexPath:)]) {
        
        if (longPressGesture.state == UIGestureRecognizerStateBegan) {
            if (![self.dataSource tableView:self canLongPressAndMoveItemAtIndexPath:cell.jj_indexPath]) {
                [longPressGesture setEnabled:NO];
                return;
            }
            
        } else if (longPressGesture.state == UIGestureRecognizerStateEnded || longPressGesture.state == UIGestureRecognizerStateCancelled) {
            [longPressGesture setEnabled:YES];
            return;
        }
    }
    
    if ([self.dataSource respondsToSelector:@selector(tableView:moveItemAtIndexPath:toIndexPath:)]) {
        [self itemDidLongPressed:longPressGesture];
        
    } else {
        
        _selectedCell = cell;
        UIView *pressedView = longPressGesture.view;
        if (longPressGesture.state == UIGestureRecognizerStateBegan) {
            pressedView.transform = CGAffineTransformMakeScale(1.1, 1.1);
            [self hiddenCloseButtonInDisplayCells];
            [pressedView jj_setCloseButtonVisible:YES animated:YES];
            [longPressGesture setEnabled:NO];
            
        } else if (longPressGesture.state == UIGestureRecognizerStateEnded || longPressGesture.state == UIGestureRecognizerStateCancelled) {
            [UIView animateWithDuration:JJTableViewAnimateDuration animations:^{
                pressedView.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
                [longPressGesture setEnabled:YES];
                _selectedCell = nil;
            }];
        }
    }
}

- (void)didClickCloseButtonInCell:(UIView *)cell {
    if ([self.delegate respondsToSelector:@selector(tableView:didClickItemCloseButtonAtIndexPath:)]) {
        [self.delegate tableView:self didClickItemCloseButtonAtIndexPath:cell.jj_indexPath];
    }
}

- (void)cell:(UIView *)cell didSingleTapWithGestureRecognizer:(UITapGestureRecognizer *)singleTapGesture {
    if ([self.delegate respondsToSelector:@selector(tableView:didSelectItemAtIndexPath:)]) {
        [self.delegate tableView:self didSelectItemAtIndexPath:cell.jj_indexPath];
    }
}

- (void)dealloc {
    _scrollTimer = nil;
}

@end


@implementation UIView (JJTableViewCell)

- (NSInteger)jj_keyIndex {
    return [objc_getAssociatedObject(self, _cmd) intValue];
}

- (void)setJj_keyIndex:(NSInteger)jj_keyIndex {
    objc_setAssociatedObject(self, @selector(jj_keyIndex), @(jj_keyIndex), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSIndexPath *)jj_indexPath{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setJj_indexPath:(NSIndexPath *)jj_indexPath{
    objc_setAssociatedObject(self, @selector(jj_indexPath), jj_indexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSIndexPath *)jj_fromIndexPath{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setJj_fromIndexPath:(NSIndexPath *)jj_fromIndexPath{
    objc_setAssociatedObject(self, @selector(jj_fromIndexPath), jj_fromIndexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSIndexPath *)jj_identifier{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setJj_identifier:(NSIndexPath *)jj_identifier{
    objc_setAssociatedObject(self, @selector(jj_identifier), jj_identifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (UILongPressGestureRecognizer *)jj_longPressGressRecognizer{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setJj_longPressGressRecognizer:(UILongPressGestureRecognizer *)longPressGressRecognizer{
    objc_setAssociatedObject(self, @selector(jj_longPressGressRecognizer), longPressGressRecognizer, OBJC_ASSOCIATION_ASSIGN);
}

#pragma mark -

- (void)jj_prepareCellUseCloseButton:(BOOL)useCloseButton closeButtonLocation:(JJTableViewCellCloseButtonLocation)location{
    if (useCloseButton) {
        [self jj_setupCloseButton];
        self.jj_closeButtonLocation = location;
    }
    [self jj_setupLongPressGesture];
    [self jj_setupTapPressGesture];
    self.jj_cellView = YES;
}

- (id<JJTableViewCellDelegate>)jj_delegate
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setJj_delegate:(id<JJTableViewCellDelegate>)delegate
{
    objc_setAssociatedObject(self, @selector(jj_delegate), delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSLayoutConstraint *)jj_leftRightConstraint {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setJj_leftRightConstraint:(NSLayoutConstraint *)leftRightConstraint {
    objc_setAssociatedObject(self, @selector(jj_leftRightConstraint), leftRightConstraint, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIButton *)jj_closeButton {
    UIButton *closeButton = objc_getAssociatedObject(self, _cmd);
    
    if (!closeButton) {
        closeButton = [[UIButton alloc] init];
        [closeButton setImage:[self deleteIcon] forState:UIControlStateNormal];
        
        closeButton.translatesAutoresizingMaskIntoConstraints = NO;
        [closeButton addTarget:self action:@selector(jj_closeButtonDidClick:) forControlEvents:UIControlEventTouchUpInside];
        objc_setAssociatedObject(self, _cmd, closeButton, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return closeButton;
}

- (void)setJj_closeButton:(UIButton *)closeButton{
    objc_setAssociatedObject(self, @selector(jj_closeButton), closeButton, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)jj_setupCloseButton {
    [self addSubview:self.jj_closeButton];
    
    self.jj_closeButton.hidden = YES;
    self.jj_closeButton.transform = CGAffineTransformMakeScale(0.01, 0.01);
    
    [self.jj_closeButton addConstraint:[NSLayoutConstraint constraintWithItem:self.jj_closeButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:28]];
    [self.jj_closeButton addConstraint:[NSLayoutConstraint constraintWithItem:self.jj_closeButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:28]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.jj_closeButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    self.jj_closeButtonLocation = JJTableViewCellCloseButtonLocationTopLeft;
}

- (JJTableViewCellCloseButtonLocation)jj_closeButtonLocation {
    return [objc_getAssociatedObject(self, _cmd) intValue];
}

- (void)setJj_closeButtonLocation:(JJTableViewCellCloseButtonLocation)closeButtonLocation {
    objc_setAssociatedObject(self, @selector(jj_closeButtonLocation), @(closeButtonLocation), OBJC_ASSOCIATION_ASSIGN);
    
    if (self.jj_leftRightConstraint) {
        [self removeConstraint:self.jj_leftRightConstraint];
    }
    NSLayoutAttribute leftRightConstraintAttribute = (closeButtonLocation == JJTableViewCellCloseButtonLocationTopLeft ? NSLayoutAttributeLeft : NSLayoutAttributeRight);
    self.jj_leftRightConstraint = [NSLayoutConstraint constraintWithItem:self.jj_closeButton attribute:leftRightConstraintAttribute relatedBy:NSLayoutRelationEqual toItem:self attribute:leftRightConstraintAttribute multiplier:1 constant:0];
    [self addConstraint:self.jj_leftRightConstraint];
}

- (void)jj_closeButtonDidClick:(UIButton *)closeButton {
    if ([self.jj_delegate respondsToSelector:@selector(didClickCloseButtonInCell:)]) {
        [self.jj_delegate didClickCloseButtonInCell:self];
    }
}

- (void)jj_setupLongPressGesture {
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(jj_itemLongPressed:)];
    // longPressGesture.cancelsTouchesInView = NO;
    [self addGestureRecognizer:longPressGesture];
    self.jj_longPressGressRecognizer = longPressGesture;
}

- (void)jj_setupTapPressGesture {
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(jj_itemSingleTap:)];
    [self addGestureRecognizer:singleTap];
}

- (void)jj_itemLongPressed:(UILongPressGestureRecognizer *)longPressGesture {
    if ([self.jj_delegate respondsToSelector:@selector(cell:didLongPressedWithGestureRecognizer:)]) {
        [self.jj_delegate cell:self didLongPressedWithGestureRecognizer:longPressGesture];
    }
}

- (void)jj_itemSingleTap:(UITapGestureRecognizer *)singleTapGesture {
    if ([self.jj_delegate respondsToSelector:@selector(cell:didSingleTapWithGestureRecognizer:)]) {
        [self.jj_delegate cell:self didSingleTapWithGestureRecognizer:singleTapGesture];
    }
}

- (void)jj_setCloseButtonVisible:(BOOL)visible animated:(BOOL)animated {
    if (!self.jj_closeButton)return;
    
    if (animated) {
        if (visible) {
            self.jj_closeButton.hidden = !visible;
            self.jj_closeButton.transform = CGAffineTransformMakeScale(0.01, 0.01);
        }
        
        [UIView animateWithDuration:JJTableViewAnimateDuration animations:^{
            if (visible) {
                self.jj_closeButton.transform = CGAffineTransformIdentity;
            } else {
                self.jj_closeButton.transform = CGAffineTransformMakeScale(0.01, 0.01);
            }
        } completion:^(BOOL finished) {
            if (!visible) {
                self.jj_closeButton.hidden = !visible;
            }
        }];
    } else {
        self.jj_closeButton.transform = CGAffineTransformIdentity;
        self.jj_closeButton.hidden = !visible;
    }
}

- (BOOL)jj_isCellView
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setJj_cellView:(BOOL)isCellView
{
    objc_setAssociatedObject(self, @selector(jj_isCellView), @(isCellView), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - delete image

- (UIImage *)deleteIcon {
    static UIImage * image = nil;
    if (image != nil)
        return image;
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(16, 16), NO, 0);
    
    
    //! General Declarations
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //! Oval
    UIBezierPath *oval = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, 16, 16)];
    CGContextSaveGState(context);
    [[UIColor colorWithWhite:0.502 alpha:0.8] setFill];
    [oval fill];
    CGContextRestoreGState(context);
    
    //! Combined Shape
    UIBezierPath *combinedShape = [UIBezierPath bezierPath];
    [combinedShape moveToPoint:CGPointMake(3.25, 3.64)];
    [combinedShape addLineToPoint:CGPointMake(0.08, 0.47)];
    [combinedShape addCurveToPoint:CGPointMake(0.08, 0.08) controlPoint1:CGPointMake(-0.03, 0.36) controlPoint2:CGPointMake(-0.03, 0.19)];
    [combinedShape addCurveToPoint:CGPointMake(0.47, 0.08) controlPoint1:CGPointMake(0.19, -0.03) controlPoint2:CGPointMake(0.36, -0.03)];
    [combinedShape addLineToPoint:CGPointMake(3.64, 3.25)];
    [combinedShape addLineToPoint:CGPointMake(6.82, 0.08)];
    [combinedShape addCurveToPoint:CGPointMake(7.21, 0.08) controlPoint1:CGPointMake(6.92, -0.03) controlPoint2:CGPointMake(7.1, -0.03)];
    [combinedShape addCurveToPoint:CGPointMake(7.21, 0.47) controlPoint1:CGPointMake(7.31, 0.19) controlPoint2:CGPointMake(7.31, 0.36)];
    [combinedShape addLineToPoint:CGPointMake(4.03, 3.64)];
    [combinedShape addLineToPoint:CGPointMake(7.21, 6.82)];
    [combinedShape addCurveToPoint:CGPointMake(7.21, 7.21) controlPoint1:CGPointMake(7.31, 6.92) controlPoint2:CGPointMake(7.31, 7.1)];
    [combinedShape addCurveToPoint:CGPointMake(6.82, 7.21) controlPoint1:CGPointMake(7.1, 7.31) controlPoint2:CGPointMake(6.92, 7.31)];
    [combinedShape addLineToPoint:CGPointMake(3.64, 4.03)];
    [combinedShape addLineToPoint:CGPointMake(0.47, 7.21)];
    [combinedShape addCurveToPoint:CGPointMake(0.08, 7.21) controlPoint1:CGPointMake(0.36, 7.31) controlPoint2:CGPointMake(0.19, 7.31)];
    [combinedShape addCurveToPoint:CGPointMake(0.08, 6.82) controlPoint1:CGPointMake(-0.03, 7.1) controlPoint2:CGPointMake(-0.03, 6.92)];
    [combinedShape addLineToPoint:CGPointMake(3.25, 3.64)];
    [combinedShape closePath];
    [combinedShape moveToPoint:CGPointMake(3.25, 3.64)];
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, 4.47, 4.47);
    combinedShape.lineCapStyle = kCGLineCapRound;
    combinedShape.lineWidth = 0.94;
    [UIColor.whiteColor setStroke];
    [combinedShape stroke];
    CGContextRestoreGState(context);
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end

