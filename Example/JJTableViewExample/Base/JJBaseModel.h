//
//  JKBaseModel.h
//  JJTableViewExample
//
//  Created by jkenny on 16/8/19.
//  Copyright © 2016年 Jkenny. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JJBaseModel : NSObject <NSMutableCopying>

@property (nonatomic,copy) NSString *title;
@property (nonatomic,copy) NSString *icon;
@property (nonatomic,copy) NSString *url;
@property (nonatomic,assign) int status;

+ (instancetype)modelWithDict:(NSDictionary *)dict;
- (instancetype)initWithDict:(NSDictionary *)dict;

@end
