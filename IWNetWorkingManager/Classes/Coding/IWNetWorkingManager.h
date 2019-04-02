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
 *  请求成功回调
 *
 *  @param returnData 回调block
 */
typedef void (^IWSuccessBlock)(NSDictionary *obj);

/**
 *  请求失败回调
 *
 *  @param error 回调block
 */
typedef void (^IWFailureBlock)(NSError *error);

@interface IWNetWorkingManager : NSObject

/**
 初始化工具
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
 @param failure 失败会调查
 */
- (void)dataWithRequest:(IWRequest*)request  success:(IWSuccessBlock)success failure:(IWFailureBlock)failure;


@end

NS_ASSUME_NONNULL_END
