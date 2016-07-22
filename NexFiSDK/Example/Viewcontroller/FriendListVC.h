//
//  FriendListVC.h
//  NexFiSDK
//
//  Created by fyc on 16/5/17.
//  Copyright © 2016年 FuYaChen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FriendListVC : UIViewController

//@property (nonatomic,strong) UITableView *usersTable;
@property (weak, nonatomic) IBOutlet UITableView *usersTable;
@property (nonatomic,strong) NSMutableArray *nearbyUsers;
@property (nonatomic,strong) NSMutableArray *handleByUsers;

@property (nonatomic,strong) NSMutableArray *nodeList;

@property (nonatomic ,retain) NSString *peesCount;

- (void)refreshGetData:(NSDictionary *)dic;
- (NSMutableArray *)getAllNodeId;

@end
