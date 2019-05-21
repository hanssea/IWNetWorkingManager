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
@property (nonatomic, strong) dispatch_group_t group;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, strong) dispatch_queue_t workQueue;
@property (nonatomic, strong) dispatch_queue_t addDelQueue;

@end

@implementation IWNetWorkingManager
static IWNetWorkingManager * _single;

+ (instancetype)allocWithZone:(struct _NSZone *)zone{
    
    static dispatch_once_t onceToken;
    // 一次函数
    dispatch_once(&onceToken, ^{
        if (_single == nil) {
            _single = [super allocWithZone:zone];
            _single.group=dispatch_group_create();
            // 创建信号量
            _single.semaphore = dispatch_semaphore_create(3);
            // 创建全局并行
            _single.queue = dispatch_queue_create("IWNetWorkingManager", DISPATCH_QUEUE_SERIAL);
            _single.workQueue = dispatch_queue_create("WorkingQueue", DISPATCH_QUEUE_CONCURRENT);
        }
    });
    
    return _single;
}
- (instancetype)init
{
    if (self = [super init])
    {
        [self startTimer];
        self.manager.requestSerializer.timeoutInterval = 15;
        [self.db jq_createTable:@"requestTab" dicOrModel:[IWRequest new]];
    }
    return self;
}
+ (instancetype)share
{
    return [[self alloc] init];
}

- (NSString *)translocTimeToTimeInterval
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss SSS"];
    NSTimeZone* timeZone = [NSTimeZone localTimeZone];
    [formatter setTimeZone:timeZone];
    NSDate *datenow = [NSDate date];
    NSString *timeSp = [NSString stringWithFormat:@"%ld", (long)[datenow timeIntervalSince1970]*1000];
    return timeSp;
}

- (void)dataWithRequest:(IWRequest *)request success:(IWSuccessBlock)success failure:(IWFailureBlock)failure{
    if (request==nil) {
        return;
    }
    if (request.requestID.length==0) {
        request.requestID=[self translocTimeToTimeInterval];
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

    while(self.requestQueue.count>0) {
        IWRequest *request=self.requestQueue.firstObject;
        IWSuccessBlock success=self.successQueue.firstObject;
        IWFailureBlock failure=self.failureQueue.firstObject;
        if (self.requestQueue.count >0)
        {
            [self.requestQueue removeObjectAtIndex:0];
            if (self.successQueue.count>0) {
                [self.successQueue removeObjectAtIndex:0];
            }
            if (self.failureQueue.count>0) {
                [self.failureQueue removeObjectAtIndex:0];
            }
            
        }
        
        dispatch_async(self.queue, ^{
            dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
            
            dispatch_async(self.workQueue, ^{
                 [[NSThread currentThread] setName:@"sea.king"];
                //发送请求
                if (request.send==IWSendPost) {
                    [self postRequest:request  success:success failure:failure ];
                }else if (request.send==IWSendGet){
                    [self getRequest:request  success:success failure:failure];
                }else if (request.send==IWSendDelete){
                    [self DELETERequest:request   success:success failure:failure];
                }else if (request.send==IWSendPut){
                    [self putRequest:request  success:success failure:failure];
                }else if (request.send==IWSendupload){
                    [self putRequest:request   success:success failure:failure];
                }
            });
            
        });
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
- (void)postRequest:(IWRequest *)request  success:(IWSuccessBlock)success failure:(IWFailureBlock)failure
{
    //1.用于添加对应任务组中的未执行完毕的任务数，执行一次，未执行完毕的任务数加1
    dispatch_group_enter(self.group);
    
    //2.通过异步执行任务
    dispatch_group_async(self.group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
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
            
            if (request.tryMethod==IWTryRetry) {
                request.retryCount--;
            }else if (request.tryMethod==IWTryNormal){
                request.retryCount=0;
            }
            //添加次数请求数据
            [self dataWithRequest:request success:success failure:failure];
           
            
        }];
    });
    
}

- (void)getRequest:(IWRequest *)request  success:(IWSuccessBlock)success failure:(IWFailureBlock)failure
{
    //1.用于添加对应任务组中的未执行完毕的任务数，执行一次，未执行完毕的任务数加1
    dispatch_group_enter(self.group);
    
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
        
        if (request.tryMethod==IWTryRetry) {
            request.retryCount--;
        }else if (request.tryMethod==IWTryNormal){
            request.retryCount=0;
        }
        //添加次数请求数据
        [self dataWithRequest:request success:success failure:failure];
    
    }];
}
- (void)DELETERequest:(IWRequest *)request  success:(IWSuccessBlock)success failure:(IWFailureBlock)failure
{
    //1.用于添加对应任务组中的未执行完毕的任务数，执行一次，未执行完毕的任务数加1
    dispatch_group_enter(self.group);
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
        
        if (request.tryMethod==IWTryRetry) {
            request.retryCount--;
        }else if (request.tryMethod==IWTryNormal){
            request.retryCount=0;
        }
        //添加次数请求数据
        [self dataWithRequest:request success:success failure:failure];
        
    }];
}
- (void)putRequest:(IWRequest *)request  success:(IWSuccessBlock)success failure:(IWFailureBlock)failure
{
    //1.用于添加对应任务组中的未执行完毕的任务数，执行一次，未执行完毕的任务数加1
    dispatch_group_enter(self.group);
    
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
        
        if (request.tryMethod==IWTryRetry) {
            request.retryCount--;
        }else if (request.tryMethod==IWTryNormal){
            request.retryCount=0;
        }
        //添加次数请求数据
        [self dataWithRequest:request success:success failure:failure];
        
    }];
}
- (void)uploadRequest:(IWRequest *)request  success:(IWSuccessBlock)success failure:(IWFailureBlock)failure
{
    //1.用于添加对应任务组中的未执行完毕的任务数，执行一次，未执行完毕的任务数加1
    dispatch_group_enter(self.group);
    [self.manager POST:request.url parameters:request.parameter constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        if (request.imageArray.count==0)return ;
        for (int i = 0; i < request.imageArray.count; i++) {
            
            UIImage *image = request.imageArray[i];
            NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
            
            // 在网络开发中，上传文件时，是文件不允许被覆盖，文件重名
            // 要解决此问题，
            // 可以在上传时使用当前的系统事件作为文件名
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            // 设置时间格式
            [formatter setDateFormat:@"yyyyMMddHHmmss"];
            NSString *dateString = [formatter stringFromDate:[NSDate date]];
            NSString *fileName = [NSString  stringWithFormat:@"%@.jpg", dateString];
            /*
             *该方法的参数
             1. appendPartWithFileData：要上传的照片[二进制流]
             2. name：对应网站上[upload.php中]处理文件的字段（比如upload）
             3. fileName：要保存在服务器上的文件名
             4. mimeType：上传的文件的类型
             */
            [formData appendPartWithFileData:imageData name:@"upload" fileName:fileName mimeType:@"image/jpeg"]; //
        }
        
        
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
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
        
        if (request.tryMethod==IWTryRetry) {
            request.retryCount--;
        }else if (request.tryMethod==IWTryNormal){
            request.retryCount=0;
        }
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
