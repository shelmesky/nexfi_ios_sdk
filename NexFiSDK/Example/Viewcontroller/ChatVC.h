//
//  ChatVC.h
//  NexFiSDK
//
//  Created by fyc on 16/5/18.
//  Copyright © 2016年 FuYaChen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChatVC : UIViewController
@property (retain, nonatomic)UITableView *chatTable;

@property (nonatomic, retain)UserModel *to_user;
@property (nonatomic ,strong)id<UDLink>link;

- (id<UDLink>)getUserLink;
- (void)refreshGetData:(NSDictionary *)dic;

@end
