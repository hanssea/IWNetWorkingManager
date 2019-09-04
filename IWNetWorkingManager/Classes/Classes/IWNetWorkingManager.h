//
//  IWNetWorkingManager.h
//  IWNetWorkingManager_Example
//
//  Created by JinYang on 2019/4/1.
//  Copyright © 2019 JinYang. All rights reserved.
//
// GitHub https://github.com/hanssea/IWNetWorkingManager.git
// 欢迎围观、提出您的宝贵意见

#import <Foundation/Foundation.h>
#import "IWRequest.h"
#import <AFNetworking/AFNetworking.h>


#define iw_dispatch_main_async_safe(block)\
if ([NSThread isMainThread]) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}
/**
 回调主线程（显示alert必须在主线程执行）
 
 @param block 执行块
 */
static inline void iw_getSafeMainQueue(_Nonnull dispatch_block_t block)
{
    iw_dispatch_main_async_safe(block);
}



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
 只需要创建即可订阅失败信息
 */
@property (nonatomic,strong) IWFailureBlock errorBlock;
/**
 V1.2.1之前版本 获取数据

 @param request 请求实例
 @param success 成功回调
 @param failure 失败回调
 */
- (void)dataWithRequest:(IWRequest*)request  success:(IWSuccessBlock)success failure:(IWFailureBlock)failure;



/**
 V1.2.1 新增请求API获取数据
 ⚠️之前API依旧可用

 @param url 网址
 @param method 请求方式
 @param scence 业务场景
 @param obj 参数
 @param success 成功
 @param failure 失败
 */
+ (void)dataWithurl:(NSString*)url method:(professionalWorkType)method scence:(scence)scence   obj:(nullable NSDictionary *)obj success:(IWSuccessBlock)success failure:(IWFailureBlock)failure;


@end

NS_ASSUME_NONNULL_END
