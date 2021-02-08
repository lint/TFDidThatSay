
#import <UIKit/UIKit.h>

/* -- Comment Interfaces -- */

@interface RKComment
@property(strong, nonatomic) NSString *body;
@property(strong, nonatomic) NSString *bodyHTML;
@property(strong, nonatomic) NSString *author;
@property(strong, nonatomic) NSString *fullName;
@end

@interface RDKComment
@property(strong, nonatomic) NSString *body;
@property(strong, nonatomic) NSString *bodyHTML;
@property(strong, nonatomic) NSString *author;
@property(strong, nonatomic) NSString *fullName;
@end

@interface CommentCellNode
@property(strong, nonatomic) id view;
@property(strong, nonatomic) id actionDelegate;
- (BOOL)isSelected;
- (void)_layoutSublayouts;
- (void)didLoad;
- (void)calculatedLayoutDidChange;

//custom elements
@property(strong,nonatomic) UIButton *undeleteButton;
- (void)undeleteCellWasSelected;
@end

@interface CommentSectionController : NSObject

//custom elements
@property(strong, nonatomic) id commentCellNode;
@end

/* -- Post Interfaces -- */

@interface RKLink
@property(strong, nonatomic) NSString *selfText;
@property(strong, nonatomic) NSString *author;
@property(strong, nonatomic) NSString *fullName;
- (BOOL)isSelfPost;

//custom elements
@property(strong, nonatomic) NSString *undeleteAuthor;
@end

@interface RDKLink
@property(strong, nonatomic) NSString *selfText;
@property(strong, nonatomic) NSString *author;
@property(strong, nonatomic) NSString *fullName;
- (BOOL)isSelfPost;

//custom elements
@property(strong, nonatomic) NSString *undeleteAuthor;
@end

@interface CommentsHeaderCellNode
@property(strong, nonatomic) id undeleteButton;
@property(strong, nonatomic) id closestViewController;
@end

@interface CommentsViewController

//custom elements
@property(strong, nonatomic) id headerCellNode;
- (void)undeleteCellWasSelected;
@end

@interface CommentsHeaderSectionController : NSObject
@end

/* -- Other Interfaces -- */

@interface MarkdownRenderer
+ (id)attributedStringFromMarkdown:(id)arg1 withAttributes:(id)arg2;
@end

@interface ActionController
- (id)tableView:(id)arg1 cellForRowAtIndexPath:(NSIndexPath *)arg2;
- (NSInteger)tableView:(id)arg1 numberOfRowsInSection:(NSInteger)arg2;
@end

@interface UIImage (ios13)
+ (id)systemImageNamed:(NSString *)arg1;
@end

@interface IconActionTableViewCell : UITableViewCell
@end

/* -- ASyncDisplayKit Interfaces -- */

@interface _ASDisplayView : UIView
@end

@interface ASImageNode
@property(strong, nonatomic) id image;
@property(assign, nonatomic) CGRect frame;
@property(strong, nonatomic) id view;
- (CGRect)_frameInWindow;
@end

@interface ASTextNode
@property(assign, nonatomic) CGRect frame;
@property(strong, nonatomic) NSAttributedString *attributedString;
@property(strong, nonatomic) NSAttributedString *attributedText;
@end

@interface ApolloButtonNode
@property(strong, nonatomic) ASTextNode *titleNode;
- (void) setAttributedTitle:(id)arg1 forState:(NSInteger)arg2;
- (id) attributedTitleForState:(NSInteger)arg1;
@end
