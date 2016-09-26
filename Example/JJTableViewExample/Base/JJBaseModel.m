//
//  JJBaseModel.m
//  JJTableViewExample
//
//  Created by jkenny on 16/8/19.
//  Copyright © 2016年 Jkenny. All rights reserved.
//

#import "JJBaseModel.h"

@implementation JJBaseModel

- (instancetype)initWithDict:(NSDictionary *)dict {
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}

+ (instancetype)modelWithDict:(NSDictionary *)dict {
    return [[self alloc] initWithDict:dict];
}

- (id)mutableCopyWithZone:(nullable NSZone *)zone {
    JJBaseModel *baseModel =  [[self class] allocWithZone:zone];
    baseModel.title = _title;
    baseModel.icon = _icon;
    baseModel.url = _url;
    baseModel.status = _status;
    
    return baseModel;
}

@end
