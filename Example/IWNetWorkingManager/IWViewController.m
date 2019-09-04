//
//  IWViewController.m
//  IWNetWorkingManager
//
//  Created by JinYang on 04/01/2019.
//  Copyright (c) 2019 JinYang. All rights reserved.
//

#import "IWViewController.h"
#import "IWNetWorkingManager.h"
@interface IWViewController ()

@end

@implementation IWViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    IWRequest *request=[IWRequest new];
//    request.url=@"http://t.weather.sojson.com/api/weather/city/101030100";
//    request.method=professionalWorkType_get;
//    request.scence=scence_general;
//    [[IWNetWorkingManager share] dataWithRequest:request success:^(NSDictionary * _Nonnull obj) {
//
//    } failure:^(NSError * _Nonnull error) {
//
//    }];
//
    //郑州天气
    [IWNetWorkingManager  dataWithurl:@"http://t.weather.sojson.com/api/weather/city/101180101" method:professionalWorkType_get scence:scence_general obj:nil success:^(NSDictionary * _Nonnull obj) {
        
    } failure:^(NSError * _Nonnull error) {
        
    }];
    
    //南京天气
    [IWNetWorkingManager  dataWithurl:@"http://t.weather.sojson.com/api/weather/city/101190101" method:professionalWorkType_get scence:scence_general obj:nil success:^(NSDictionary * _Nonnull obj) {
        
    } failure:^(NSError * _Nonnull error) {
        
    }];
    
    //西安天气
    [IWNetWorkingManager  dataWithurl:@"http://t.weather.sojson.com/api/weather/city/101110101" method:professionalWorkType_get scence:scence_general obj:nil success:^(NSDictionary * _Nonnull obj) {
        
    } failure:^(NSError * _Nonnull error) {
        
    }];
    

    

}


@end
