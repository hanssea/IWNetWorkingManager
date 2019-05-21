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
 业务类型
 */
typedef NS_ENUM(NSInteger, IWTry) {
    IWTryNormal=100,  //一般业务场景失败就停止
    IWTryRetry,       // 失败会默认重试3次
    IWTryMust        //必须要送达的业务，存储在数据库
};
/*
 业务类型
 */
typedef NS_ENUM(NSInteger, IWSend) {
    IWSendPost = 0,//post
    IWSendGet = 1,// get
    IWSendDelete=2,//delete
    IWSendPut, //put
    IWSendupload //upload
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
 业务策略
 */
@property (nonatomic,assign) IWTry tryMethod;
/**
 失败重发次数 默认3次
 */
@property (nonatomic,assign) NSInteger retryCount;
/**
 请求方式
 */
@property (nonatomic,assign) IWSend send;


/**
 图片文件必须是UIImage对象
 */
@property (nonatomic,strong) NSArray *imageArray;




@end

NS_ASSUME_NONNULL_END
