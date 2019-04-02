//
//  IWNetWorkingManager.m
//  IWNetWorkingManager_Example
//
//  Created by JinYang on 2019/4/1.
//  Copyright © 2019 JinYang. All rights reserved.
//

#import "IWNetWorkingManager.h"
#import "JQFMDB.h"
#import <MJExtension/MJExtension.h>
#import <CommonCrypto/CommonDigest.h>

static NSString * salt =@"aujwejxrlorporttnvk";

@interface  IWNetWorkingManager ()
/**
 请求request数据
 */
@property (nonatomic, strong) NSMutableArray *requestQueue;

/**
 成功回调的request数据
 */
@property (nonatomic, strong) NSMutableArray *successQueue;

/**
 存放request的失败回调
 */
@property (nonatomic, strong) NSMutableArray *failureQueue;

@property (nonatomic, strong) AFHTTPSessionManager *manager;
@property (nonatomic, strong) JQFMDB *db;
/**
 定时器定期轮询
 */
@property (nonatomic, strong) NSTimer *timer;

/**
 信号控制
 */
@property (nonatomic,strong) dispatch_semaphore_t semaphore;
//添加、删除队列，维护添加与删除request在同一个线程
@property (nonatomic, strong) dispatch_queue_t addDelQueue;

@end

//最大并发数
static const int _maxCurrentNum = 3;

@implementation IWNetWorkingManager
static IWNetWorkingManager * _single;

+ (instancetype)allocWithZone:(struct _NSZone *)zone{
    
    static dispatch_once_t onceToken;
    // 一次函数
    dispatch_once(&onceToken, ^{
        if (_single == nil) {
            _single = [super allocWithZone:zone];
        }
    });
    
    return _single;
}
- (instancetype)init
{
    if (self = [super init])
    {
        [self startTimer];
        self.semaphore = dispatch_semaphore_create(_maxCurrentNum);
        [self.db jq_createTable:@"requestTab" dicOrModel:[IWRequest new]];
    }
    return self;
}
+ (instancetype)share
{
    return [[self alloc] init];
}
- (NSString *)MD5lower:(NSString *)inputmessage
{
    const char *cStr = [[inputmessage stringByAppendingString:salt] UTF8String];
    //开辟一个16字节的空间
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    /*
     extern unsigned char * CC_MD5(const void *data, CC_LONG len, unsigned char *md)官方封装好的加密方法
     把str字符串转换成了32位的16进制数列（这个过程不可逆转） 存储到了md这个空间中
     */
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    return [[NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
             result[0], result[1], result[2], result[3],
             result[4], result[5], result[6], result[7],
             result[8], result[9], result[10], result[11],
             result[12], result[13], result[14], result[15]
             ] lowercaseString];  //大小写注意
    
}
- (void)dataWithRequest:(IWRequest *)request success:(IWSuccessBlock)success failure:(IWFailureBlock)failure{
    if (request==nil) {
        return;
    }
    if (request.requestID.length==0) {
        request.requestID=[self MD5lower:request.url];
    }
    
    // 如果是必达业务场景则存储在数据库
    if (request.tryMethod==IWTryMust) {
        
        NSArray *data=[self.db jq_lookupTable:@"requestTab" dicOrModel:[IWRequest class] whereFormat:nil];
        if (data.count>0) {
            for (IWRequest *dbrequest in data) {
                if (![dbrequest.requestID isEqualToString:request.requestID]) {
                    [self.db jq_insertTable:@"requestTab" dicOrModel:request.mj_keyValues];
                }
            }
        }else{
             [self.db jq_insertTable:@"requestTab" dicOrModel:request.mj_keyValues];
        }
       
    }
    
    // 将请求保存起来
    dispatch_async(self.addDelQueue, ^{
        if ([self.requestQueue containsObject:request]) return;
        if (request.retryCount>0) {
            NSLog(@"处理的第 %ld 次请求",request.retryCount);
            [self.requestQueue addObject:request];
            //做容错处理，如果block为空，设置默认block
            id tmpBlock = [success copy];
            if (success == nil)
            {
                tmpBlock = [^(id obj){} copy];
            }
            [self.successQueue addObject:tmpBlock];
            
            
            tmpBlock = [failure copy];
            if (failure == nil)
            {
                tmpBlock = [^(id obj){} copy];
            }
            [self.failureQueue addObject:tmpBlock];
            
            [self dealRequest];
        }
    });
}

/**
 处理请求
 */
- (void)dealRequest{
    //在子线程处理
    while(self.requestQueue.count>0) {
        IWRequest *request=self.requestQueue.firstObject;
        IWSuccessBlock success=self.successQueue.firstObject;
        IWFailureBlock failure=self.failureQueue.firstObject;
        if (self.requestQueue.count >= 1)
        {
            [self.requestQueue removeObjectAtIndex:0];
            [self.successQueue removeObjectAtIndex:0];
            [self.failureQueue removeObjectAtIndex:0];
        }
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
        //发送请求
        
        if (request.send==IWSendPost) {
          [self postRequest:request success:success failure:failure];
        }else if (request.send==IWSendGet){
           [self getRequest:request success:success failure:failure];
        }else if (request.send==IWSendDelete){
           [self DELETERequest:request success:success failure:failure];
        }else if (request.send==IWSendPut){
           [self putRequest:request success:success failure:failure];
        }else if (request.send==IWSendupload){
            [self putRequest:request success:success failure:failure];
        }
    }
}

/**
 删除保存的请求数据

 @param request IWRequest
 */
- (void)deleterequest:(IWRequest*)request
{
    [self.db jq_deleteTable:@"requestTab" whereFormat:@"where requestID=%@",request.requestID];
}

#pragma mark - Timer
- (void)startTimer
{
    [self.timer invalidate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(updateTimer) userInfo:nil repeats:true];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
}

/**
 轮询数据
 */
- (void)updateTimer{
    //开辟子线程进行事务处理
    NSArray *data=[self.db jq_lookupTable:@"requestTab" dicOrModel:[IWRequest class] whereFormat:nil];
    NSLog(@"正在跑批...当前待完成事物量 %ld",data.count);
    if (data.count>0) {
        for (IWRequest *request in data) {
             [self.requestQueue addObject:request];
            // 容错处理
            [self.successQueue addObject:[^(id obj){} copy]];
            [self.failureQueue addObject: [^(id obj){} copy]];
        }
        [self dealRequest];
    }
}
- (void)postRequest:(IWRequest *)request success:(IWSuccessBlock)success failure:(IWFailureBlock)failure
{
    [self.manager POST:request.url parameters:request.parameter progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
         dispatch_semaphore_signal(self.semaphore);
        if (success) {
            success(responseObject);
        }
        //移除保存的请求数据
        if (request.tryMethod==IWTryMust) {
            [self deleterequest:request];
        }
        
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
         dispatch_semaphore_signal(self.semaphore);
        if (failure) {
            failure(error);
        }
        
         request.retryCount--;
        
        //添加次数请求数据
        [self dataWithRequest:request success:success failure:failure];
        
    }];
}

- (void)getRequest:(IWRequest *)request success:(IWSuccessBlock)success failure:(IWFailureBlock)failure
{
    [self.manager GET:request.url parameters:request.parameter progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        dispatch_semaphore_signal(self.semaphore);
        if (success) {
            success(responseObject);
        }
        //移除保存的请求数据
        if (request.tryMethod==IWTryMust) {
            [self deleterequest:request];
        }
        
       
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        dispatch_semaphore_signal(self.semaphore);
        if (failure) {
            failure(error);
        }
        
         request.retryCount--;
        //添加次数请求数据
        [self dataWithRequest:request success:success failure:failure];
        
        
    }];
}
- (void)DELETERequest:(IWRequest *)request success:(IWSuccessBlock)success failure:(IWFailureBlock)failure
{
    [self.manager DELETE:request.url parameters:request.parameter success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        dispatch_semaphore_signal(self.semaphore);
        if (success) {
            success(responseObject);
        }
        //移除保存的请求数据
        if (request.tryMethod==IWTryMust) {
            [self deleterequest:request];
        }
        
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        dispatch_semaphore_signal(self.semaphore);
        if (failure) {
            failure(error);
        }
        
        request.retryCount--;
        //添加次数请求数据
        [self dataWithRequest:request success:success failure:failure];
        
    }];
}
- (void)putRequest:(IWRequest *)request success:(IWSuccessBlock)success failure:(IWFailureBlock)failure
{
    [self.manager PUT:request.url parameters:request.parameter success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        dispatch_semaphore_signal(self.semaphore);
        if (success) {
            success(responseObject);
        }
        //移除保存的请求数据
        if (request.tryMethod==IWTryMust) {
            [self deleterequest:request];
        }
        
       
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        dispatch_semaphore_signal(self.semaphore);
        if (failure) {
            failure(error);
        }
        
         request.retryCount--;
        //添加次数请求数据
        [self dataWithRequest:request success:success failure:failure];
        
    }];
}
- (void)uploadRequest:(IWRequest *)request success:(IWSuccessBlock)success failure:(IWFailureBlock)failure
{
    [self.manager POST:request.url parameters:request.parameter constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyyMMddHHmmss";
        NSString *fileName = [NSString stringWithFormat:@"%@.png",[formatter stringFromDate:[NSDate date]]];
        //二进制文件，接口key值，文件路径，图片格式
        [formData appendPartWithFileData:request.imageData name:@"file" fileName:fileName mimeType:@"image/jpg/png/jpeg"];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) {
            success(responseObject);
        }
        //移除保存的请求数据
        if (request.tryMethod==IWTryMust) {
            [self deleterequest:request];
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) {
            failure(error);
        }
        
        request.retryCount--;
        //添加次数请求数据
        [self dataWithRequest:request success:success failure:failure];
        
    }];
}
- (AFHTTPSessionManager *)manager{
    if (!_manager) {
        _manager=[AFHTTPSessionManager manager];
        _manager.responseSerializer = [AFJSONResponseSerializer serializer];
        _manager.requestSerializer=[AFJSONRequestSerializer serializer];
        _manager.responseSerializer = [AFJSONResponseSerializer serializer];
        [_manager.requestSerializer willChangeValueForKey:@"timeoutInterval"];
        _manager.requestSerializer.timeoutInterval = 15;
        [_manager.requestSerializer didChangeValueForKey:@"timeoutInterval"];
        _manager.responseSerializer.acceptableContentTypes =[NSSet setWithObjects:@"text/plain", @"multipart/form-data", @"application/json", @"text/html", @"image/jpeg", @"image/png",@"image/jpg", @"application/octet-stream", @"text/json",@"text/javascript", nil];
    }return _manager;
}
- (AFHTTPSessionManager *)requestManager{
    return self.manager;
}
- (NSMutableArray *)requestQueue{
    if (!_requestQueue) {
        _requestQueue=[[NSMutableArray alloc] init];
    }return _requestQueue;
}
- (NSMutableArray *)successQueue{
    if (!_successQueue) {
        _successQueue=[[NSMutableArray alloc] init];
    }return _successQueue;
}

- (NSMutableArray *)failureQueue{
    if (!_failureQueue) {
        _failureQueue=[[NSMutableArray alloc] init];
    }return _failureQueue;
}
- (dispatch_queue_t)addDelQueue
{
    if (!_addDelQueue)
    {
        _addDelQueue = dispatch_queue_create("com.addDel.www", DISPATCH_QUEUE_SERIAL);
    }
    return _addDelQueue;
}
- (JQFMDB *)db{
    if (!_db) {
        _db = [JQFMDB shareDatabase];
    }return _db;
}
@end
