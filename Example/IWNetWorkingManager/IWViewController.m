//
//  IWViewController.m
//  IWNetWorkingManager
//
//  Created by JinYang on 04/01/2019.
//  Copyright (c) 2019 JinYang. All rights reserved.
//

#import "IWViewController.h"
#import <IWNetWorkingManager.h>

@interface IWViewController ()

@end

@implementation IWViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    IWRequest *feeds=[[IWRequest alloc] init];
    feeds.url=@"http://t.weather.sojson.com/api/weather/city/101030100";
    feeds.send=IWSendGet;
    [[IWNetWorkingManager share] dataWithRequest:feeds success:^(NSDictionary * _Nonnull obj) {
        NSLog(@"obj %@",obj);
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"error %@",error);
    }];
    
}


@end
