//
//  Node.h
//  UnderdarkTest
//
//  Created by fyc on 16/3/28.
//  Copyright © 2016年 FuYaChen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserModel.h"
#import "ViewController.h"
//#import "NFSingleChatInfoVC.h"
//#import "NeighbourVC.h"
//#import "NFAllUserChatInfoVC.h"
#import "FriendListVC.h"
#import "ChatVC.h"
#import "AllUserVC.h"

@protocol NodeDelegate <NSObject>
/**
 *单聊发送消息失败
 */

- (void)singleChatSendFailWithInfo:(NSString *)failMsg;

/**
 *群聊发送消息失败
 */
- (void)AllUserChatSendFailWithInfo:(NSString *)failMsg;

@end

@interface Node : NSObject<UDTransportDelegate>

/**
 *下面三个VC测试代码
 */
@property (nonatomic,strong)FriendListVC *neighbourVc;
@property (nonatomic,strong)ChatVC *chatVc;
@property (nonatomic,strong)AllUserVC * alluserVc;
//@property (nonatomic,strong)NFSingleChatInfoVC *singleVC;
//@property (nonatomic,strong)NFAllUserChatInfoVC *allUserChatVC;
/**
 *初始化传输 transport
 */
@property (nonatomic ,strong)id<UDTransport>transport;
/**
 *连接link数
 */
@property (nonatomic, assign)int peersCount;
/**
 *唯一标识符
 */
@property (nonatomic, assign)int appId;
/**
 *唯一标识符 对应每一个人
 */
@property (nonatomic, assign)long long int nodeId;
/**
 *队列
 */
@property (nonatomic, strong)dispatch_queue_t queue;
/**
 *存放link的容器
 */
@property (nonatomic, strong)NSMutableArray *links;
/**
 *与每一个node的连接
 */
@property (nonatomic ,strong)id<UDLink>link;

@property (nonatomic, assign)id<NodeDelegate>delegate;

- (void)broadcastFrame:(id<UDSource>)frameData WithMessageType:(MessageType)messageType;



/**
 *开启蓝牙/WIFI 监测
 */

- (void)start;

/**
 *关闭蓝牙/WIFI 监测
 */

- (void)stop;


/**
 *获取所有用户
 */

- (NSMutableArray *)getNumberOfUsers;

/**
 *单聊发送消息接口
 *frameData参数由此函数获得 UDLazySource *r = [UDLazySource alloc]initWithQueue:<#(nullable dispatch_queue_t)#> block:<#^NSData * _Nullable(void)block#>
 */

- (void)singleChatWithFrame:(id<UDSource>)frameData WithUserNodeId:(NSString *)userNodeId;


/**
 *群聊发送消息接口
 *frameData参数由此函数获得 UDLazySource *r = [UDLazySource alloc]initWithQueue:<#(nullable dispatch_queue_t)#> block:<#^NSData * _Nullable(void)block#>
 */

- (void)allUserChatWithFrame:(id<UDSource>)frameData;


/**
 *发送 用户信息请求消息 （eMessageType_requestUserInfo）用户信息返回消息 （eMessageType_SendUserInfo）
 *更新用户信息 （eMessageType_UpdateUserInfo）
 *MessageType  自己定义
 */

- (id<UDSource>)sendMsgWithMessageType:(MessageType)type;


/**
 *用户接收消息接口  自定义消息类型区分不同类型的消息 messageType
 */

- (void)transport:(id<UDTransport>)transport link:(id<UDLink>)link didReceiveFrame:(NSData *)frameData WithProgress:(float)progress;


/**
 *用户失去连接
 */

- (void)transport:(id<UDTransport>)transport linkDisconnected:(id<UDLink>)link;


/**
 *用户连接成功
 */

- (void)transport:(id<UDTransport>)transport linkConnected:(id<UDLink>)link;


@end
