
/* -- Voteable Interfaces -- */

@interface VoteableElement : NSObject
@property(strong, nonatomic) NSString *ident;
@property(strong, nonatomic) NSString *author;
@end

@interface Comment : VoteableElement
@property(strong, nonatomic) NSString *body;
@property(strong, nonatomic) NSString *bodyHTML;
@end

@interface Post : VoteableElement
@property(strong, nonatomic) NSString *selftext;
@property(strong, nonatomic) NSString *selftextHtml;
@property(assign, nonatomic) BOOL selfPost;
@end

/* -- UI Interfaces -- */

@interface NCommentCell
@property(strong, nonatomic) Comment *comment;
@end

@interface NCommentPostHeaderCell
@property(strong, nonatomic) Post *post;
@property(strong, nonatomic) id node;
@end

@interface CommentsViewController
- (void)respondToStyleChange;
@end

@interface CommentPostHeaderNode
@property(strong, nonatomic) Comment *comment;
@property(strong, nonatomic) Post *post;
@end

@interface CommentNode
@property(strong, nonatomic) Comment *comment;
@property(strong, nonatomic) Post *post;
@end

@interface CommentOptionsDrawerView
@property(strong, nonatomic) NSMutableArray *buttons;
@property(assign, nonatomic) BOOL isPostHeader;
@property(strong, nonatomic) id delegate;
@property(strong, nonatomic) id node;
- (void)addButton:(id)arg1;
@end

/* -- Other Interfaces -- */

@interface MarkupEngine
+ (id)markDownHTML:(id)arg1 forSubreddit:(id)arg2;
@end

@interface Resources
+ (BOOL)isNight;
@end
