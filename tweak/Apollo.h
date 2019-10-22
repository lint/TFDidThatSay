
/* -- Comment Interfaces -- */

@interface RKComment
@property(assign,nonatomic) NSString* body;
@property(assign,nonatomic) NSString* bodyHTML;
@property(assign,nonatomic) NSString* author;
@property(assign,nonatomic) NSString* fullName;
@end

@interface ApolloCommentCellNode
@property(assign,nonatomic)id view;
-(BOOL) isSelected;
-(void) _layoutSublayouts;
-(void) didLoad;
-(void) calculatedLayoutDidChange;

//custom element
@property(strong,nonatomic) id undeleteButton;

@end

/* -- Post Interfaces -- */

@interface RKLink
@property(assign,nonatomic) NSString* selfText;
@property(assign,nonatomic) NSString* author;
@property(assign,nonatomic) NSString* fullName;

-(BOOL) isSelfPost;
@end

@interface ApolloCommentsHeaderCellNode
@property(strong, nonatomic) id undeleteButton;
@end

/* -- Other Interfaces -- */

@interface MarkdownRenderer
+(id) attributedStringFromMarkdown:(id) arg1 withAttributes:(id) arg2;
@end

/* -- ASyncDisplayKit Interfaces -- */

@interface _ASDisplayView : UIView
@end

@interface ASImageNode
@property(assign,nonatomic)id image;
@property(assign,nonatomic) CGRect frame;
@property(assign,nonatomic) id view;
-(CGRect)_frameInWindow;
@end

@interface ASTextNode
@property(assign,nonatomic) CGRect frame;
@property(assign,nonatomic) id attributedString;
@property(assign,nonatomic) id attributedText;
@end

@interface ApolloApolloButtonNode
@property(assign,nonatomic) NSArray* subnodes;
@end



