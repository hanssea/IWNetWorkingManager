//
//  IWNetWorkingManager.h
//  IWNetWorkingManager_Example
//
//  Created by JinYang on 2019/4/1.
//  Copyright © 2019 JinYang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IWRequest.h"
#import <AFNetworking/AFNetworking.h>

NS_ASSUME_NONNULL_BEGIN


/**
 请求成功回调

 @param obj 返回结果
 */
typedef void (^IWSuccessBlock)(NSDictionary *obj);

/**
 *  请求失败回调
 *
 *  @param error 错误信息
 */
typedef void (^IWFailureBlock)(NSError *error);

@interface IWNetWorkingManager : NSObject

/**
 网络请求工具实例
 */
+ (instancetype)share;

/**
 配置请求头设置
 */
@property (nonatomic,strong,readonly) AFHTTPSessionManager *requestManager;

/**
 获取数据

 @param request 请求实例
 @param success 成功回调
 @param failure 失败回调
 */
- (void)dataWithRequest:(IWRequest*)request  success:(IWSuccessBlock)success failure:(IWFailureBlock)failure;

@end

NS_ASSUME_NONNULL_END
