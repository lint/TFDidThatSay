
/* -- Comment Interfaces -- */

@interface RKComment
@property(assign,nonatomic) NSString *body;
@property(assign,nonatomic) NSString *bodyHTML;
@property(assign,nonatomic) NSString *author;
@property(assign,nonatomic) NSString *fullName;
@end

@interface RDKComment
@property(assign,nonatomic) NSString *body;
@property(assign,nonatomic) NSString *bodyHTML;
@property(assign,nonatomic) NSString *author;
@property(assign,nonatomic) NSString *fullName;
@end

@interface CommentCellNode
@property(assign,nonatomic)id view;
- (BOOL)isSelected;
- (void)_layoutSublayouts;
- (void)didLoad;
- (void)calculatedLayoutDidChange;

//custom elements
@property(strong,nonatomic) UIButton *undeleteButton;
- (void)undeleteCellWasSelected;
@end

/* -- Post Interfaces -- */

@interface RKLink
@property(assign,nonatomic) NSString *selfText;
@property(assign,nonatomic) NSString *author;
@property(assign,nonatomic) NSString *fullName;
- (BOOL)isSelfPost;

//custom elements
@property(strong, nonatomic) NSString *undeleteAuthor;
@end

@interface RDKLink
@property(assign,nonatomic) NSString *selfText;
@property(assign,nonatomic) NSString *author;
@property(assign,nonatomic) NSString *fullName;
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
@property(assign,nonatomic)id image;
@property(assign,nonatomic) CGRect frame;
@property(assign,nonatomic) id view;
- (CGRect)_frameInWindow;
@end

@interface ASTextNode
@property(assign,nonatomic) CGRect frame;
@property(assign,nonatomic) NSAttributedString *attributedString;
@property(assign,nonatomic) NSAttributedString *attributedText;
@end

@interface ApolloButtonNode
@property(assign,nonatomic) ASTextNode *titleNode;
- (void) setAttributedTitle:(id)arg1 forState:(NSInteger)arg2;
- (id) attributedTitleForState:(NSInteger)arg1;
@end
