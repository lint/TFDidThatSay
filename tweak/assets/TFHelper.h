
#import <UIKit/UIKit.h>

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface TFHelper : NSObject

+ (void)getUndeleteDataWithID:(NSString *)ident isComment:(BOOL)isComment timeout:(CGFloat)timeout extraData:(NSDictionary *)extra completionTarget:(id)target completionSelector:(SEL)sel;
+ (BOOL)shouldShowUndeleteButtonWithInfo:(NSString *)content isDeletedOnly:(BOOL)isDeletedOnly;

@end
