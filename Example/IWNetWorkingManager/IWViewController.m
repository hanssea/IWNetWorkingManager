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
	
    IWRequest *request=[IWRequest new];
    request.url=@"www.baidu.com";
    request.parameter=@{@"name":@"1"};
    request.tryMethod=IWTryMust;
    request.send=IWSendPost;
    request.showHUD=YES;
    [[IWNetWorkingManager share] dataWithRequest:request success:^(NSDictionary * _Nonnull obj) {
        NSLog(@"obj %@",obj);
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"error %@",error);
    }];
}


@end
