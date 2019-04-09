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
        _send=IWSendPost;
        _tryMethod=IWTryNormal;
    }return self;
}
- (void)setValue:(id)value forUndefinedKey:(NSString *)key{
    
}
- (void)setTryMethod:(IWTry)tryMethod{
    _tryMethod=tryMethod;
}
- (void)setRetryCount:(NSInteger)retryCount{
    _retryCount=retryCount;
}
- (void)setSend:(IWSend)send{
    _send=send;
}
@end
