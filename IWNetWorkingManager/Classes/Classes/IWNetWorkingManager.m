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
            _single.group= dispatch_group_create();
        }
    });
    
    return _single;
}
- (instancetype)init
{
    if (self = [super init])
    {
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
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss.SSS"];
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
        request.requestID=request.url;
    }
    
    // 如果是必达业务场景则存储在数据库
    if (request.scence==scence_willMust) {
        
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
        
         [self startTimer];
       
    }
    

    // 将请求保存起来
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
        
        // 处理请求
        [self dealRequest];
    }
}

/**
 处理请求
 */
- (void)dealRequest{
    
    while (self.requestQueue.count>0) {
        IWRequest *request=self.requestQueue.firstObject;
        IWSuccessBlock success=self.successQueue.firstObject;
        IWFailureBlock failure=self.failureQueue.firstObject;
        [self.requestQueue removeObjectAtIndex:0];
        if (self.successQueue.count>0) {
            [self.successQueue removeObjectAtIndex:0];
        }
        if (self.failureQueue.count>0) {
            [self.failureQueue removeObjectAtIndex:0];
        }
        
        dispatch_group_enter(self.group);
        
        dispatch_queue_t requestQuence = dispatch_queue_create("requestQuence", DISPATCH_QUEUE_CONCURRENT);
        //异步执行
        dispatch_async(requestQuence, ^{
            if (request.method==professionalWorkType_post) {
                [self postRequest:request  success:success failure:failure ];
            }else if (request.method==professionalWorkType_get){
                [self getRequest:request  success:success failure:failure];
            }else if (request.method==professionalWorkType_delete){
                [self DELETERequest:request   success:success failure:failure];
            }else if (request.method==professionalWorkType_put){
                [self putRequest:request  success:success failure:failure];
            }else if (request.method==professionalWorkType_upload){
                [self putRequest:request   success:success failure:failure];
            }
        });
    }
    
    dispatch_group_notify(self.group, dispatch_get_main_queue(), ^{
        
    });
    
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
    self.timer = [NSTimer scheduledTimerWithTimeInterval:8 target:self selector:@selector(updateTimer) userInfo:nil repeats:true];
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
    }else{
        [self.timer invalidate];
    }
}
- (void)postRequest:(IWRequest *)request  success:(IWSuccessBlock)success failure:(IWFailureBlock)failure
{
    
    
    [self.manager POST:request.url parameters:request.parameter progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        // 任务完成离开组
        dispatch_group_leave(self.group);
       
        if (success) {
            success(responseObject);
        }
        //移除保存的请求数据
        if (request.scence==scence_willMust) {
            [self deleterequest:request];
        }
        
       
        
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
       
        // 任务完成离开组
        dispatch_group_leave(self.group);
        
        if (failure) {
            failure(error);
        }
        
        if (request.scence==scence_retry) {
            request.retryCount--;
        }else if (request.scence==scence_general){
            request.retryCount=0;
        }
        //添加次数请求数据
        [self dataWithRequest:request success:success failure:failure];
        
        if (self.errorBlock) {
            self.errorBlock(error);
        }
    }];
    
}

- (void)getRequest:(IWRequest *)request  success:(IWSuccessBlock)success failure:(IWFailureBlock)failure
{
   
    [self.manager GET:request.url parameters:request.parameter progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
       
        NSLog(@"request.url ----  %@ 接口返回结果  ---  %@",request.url,responseObject);
       
        // 任务完成离开组
        dispatch_group_leave(self.group);
        
        if (success) {
            success(responseObject);
        }
        //移除保存的请求数据
        if (request.scence==scence_willMust) {
            [self deleterequest:request];
        }
        
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
       
        // 任务完成离开组
        dispatch_group_leave(self.group);
        
        if (failure) {
            failure(error);
        }
        
        if (request.scence==scence_retry) {
            request.retryCount--;
        }else if (request.scence==scence_general){
            request.retryCount=0;
        }
        //添加次数请求数据
        [self dataWithRequest:request success:success failure:failure];
        
    
        if (self.errorBlock) {
            self.errorBlock(error);
        }
    }];
}
- (void)DELETERequest:(IWRequest *)request  success:(IWSuccessBlock)success failure:(IWFailureBlock)failure
{
    
    
    [self.manager DELETE:request.url parameters:request.parameter success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        // 任务完成离开组
        dispatch_group_leave(self.group);
        
        if (success) {
            success(responseObject);
        }
        //移除保存的请求数据
        if (request.scence==scence_willMust) {
            [self deleterequest:request];
        }
      
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        // 任务完成离开组
        dispatch_group_leave(self.group);
        
        if (failure) {
            failure(error);
        }
        
        if (request.scence==scence_retry) {
            request.retryCount--;
        }else if (request.scence==scence_general){
            request.retryCount=0;
        }
        //添加次数请求数据
        [self dataWithRequest:request success:success failure:failure];
       
        if (self.errorBlock) {
            self.errorBlock(error);
        }
       
    }];
}
- (void)putRequest:(IWRequest *)request  success:(IWSuccessBlock)success failure:(IWFailureBlock)failure
{
    
    [self.manager PUT:request.url parameters:request.parameter success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        // 任务完成离开组
        dispatch_group_leave(self.group);
        
        if (success) {
            success(responseObject);
        }
        //移除保存的请求数据
        if (request.scence==scence_willMust) {
            [self deleterequest:request];
        }
        
       
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
       
        // 任务完成离开组
        dispatch_group_leave(self.group);
        
        if (failure) {
            failure(error);
        }
        
        if (request.scence==scence_retry) {
            request.retryCount--;
        }else if (request.scence==scence_general){
            request.retryCount=0;
        }
        //添加次数请求数据
        [self dataWithRequest:request success:success failure:failure];
        
        
        if (self.errorBlock) {
            self.errorBlock(error);
        }
        
       
    }];
}
- (void)uploadRequest:(IWRequest *)request  success:(IWSuccessBlock)success failure:(IWFailureBlock)failure
{
    
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
       
        // 任务完成离开组
        dispatch_group_leave(self.group);
        
        if (success) {
            success(responseObject);
        }
        //移除保存的请求数据
        if (request.scence==scence_willMust) {
            [self deleterequest:request];
        }
        
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        // 任务完成离开组
        dispatch_group_leave(self.group);
        
        if (failure) {
            failure(error);
        }
        
        if (request.scence==scence_retry) {
            request.retryCount--;
        }else if (request.scence==scence_general){
            request.retryCount=0;
        }
        //添加请求数据
        [self dataWithRequest:request success:success failure:failure];
       
        
        if (self.errorBlock) {
            self.errorBlock(error);
        }
        
    }];
    
}
+ (void)dataWithurl:(NSString*)url method:(professionalWorkType)method scence:(scence)scence   obj:(nullable NSDictionary *)obj success:(IWSuccessBlock)success failure:(IWFailureBlock)failure{
    IWRequest *request=[IWRequest new];
    request.url=url;
    request.method=method;
    request.scence=scence;
    request.parameter=obj;
    [[IWNetWorkingManager share]dataWithRequest:request success:success failure:failure];
}
- (AFHTTPSessionManager *)manager{
    if (!_manager) {
        _manager=[AFHTTPSessionManager manager];
        _manager.responseSerializer = [AFJSONResponseSerializer serializer];
        _manager.requestSerializer=[AFJSONRequestSerializer serializer];
        _manager.requestSerializer.timeoutInterval=15;
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
