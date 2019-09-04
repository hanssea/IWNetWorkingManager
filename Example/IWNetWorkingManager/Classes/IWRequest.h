//
//  IWRequest.h
//  IWNetWorkingManager_Example
//
//  Created by JinYang on 2019/4/1.
//  Copyright © 2019 JinYang. All rights reserved.
//  一个请求实例

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/*
 业务场景
 */
typedef NS_ENUM(NSInteger, scence) {
    /**一般场景 请求一次**/
    scence_general=100,
    /**重试场景 默认请求3次挂起**/
    scence_retry,
    /**必达场景 默认存储数据库发送成功后删除链接**/
    scence_willMust
};
/*
 业务类型
 */
typedef NS_ENUM(NSInteger, professionalWorkType) {
    /** post 方式 **/
    professionalWorkType_post = 0,
    /** get 方式 **/
    professionalWorkType_get = 1,
    /** delete 方式 **/
    professionalWorkType_delete=2,
    /** put 方式 **/
    professionalWorkType_put=3,
    /** upload 方式 **/
    professionalWorkType_upload
};


@interface IWRequest : NSObject

/**
 请求ID
 */
@property (nonatomic,copy) NSString  * requestID;
/**
 请求参数
 */
@property (nonatomic,strong) NSDictionary *parameter;
/**
 网址
 */
@property (nonatomic,copy) NSString *url;
/**
 业务场景
 */
@property (nonatomic,assign) scence scence;
/**
 失败重发次数 默认3次
 */
@property (nonatomic,assign) NSInteger retryCount;
/**
 请求方式
 */
@property (nonatomic,assign) professionalWorkType method;


/**
 图片文件必须是UIImage对象
 */
@property (nonatomic,strong) NSArray *imageArray;




@end

NS_ASSUME_NONNULL_END
