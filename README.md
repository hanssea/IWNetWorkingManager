# IWNetWorkingManager

[![CI Status](https://img.shields.io/travis/JinYang/IWNetWorkingManager.svg?style=flat)](https://travis-ci.org/JinYang/IWNetWorkingManager)
[![Version](https://img.shields.io/cocoapods/v/IWNetWorkingManager.svg?style=flat)](https://cocoapods.org/pods/IWNetWorkingManager)
[![License](https://img.shields.io/cocoapods/l/IWNetWorkingManager.svg?style=flat)](https://cocoapods.org/pods/IWNetWorkingManager)
[![Platform](https://img.shields.io/cocoapods/p/IWNetWorkingManager.svg?style=flat)](https://cocoapods.org/pods/IWNetWorkingManager)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

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
业务类型
*/
typedef NS_ENUM(NSInteger, IWTry) {
IWTryMust = 0,//必达，存储在数据库 无惧于网络环境
IWTryRetry = 1,// 失败会默认重试3次
IWTryNormal=2,//一般业务场景失败就停止
};
/*
请求类型
*/
typedef NS_ENUM(NSInteger, IWSend) {
IWSendPost = 0,//post
IWSendGet = 1,// get
IWSendDelete=2,//delete
IWSendPut, //put
IWSendupload //upload
};


导入头文件
#import <IWNetWorkingManager.h>

只需要在需要网络请求的地方创建一个 IWRequest 实例即可

IWRequest *request=[IWRequest new];
request.url=@"http://t.weather.sojson.com/api/weather/city/101030100";
request.tryMethod=IWTryMust;
request.send=IWSendGet;
[[IWNetWorkingManager share] dataWithRequest:request success:^(NSDictionary * _Nonnull obj) {
NSLog(@"obj %@",obj);
} failure:^(NSError * _Nonnull error) {
NSLog(@"error %@",error);
}];


```
## 作者
```
金阳
jianye0209@yeah.net
```
## License

IWNetWorkingManager is available under the MIT license. See the LICENSE file for more info.
