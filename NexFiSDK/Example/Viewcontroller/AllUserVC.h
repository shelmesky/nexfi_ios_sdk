//
//  AllUserVC.h
//  NexFiSDK
//
//  Created by fyc on 16/5/19.
//  Copyright © 2016年 FuYaChen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AllUserVC : UIViewController

@property (nonatomic ,strong)id<UDLink>link;
@property (nonatomic, strong)NSString *peersCount;
@property (retain, nonatomic)UITableView *chatTable;

//- (void)updatePeersCount:(NSString *)peersCount;
- (void)refreshGetData:(NSDictionary *)dic;

@end
