//
//  ViewController.m
//  NexFiSDK
//
//  Created by fyc on 16/5/16.
//  Copyright © 2016年 FuYaChen. All rights reserved.
//

#import "ViewController.h"
#import "FriendListVC.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    b.frame = CGRectMake(100, 100, 100, 60);
    [b setTitle:@"用户列表" forState:UIControlStateNormal];
    [b addTarget:self action:@selector(clicks:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:b];
}
- (void)clicks:(id)sender{
    FriendListVC *friend = [[FriendListVC alloc]init];
    [self.navigationController pushViewController:friend animated:YES];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
