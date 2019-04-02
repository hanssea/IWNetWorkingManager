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
    if (self=[super init]) {
        self.retryCount=3;
        self.tryMethod=IWTryRetry;
        self.send=IWSendPost;
        self.showHUD=NO;
    }return self;
}
- (void)setValue:(id)value forUndefinedKey:(NSString *)key{
    
}

@end
