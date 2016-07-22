//
//  FriendListVC.m
//  NexFiSDK
//
//  Created by fyc on 16/5/17.
//  Copyright © 2016年 FuYaChen. All rights reserved.
//
#import "NFNearbyUserCell.h"
#import "FriendListVC.h"
#import "UnderdarkUtil.h"
#import "ChatVC.h"
#import "AllUserVC.h"
@interface FriendListVC ()<NFNearbyUserCellDelegate>


@end

@implementation FriendListVC
- (NSMutableArray *)nodeList{
    if (!_nodeList) {
        _nodeList = [[NSMutableArray alloc]initWithCapacity:0];
    }
    return _nodeList;
}
- (NSMutableArray *)handleByUsers{
    if (!_handleByUsers) {
        _handleByUsers = [[NSMutableArray alloc]initWithCapacity:0];
    }
    return _handleByUsers;
}
- (NSMutableArray *)nearbyUsers{
    if (!_nearbyUsers) {
        _nearbyUsers = [[NSMutableArray alloc]initWithCapacity:0];
    }
    return _nearbyUsers;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    
    UIBarButtonItem *RightBarBtn = [[UIBarButtonItem alloc]initWithTitle:@"群聊" style:UIBarButtonItemStylePlain target:self action:@selector(RightBarBtnClick:)];
    self.navigationItem.rightBarButtonItem = RightBarBtn;
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    
    //创建用户信息
    [self creatUserInfo];
    
    //开启监测搜索附近的人
    [UnderdarkUtil share].node.neighbourVc = self;
    [[UnderdarkUtil share].node start];
    
    [self initView];
    
    
    //好友列表
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(refreshTable:) name:@"userInfo" object:nil];
    
    //检测蓝牙是否开启
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(blueToothMsgFail:) name:@"blueToothFail" object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(userListNotify:) name:@"updateUserList" object:nil];
    
 
}
#pragma -mark 创建用户信息
- (void)creatUserInfo{
    
    //创建用户信息 并存储到数据库
    NSArray *arr = @[@"科比",@"詹姆斯",@"麦迪",@"库里",@"乔丹"];
    UserModel *user = [[UserModel alloc]init];
    NSString *armName = [NSString stringWithFormat:@"%@%d",arr[arc4random()%5],arc4random_uniform(100)];
    user.userNick = armName;
    user.userGender = @"1";
    user.userAge = arc4random_uniform(100);
    user.userId = [NexfiUtil uuid];
    user.userAvatar = [NSString stringWithFormat:@"img_head_0%d",1 + arc4random_uniform(9)];
    
    [[UserManager shareManager]loginSuccessWithUser:user];
    
}
#pragma -mark UI
- (void)initView{
    
//    self.usersTable.backgroundColor = [UIColor colorWithHexString:@"#eeeeee"];
    [self.usersTable registerNib:[UINib nibWithNibName:@"NFNearbyUserCell" bundle:nil] forCellReuseIdentifier:@"NFNearbyUserCell"];
    
    
}
#pragma -mark  蓝牙打开失败信息
- (void)blueToothMsgFail:(id)sender{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"蓝牙开启请求" message:@"此app需要通过蓝牙和其他用户进行通信" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
    });
    
}
#pragma -mark 群聊
- (void)RightBarBtnClick:(id)sender{
    AllUserVC *vv = [[AllUserVC alloc]init];
    [self.navigationController pushViewController:vv animated:YES];
}
#pragma -mark NSNotification 用户信息更新
- (void)userListNotify:(NSNotification *)notify{
    NSString *nodeId = notify.userInfo[@"nodeId"];
    
    [self.handleByUsers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UserModel *user = obj;
        if ([user.nodeId isEqualToString:nodeId]) {
            BOOL stop = YES;;
            if (stop == YES) {
                [self.handleByUsers removeObject:user];
            }
            [self.usersTable reloadData];
        }
    }];
    
}
- (void)refreshGetData:(NSDictionary *)dic{
    
    NSDictionary *userDic = dic[@"user"];
    NSString *nodeId = dic[@"nodeId"];
    NSMutableDictionary *user = [[NSMutableDictionary alloc]initWithDictionary:userDic[@"userMessage"]];
    
    UserModel *users = [UserModel mj_objectWithKeyValues:user];
    users.nodeId = nodeId;
    //过滤多余的用户信息
    NSString *update = dic[@"update"];
    if (update) {
        
        for (int i = 0; i < self.handleByUsers.count; i ++) {
            UserModel *user = [self.handleByUsers objectAtIndex:i];
            if ([user.userId isEqualToString:users.userId]) {
                [self.handleByUsers replaceObjectAtIndex:i withObject:users];
            }
        }
        
        
    }else{
        
        
        if (self.handleByUsers.count == 0) {
            [self.handleByUsers addObject:users];
        }else{
            //            for (UserModel *user in self.handleByUsers) {
            //                if (![user.userId isEqualToString:users.userId] && ![self.handleByUsers containsObject:users]) {
            //                    [self.handleByUsers addObject:users];
            //                }
            //            }
            if (![self.handleByUsers containsObject:users]) {
                [self.handleByUsers addObject:users];
            }
        }
        
        self.handleByUsers = (NSMutableArray *)[[self.handleByUsers reverseObjectEnumerator]allObjects];
        
        
    }
    
    //获取所有用户的nodeId
    [self getAllNodeId];
    
    [self.usersTable reloadData];
    
}
- (NSMutableArray *)getAllNodeId{
    for (UserModel *user in self.handleByUsers) {
        [self.nodeList addObject:user.nodeId];
    }
    return self.nodeList;
}
#pragma -mark 私聊
- (void)nearbyUserCellDidClickChatButtonForIndexPath:(NSIndexPath *)indexPath{
    UserModel *to_user = [self.handleByUsers objectAtIndex:indexPath.row];
    ChatVC *chat = [[ChatVC alloc]init];
    chat.to_user = to_user;
    [self.navigationController pushViewController:chat animated:YES];
//    NFSingleChatInfoVC *chat = [[NFSingleChatInfoVC alloc]init];
//    chat.to_user = to_user;
//    [self.navigationController pushViewController:chat animated:YES];
}
#pragma mark - table
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0.1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return 0.1;
    }
    return 3;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
//    UserModel *user = [self.handleByUsers objectAtIndex:indexPath.row];
//    OtherInfoVC *otherVc= [[OtherInfoVC alloc]init];
//    otherVc.user = user;
//    [self.navigationController pushViewController:otherVc animated:YES];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.handleByUsers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NFNearbyUserCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NFNearbyUserCell" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.delegate = self;
    cell.indexPath = indexPath;
    UserModel *user = self.handleByUsers[indexPath.row];
    cell.user = user;
    return cell;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
