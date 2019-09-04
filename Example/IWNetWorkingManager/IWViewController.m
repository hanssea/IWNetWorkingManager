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
    

    [IWNetWorkingManager  dataWithurl:@"http://t.weather.sojson.com/api/weather/city/101030100" method:professionalWorkType_get scence:scence_general obj:nil success:^(NSDictionary * _Nonnull obj) {
        
    } failure:^(NSError * _Nonnull error) {
        
    }];

}


@end
