# IWNetWorkingManager

[![CI Status](https://img.shields.io/travis/JinYang/IWNetWorkingManager.svg?style=flat)](https://travis-ci.org/JinYang/IWNetWorkingManager)
[![Version](https://img.shields.io/cocoapods/v/IWNetWorkingManager.svg?style=flat)](https://cocoapods.org/pods/IWNetWorkingManager)
[![License](https://img.shields.io/cocoapods/l/IWNetWorkingManager.svg?style=flat)](https://cocoapods.org/pods/IWNetWorkingManager)
[![Platform](https://img.shields.io/cocoapods/p/IWNetWorkingManager.svg?style=flat)](https://cocoapods.org/pods/IWNetWorkingManager)

## 背景
```
请求的可靠性保障是个很容易被忽视的问题，笔者发现市场上很多App的网络请求都是只进行一次请求，失败后直接给用户提示网络错误。基于最近的项目和自己一点想法于是乎有了这套基于业务场景的网络工具，具体实现思路根据三种业务场景将【IWRequest】按业务分类：
1、关键核心业务，期望在任何条件下能百分百送达服务器；
2、重要的内容请求、数据展示，需要较高的成功率；
3、一般性内容请求，对成功率无要求。
```

## 如何安装

```ruby
pod 'IWNetWorkingManager'
```

## 如何使用
```

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



导入头文件
#import <IWNetWorkingManager.h>

 

【用法实例1】

 只需要在需要网络请求的地方创建一个 IWRequest 实例即可
 
 IWRequest *request=[IWRequest new];
 request.url=@"http://t.weather.sojson.com/api/weather/city/101030100";
 request.method=professionalWorkType_get;
 request.scence=scence_general;
 [[IWNetWorkingManager share] dataWithRequest:request success:^(NSDictionary * _Nonnull obj) {
 
 } failure:^(NSError * _Nonnull error) {
 
 }];
 
 
【用法实例2】

 [IWNetWorkingManager  dataWithurl:@"http://t.weather.sojson.com/api/weather/city/101030100" method:professionalWorkType_get scence:scence_general obj:nil success:^(NSDictionary * _Nonnull obj) {

 } failure:^(NSError * _Nonnull error) {

 }];


```
## 作者
```
金阳
hanssea09@gmail.com
```

## 期待
```
如果在使用过程中遇到BUG或者想笔者加入更多功能，希望你能Issues我，谢谢
如果在使用过程中发现功能不够用，希望你能Issues我，我非常想为这个框架增加更多好用的功能，谢谢
如果你想为IWNetWorkingManager输出代码，请Pull Requests我
```
## 版本说明
所有版本均只用于数据处理，为了使工具简单易用笔者并不打算加入其它数据处理之外的功能，请谅解。
```
V1.2.2
【优化】处理issues出现的问题

V1.2.1
【新增】类方法创建请求
【优化】业务数据处理

V1.1.0
【新增】加入对并发量的控制

V1.0.1
【新增】支持三种业务场景的数据处理
```


