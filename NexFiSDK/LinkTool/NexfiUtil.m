//
//  NexfiUtil.m
//  Nexfi
//
//  Created by fyc on 16/4/5.
//  Copyright © 2016年 FuYaChen. All rights reserved.
//

#import "NexfiUtil.h"
@implementation NexfiUtil
static NexfiUtil *_util;
+ (instancetype)shareUtil{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _util = [[NexfiUtil alloc]init];
    });
    return _util;
}
/**
 *@日期格式转换函数
 *date所要转化的日期 输入date格式为"yyyyMMddHHmmss"
 *type转化的格式  1:输出@"yyyy-MM-dd HH:mm:ss"
 *              2:输出@"yyyy-MM-dd"
 *              3:距离1970的时间戳输入date为时间戳 输出@"yyyy-MM-dd"
 *              4:输出@"yyyy年MM月dd日"
 *              5:输出@"yyyy-MM-dd HH:mm"
 **/
-(NSString *)switchDate:(NSString *)date returnType:(NSUInteger)type{
    if(date.length ==0){
        return @"";
    }
    NSString* string = date;
    NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
    [inputFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] ];
    [inputFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSDate* inputDate = [inputFormatter dateFromString:string];
    if (type == 3) {//时间戳转换成具体时间
        if (date.length>10)
            date = [date substringWithRange:NSMakeRange(0, 11)];
//            date = [date substringFromIndex:0 toIndex:10];
        inputDate = [NSDate dateWithTimeIntervalSince1970:[date longLongValue]];
    }
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    if (type == 1) {
        [outputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    }
    else if(type == 2){
        [outputFormatter setDateFormat:@"yyyy-MM-dd"];
    }
    else if(type == 3){
        [outputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    }
    else if(type == 4){
        [outputFormatter setDateFormat:@"yyyy年MM月dd日"];
    }
    else if(type == 5){
        [outputFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    }
    NSString *str = [outputFormatter stringFromDate:inputDate];
    return str;
}
+(NSDictionary*)getObjectData:(id)obj
{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    
    unsigned int propsCount;

    objc_property_t *props = class_copyPropertyList([obj class], &propsCount);
    
    for(int i = 0;i < propsCount; i++)
    {
        
        objc_property_t prop = props[i];
        
        NSString *propName = [NSString stringWithUTF8String:property_getName(prop)];
        
        id value = [obj valueForKey:propName];
        
        if(value == nil)
        {
            value = [NSNull null];
        }
        else
        {
            value = [self getObjectInternal:value];
        }
        [dic setObject:value forKey:propName];
    }
    return dic;
}
+(void)print:(id)obj
{
    NSLog(@"%@",[self getObjectData:obj]);
}
+(NSData*)getJSON:(id)obj options:(NSJSONWritingOptions)options error:(NSError**)error
{
    return [NSJSONSerialization dataWithJSONObject:[self getObjectData:obj] options:options error:error];
}
+(id)getObjectInternal:(id)obj
{
    if([obj isKindOfClass:[NSString class]]||[obj isKindOfClass:[NSNumber class]]|| [obj isKindOfClass:[NSNull class]]||[obj isKindOfClass:[NSData class]]||[obj isKindOfClass:[UIImage class]]||[obj isKindOfClass:[NSObject class]])
    {
        return obj;
    }
    if([obj isKindOfClass:[NSArray class]])
    {
        NSArray *objarr = obj;
        NSMutableArray *arr = [NSMutableArray arrayWithCapacity:objarr.count];
        for(int i = 0;i < objarr.count; i++)
        {
            [arr setObject:[self getObjectInternal:[objarr objectAtIndex:i]] atIndexedSubscript:i];
        }
        return arr;
    }
    if([obj isKindOfClass:[NSDictionary class]])
    {
        
        NSDictionary *objdic = obj;
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:[objdic count]];
        for(NSString *key in objdic.allKeys)
        {
            [dic setObject:[self getObjectInternal:[objdic objectForKey:key]] forKey:key];
        }
        return dic;
    }
    return [self getObjectData:obj];
    
}
+ (NSString*) uuid {
    
    CFUUIDRef puuid = CFUUIDCreate( nil );
    CFStringRef uuidString = CFUUIDCreateString( nil, puuid );
    NSString * result = (NSString *)CFBridgingRelease(CFStringCreateCopy( NULL, uuidString));
    CFRelease(puuid);
    CFRelease(uuidString);

//        return [result autorelease];
    return result;
}
- (NSString *)pathForTemporaryFileWithPrefix:(NSString *)prefix

{
    
    NSString * result;
    
    CFUUIDRef uuid;
    
    CFStringRef uuidStr;
    
    uuid = CFUUIDCreate(NULL);
    
    assert(uuid != NULL);
    
    uuidStr = CFUUIDCreateString(NULL, uuid);
    
    assert(uuidStr != NULL);
    
    result = [NSTemporaryDirectory()stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%@", prefix, uuidStr]];
    
    assert(result != nil);
    
    CFRelease(uuidStr);
    
    CFRelease(uuid);
    
    return result;
    
}
+(BOOL)isMeSend:(Message *)msg{
    
    return [[msg userMessage].userId isEqualToString:[[UserManager shareManager]getUser].userId];
    
}
+(NSData *) image2Data:(UIImage *)image{
    
    image = [self scaleImage:image toWidth:SCREEN_SIZE.width toHeight:SCREEN_SIZE.height - 20];
    
    NSData *pictureData = UIImageJPEGRepresentation(image, 1);
    CGFloat kbSize = pictureData.length;
    CGFloat scale = 1.0;
    if (kbSize > 100) {
        scale  = 100/kbSize;
    }
    NSData *newData = UIImageJPEGRepresentation(image, scale);
    UIImage *newImage = [UIImage imageWithData:newData];
    
    NSData* newPictureData = UIImageJPEGRepresentation(newImage,0.5);
    return newPictureData;
}
+(UIImage *)scaleImage:(UIImage *)image toWidth:(int)toWidth toHeight:(int)toHeight{
    int width=0;
    int height=0;
    int x=0;
    int y=0;
    
    if (image.size.width<toWidth){
        width = toWidth;
        height = image.size.height*(toWidth/image.size.width);
        y = (height - toHeight)/2;
    }else if (image.size.height<toHeight){
        height = toHeight;
        width = image.size.width*(toHeight/image.size.height);
        x = (width - toWidth)/2;
    }else if (image.size.width>toWidth){
        width = toWidth;
        height = image.size.height*(toWidth/image.size.width);
        y = (height - toHeight)/2;
    }else if (image.size.height>toHeight){
        height = toHeight;
        width = image.size.width*(toHeight/image.size.height);
        x = (width - toWidth)/2;
    }else{
        height = toHeight;
        width = toWidth;
    }
    
    CGSize size = CGSizeMake(width, height);
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGSize subImageSize = CGSizeMake(toWidth, toHeight);
    CGRect subImageRect = CGRectMake(x, y, toWidth, toHeight);
    CGImageRef imageRef = image.CGImage;
    CGImageRef subImageRef = CGImageCreateWithImageInRect(imageRef, subImageRect);
    UIGraphicsBeginImageContext(subImageSize);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, subImageRect, subImageRef);
    UIImage* subImage = [UIImage imageWithCGImage:subImageRef];
    CGImageRelease(subImageRef);
    UIGraphicsEndImageContext();
    return subImage;
}

- (void)toUpdateUserInfo{
//    for (int i = 0; i < [UnderdarkUtil share].node.links.count; i++) {
//        id<UDLink>myLink = [[UnderdarkUtil share].node.links objectAtIndex:i];
//        [myLink sendData:[[UnderdarkUtil share].node sendMsgWithMessageType:6]];
//    }
}
@end
