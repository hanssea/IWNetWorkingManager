//
//  IWRequest.m
//  IWNetWorkingManager_Example
//
//  Created by JinYang on 2019/4/1.
//  Copyright © 2019 JinYang. All rights reserved.
//

#import "IWRequest.h"

@implementation IWRequest

- (instancetype)init{
    self=[super init];
    if (self) {
        _retryCount=3;
        _method=professionalWorkType_post;
        _scence=scence_general;
    }return self;
}
- (void)setValue:(id)value forUndefinedKey:(NSString *)key{
    
}
- (void)setScence:(scence)scence{
    _scence=scence;
}
- (void)setMethod:(professionalWorkType)method{
    _method=method;
}
- (void)setRetryCount:(NSInteger)retryCount{
    _retryCount=retryCount;
}

@end
