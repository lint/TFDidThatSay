
#import <UIKit/UIKit.h>

/* -- Comment Interfaces -- */

@interface RComment
@property(strong, nonatomic) NSString *subreddit;
@property(strong, nonatomic) NSString *author;
@property(strong, nonatomic) NSString *body;
@property(strong, nonatomic) NSString *id;
@end

@interface CommentDepthCell
- (void)showMenu:(id)arg1;

//custom elements
- (void)addUndeleteButtonToMenu;
@end

/* -- Post Interfaces -- */

@interface RSubmission
@property(assign, nonatomic) BOOL isSelf;
@end

@interface CommentViewController : UIViewController
- (void)refresh:(id)arg1;

//custom elements
@property(strong, nonatomic) UIButton *undeleteButton;
- (void)addUndeleteButtonToToolbar;
- (BOOL)shouldAddUndeleteButtonToToolbar;
@end

/* -- Utility Interfaces -- */

@interface UIColor ()
+ (UIColor *)colorWithHex:(NSString *)arg1;
- (NSString *)hexString;
@end

@interface NSAttributedString ()
- (void)yy_setTextHighlightRange:(NSRange)range color:(UIColor *)color backgroundColor:(UIColor *)backgroundColor userInfo:(NSDictionary *)userInfo;
@end

@interface ColorUtil : NSObject
+ (UIColor *)accentColorForSub:(NSString *)arg1;
+ (UIColor *)fontColorForTheme:(NSString *)arg1;
+ (UIColor *)backgroundColorForTheme:(NSString *)arg1;
@end

@interface DTHTMLAttributedStringBuilder
- (id) initWithHTML:(NSData *)data options:(NSDictionary *)options documentAttributes:(NSDictionary * __autoreleasing*)docAttributes;
- (NSAttributedString *)generatedAttributedString;
@end

@interface FontGenerator : NSObject
+ (UIFont *)fontOfSize:(CGFloat)arg1 submission:(BOOL)arg2 willOffset:(BOOL)arg3;
+ (UIFont *)boldFontOfSize:(CGFloat)arg1 submission:(BOOL)arg2 willOffset:(BOOL)arg3;
+ (UIFont *)italicFontOfSize:(CGFloat)arg1 submission:(BOOL)arg2 willOffset:(BOOL)arg3;
@end
