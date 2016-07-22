//
//  ChatVC.m
//  NexFiSDK
//
//  Created by fyc on 16/5/18.
//  Copyright © 2016年 FuYaChen. All rights reserved.
//

#import "ChatVC.h"
#import "SenderTextCell.h"
#import "SenderAvatarCell.h"
#import "ReceiverAvatarCell.h"
#import "ReceiverVoiceCell.h"
#import "SenderVoiceCell.h"
#import "TextCell.h"
#import "UnderdarkUtil.h"
#import "FNAVAudioPlayer.h"

@interface ChatVC ()<chatCellDelegate,XMChatBarDelegate,NodeDelegate,UITableViewDelegate,UITableViewDataSource>

@property (strong, nonatomic) XMChatBar *chatBar;
@property (nonatomic, strong) NSMutableArray *msgs;
@property (nonatomic, assign) BOOL sendOnce;
@property (nonatomic, strong) NSArray *historyMsgs;
@property (nonatomic, assign) BOOL wasKeyboardManagerEnabled;//iqkeyboard 和 xmchatBar 有冲突


@end

@implementation ChatVC

- (NSMutableArray *)msgs{
    if (!_msgs) {
        _msgs = [[NSMutableArray alloc]initWithCapacity:0];
        
    }
    return _msgs;
}
//IQKeyboardManager 禁用
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
 
    _wasKeyboardManagerEnabled = [[IQKeyboardManager sharedManager] isEnabled];
    [[IQKeyboardManager sharedManager] setEnable:NO];
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[IQKeyboardManager sharedManager] setEnable:_wasKeyboardManagerEnabled];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.extendedLayoutIncludesOpaqueBars = NO;
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    [UnderdarkUtil share].node.chatVc = self;
    [UnderdarkUtil share].node.delegate = self;
    
    self.chatTable=[[UITableView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_SIZE.width, SCREEN_SIZE.height-64 -kMinHeight) style:UITableViewStylePlain];
    self.chatTable.delegate=self;
    self.chatTable.dataSource=self;
    //取消tableview上的横线
    self.chatTable.separatorStyle=UITableViewCellSeparatorStyleNone;
    
    //为了让下面的图片显示出来，把背景颜色置为cleanColor
    self.chatTable.backgroundColor=[UIColor clearColor];
    [self.view addSubview:self.chatTable];
    
    self.chatTable.rowHeight = UITableViewAutomaticDimension;
    
    
    [self.view addSubview:self.chatBar];
    
    //获取历史数据
    [self showHistoryMsgWithCount:0];
    [self setupDownRefresh];

    
}
- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 200;
}
- (void)setupDownRefresh
{
    // 设置回调（一旦进入刷新状态，就调用target的action，也就是调用self的loadNewData方法）
    MJCommonHeader *header = [MJCommonHeader headerWithRefreshingBlock:^{
        [self showHistoryMsgWithCount:self.msgs.count];
    }];
    
    // 设置header
    self.chatTable.header = header;
    
    //    [header beginRefreshing];
}
- (void)showHistoryMsgWithCount:(NSInteger)count{
    //别人发我，我发别人都要取出来
    self.historyMsgs = [[SqlManager shareInstance]getChatHistory:self.to_user.userId withToId:self.to_user.userId withStartNum:count];
    
    for (PersonMessage *msg in self.historyMsgs) {
        [self showHistoryTableMsg:msg];
    }
    
    
    [self.chatTable.header endRefreshing];
}
-(void)showHistoryTableMsg:(PersonMessage *)msg{
    
    [self.msgs insertObject:msg atIndex:0];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.chatTable reloadData];
        
    });
    
}
-(void)showTableMsg:(PersonMessage *) msg
{
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    [self.msgs addObject:msg];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.msgs count]-1 inSection:0];
    [indexPaths addObject:indexPath];

        //            [_tableView beginUpdates];
    [self.chatTable insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationBottom];
        //            [_tableView endUpdates];
        
    [self.chatTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.msgs.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    
}

/**
 *点击bubble 播放语音
 */
#pragma -mark 点击bubble
- (void)msgCellTappedContent:(ChatCell *)msgCell{
    NSIndexPath *indexPath = [self.chatTable indexPathForCell:msgCell];
    
    PersonMessage *msg = self.msgs[indexPath.row];
    
    ReceiverVoiceCell *cell = (ReceiverVoiceCell *)msgCell;
    NSArray<ReceiverVoiceCell *>*cells = [self.chatTable visibleCells];
    for (ReceiverVoiceCell *cell in cells) {
        if (cell.msg.messageBodyType == eMessageBodyType_Voice) {
            [cell sendVoiceMesState:FNVoiceMessageStateNormal];
        }
    }
    cell.voice.animationRepeatCount = [msg.voiceMessage.durational intValue];
    //播放动画
    [cell.voice startAnimating];
    //播放声音
    [[FNAVAudioPlayer sharePlayer] playAudioWithvoiceData:[NSData dataWithBase64EncodedString:msg.voiceMessage.fileData] atIndex:indexPath.row];
    
    //设为已读
    if ([msgCell isKindOfClass:[ReceiverVoiceCell class]]) {
        [cell updateIsRead:YES];//UI
        [[SqlManager shareInstance]clearMsgOfSingleWithmsg_id:msg.msgId];//数据库
        msg.voiceMessage.isRead = @"1";
        [self.msgs replaceObjectAtIndex:indexPath.row withObject:msg];
    }
    
}
#pragma mark -FNMsgCellDelegate
- (void)msgCellTappedBlank:(ChatCell *)msgCell{
    [self.chatBar endInputing];
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.msgs.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PersonMessage *pMsg = self.msgs[indexPath.row];
    ChatCell *cell = [self getCellWithMsg:pMsg];
    cell.index = indexPath.row;
    cell.delegate = self;
    return cell;
}
#pragma -mark  获取不同的cell
- (ChatCell *)getCellWithMsg:(PersonMessage *)msg{
    if (msg.messageBodyType == eMessageBodyType_Text) {
        if ([NexfiUtil isMeSend:msg]) {
            SenderTextCell *cell = [[[NSBundle mainBundle]loadNibNamed:@"SenderTextCell" owner:nil options:nil] objectAtIndex:0];
            cell.msg = msg;
            cell.avatar.image = [UIImage imageNamed:[[UserManager shareManager]getUser].userAvatar];
            return (ChatCell *)cell;
        }else{
            TextCell *cell = [[[NSBundle mainBundle]loadNibNamed:@"TextCell" owner:nil options:nil] objectAtIndex:0];
            cell.to_user = self.to_user;
            cell.msg = msg;
            cell.avatar.image = [UIImage imageNamed:self.to_user.userAvatar];
            return (ChatCell *)cell;
        }
    }else if (msg.messageBodyType == eMessageBodyType_Image){
        if ([NexfiUtil isMeSend:msg]) {
            SenderAvatarCell *cell = [[[NSBundle mainBundle]loadNibNamed:@"SenderAvatarCell" owner:nil options:nil] objectAtIndex:0];
            cell.msg = msg;
            cell.avatar.image = [UIImage imageNamed:[[UserManager shareManager]getUser].userAvatar];
            return (ChatCell *)cell;
        }else{
            ReceiverAvatarCell *cell = [[[NSBundle mainBundle]loadNibNamed:@"ReceiverAvatarCell" owner:nil options:nil] objectAtIndex:0];
            cell.to_user = self.to_user;
            cell.msg = msg;
            cell.avatar.image = [UIImage imageNamed:self.to_user.userAvatar];
            return (ChatCell *)cell;
        }
    }else if (msg.messageBodyType == eMessageBodyType_Voice){
        if ([NexfiUtil isMeSend:msg]) {
            SenderVoiceCell *cell = [[[NSBundle mainBundle]loadNibNamed:@"SenderVoiceCell" owner:nil options:nil] objectAtIndex:0];
            cell.msg = msg;
            cell.avatar.image = [UIImage imageNamed:[[UserManager shareManager]getUser].userAvatar];
            return (ChatCell *)cell;
        }else{
            ReceiverVoiceCell *cell = [[[NSBundle mainBundle]loadNibNamed:@"ReceiverVoiceCell" owner:nil options:nil] objectAtIndex:0];
            cell.to_user = self.to_user;
            cell.msg = msg;
            cell.avatar.image = [UIImage imageNamed:self.to_user.userAvatar];
            return (ChatCell *)cell;
        }
    }
    return nil;
}
#pragma -mark 获取接收到的数据
- (void)refreshGetData:(NSDictionary *)dic{
    NSDictionary *text = dic[@"text"];

    PersonMessage *msg = [PersonMessage mj_objectWithKeyValues:text];

    //保存聊天记录
    [[SqlManager shareInstance]add_chatUser:[[UserManager shareManager]getUser] WithTo_user:self.to_user WithMsg:msg];
    //增加未读消息数量
    [[SqlManager shareInstance]addUnreadNum:[[UserManager shareManager]getUser].userId];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showTableMsg:msg];
    });
    
}
#pragma -mark 获取发送的数据
- (id<UDSource>)frameData:(MessageBodyType)type withSendData:(id)data{
    
    UDLazySource *result = [[UDLazySource alloc]initWithQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0) block:^NSData * _Nullable{
        
        
        
        NSData *newData;
        PersonMessage *msg = [[PersonMessage alloc]init];
        NSString *deviceUDID = [NexfiUtil uuid];
        
        switch (type) {
            case eMessageBodyType_Text:
            {
                TextMessage *textMessage = [[TextMessage alloc]init];
                textMessage.fileData = data;
                textMessage.isRead = @"1";
                msg.textMessage = textMessage;
                
                msg.timeStamp = [self getDateWithFormatter:@"yyyy-MM-dd HH:mm:ss"];
                msg.receiver = self.to_user.userId;
                msg.messageBodyType = eMessageBodyType_Text;
                msg.msgId = deviceUDID;
                msg.userMessage = [[UserManager shareManager]getUser];
                break;
            }
            case eMessageBodyType_Image:
            {
                
                //缓存到本地图片
                NSData *picData = [NexfiUtil image2Data:data];
//                NSString *fileName = [[NFChatCacheFileUtil sharedInstance]chatCachePathWithFriendId:[[UserManager shareManager]getUser].userId andType:2];
//                NSString *relativePath = [NSString stringWithFormat:@"voice/chatLog/%@/image/",[[UserManager shareManager]getUser].userId];
//                NSString *imgPath = [relativePath stringByAppendingString:[NSString stringWithFormat:@"image_%@.jpg",[self getDateWithFormatter:@"yyyyMMddHHmmss"]]];
//                
//                
//                
//                NSString *fullPath = [fileName stringByAppendingPathComponent:[NSString stringWithFormat:@"image_%@.jpg",[self getDateWithFormatter:@"yyyyMMddHHmmss"]]];
//                [picData writeToFile:fullPath atomically:YES];
//                
                FileMessage *fileMessage = [[FileMessage alloc]init];
                fileMessage.fileData = [picData base64Encoding];
                fileMessage.isRead = @"1";
                msg.fileMessage = fileMessage;
                
                msg.messageBodyType = eMessageBodyType_Image;
                msg.timeStamp = [self getDateWithFormatter:@"yyyy-MM-dd HH:mm:ss"];
                msg.receiver = self.to_user.userId;
                msg.msgId = deviceUDID;
                msg.userMessage = [[UserManager shareManager]getUser];
                
                
                
                break;
            }
            case eMessageBodyType_File:
            {
                
                
                break;
            }
            case eMessageBodyType_Voice:
            {
                
                NSDictionary *voicePro = data;
                
                NSString *DoucmentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
                NSString *mp3Path = [DoucmentsPath stringByAppendingPathComponent:voicePro[@"voiceName"]];
                
                NSData *voiceData = [[NSData alloc]initWithContentsOfURL:[NSURL fileURLWithPath:mp3Path]];
                
                VoiceMessage *voiceMessage = [[VoiceMessage alloc]init];
                voiceMessage.isRead = @"0";
                voiceMessage.fileData = [voiceData base64Encoding];
                voiceMessage.durational = voicePro[@"voiceSec"];
                
                msg.voiceMessage = voiceMessage;
                
                msg.timeStamp = [self getDateWithFormatter:@"yyyy-MM-dd HH:mm:ss"];
                msg.messageBodyType = eMessageBodyType_Voice;
                msg.msgId = deviceUDID;
                msg.receiver = self.to_user.userId;
                msg.userMessage = [[UserManager shareManager]getUser];
                 
                
                
                break;
            }
            default:
                break;
        }
        
        msg.messageType = eMessageType_SingleChat;
        //        NSDictionary *msgDic = [NexfiUtil getObjectData:msg];
        
        newData = [NSJSONSerialization dataWithJSONObject:msg.mj_keyValues options:0 error:0];
        //刷新表
        if (self.sendOnce == YES) {
            self.sendOnce = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showTableMsg:msg];
            });
            
            //插入数据库
            
            [[SqlManager shareInstance]add_chatUser:[[UserManager shareManager]getUser] WithTo_user:self.to_user WithMsg:msg];
        }
        
        
        return newData;
        
    }];
    
    return result;
}
#pragma -mark 获取当前时间
-(NSString *)getDateWithFormatter:(NSString *)formatter
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *strDate = [dateFormatter stringFromDate:[NSDate date]];
    NSLog(@"%@", strDate);
    return strDate;
}
- (XMChatBar *)chatBar {
    if (!_chatBar) {
        _chatBar = [[XMChatBar alloc] initWithFrame:CGRectMake(0, SCREEN_SIZE.height - kMinHeight - 64, SCREEN_SIZE.width, kMinHeight)];
        [_chatBar setSuperViewHeight:SCREEN_SIZE.height - 64];
        _chatBar.delegate = self;
    }
    return _chatBar;
}
#pragma mark -NodeDelegate
- (void)singleChatSendFailWithInfo:(NSString *)failMsg{
//    [HudTool showErrorHudWithText:failMsg inView:self.view duration:2];
}
- (void)AllUserChatSendFailWithInfo:(NSString *)failMsg{
    
}
#pragma mark - XMChatBarDelegate

- (void)chatBar:(XMChatBar *)chatBar sendMessage:(NSString *)message{
    
    self.sendOnce = YES;
    //    [self broadcastFrame:[self frameData:eMessageBodyType_Text withSendData:message]];
    [[UnderdarkUtil share].node singleChatWithFrame:[self frameData:eMessageBodyType_Text withSendData:message] WithUserNodeId:self.to_user.nodeId];

}

- (void)chatBar:(XMChatBar *)chatBar sendVoice:(NSString *)voiceFileName seconds:(NSTimeInterval)seconds{
    
    self.sendOnce = YES;
    NSDictionary *voicePro = @{@"voiceName":voiceFileName,@"voiceSec":@((int)seconds)};
    [[UnderdarkUtil share].node singleChatWithFrame:[self frameData:eMessageBodyType_Voice withSendData:voicePro] WithUserNodeId:self.to_user.nodeId];
    
}

- (void)chatBar:(XMChatBar *)chatBar sendPictures:(NSArray *)pictures{
    
    self.sendOnce = YES;
    //    [self broadcastFrame:[self frameData:eMessageBodyType_Image withSendData:[pictures objectAtIndex:0]]];
    [[UnderdarkUtil share].node singleChatWithFrame:[self frameData:eMessageBodyType_Image withSendData:[pictures objectAtIndex:0]] WithUserNodeId:self.to_user.nodeId];
    
}

- (void)chatBar:(XMChatBar *)chatBar sendLocation:(CLLocationCoordinate2D)locationCoordinate locationText:(NSString *)locationText{
    //    NSMutableDictionary *locationMessageDict = [NSMutableDictionary dictionary];
    //    locationMessageDict[kXMNMessageConfigurationTypeKey] = @(XMNMessageTypeLocation);
    //    locationMessageDict[kXMNMessageConfigurationOwnerKey] = @(XMNMessageOwnerSelf);
    //    locationMessageDict[kXMNMessageConfigurationGroupKey] = @(self.messageChatType);
    //    locationMessageDict[kXMNMessageConfigurationNicknameKey] = kSelfName;
    //    locationMessageDict[kXMNMessageConfigurationAvatarKey] = kSelfThumb;
    //    locationMessageDict[kXMNMessageConfigurationLocationKey]=locationText;
    //    [self addMessage:locationMessageDict];
    
}
- (void)chatBarFrameDidChange:(XMChatBar *)chatBar frame:(CGRect)frame{
    if (frame.origin.y == self.chatTable.frame.size.height) {
        return;
    }
    [UIView animateWithDuration:.3f animations:^{
        [self.chatTable setFrame:CGRectMake(0, 0, self.view.frame.size.width, frame.origin.y)];
    } completion:nil];
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
