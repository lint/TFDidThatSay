
/* -- Comment Interfaces -- */

@interface Comment
@property(strong, nonatomic) NSString *author;
@property(strong, nonatomic) NSString *content;
@property(strong, nonatomic) NSString *identifier;
@property(strong, nonatomic) id markdownString;
@end

@interface CommentCell : UIView
@property(strong, nonatomic) id comment;
@property(strong, nonatomic) id commentContentView;
@property(strong, nonatomic) id authorButton;
@property(assign, nonatomic) BOOL isCollapsed;
@property(assign, nonatomic) BOOL commentDidChange;
- (void)reloadContents;

//custom elements
@property(strong, nonatomic) UIButton *undeleteButton;
@end

/* -- Post Interfaces -- */

@interface Post
@property(strong, nonatomic) NSString *author;
@property(strong, nonatomic) NSString *content;
@property(strong, nonatomic) NSString *identifier;
@property(strong, nonatomic) id markdownString;
@property(strong, nonatomic) NSNumber *isSelfText;
@end

@interface PostDetailEmbeddedViewController
@property(strong, nonatomic) UITableView *tableView;
@property(strong, nonatomic) NSArray *content;

//custom elements
@property(strong, nonatomic) id selfTextView;
@property(strong, nonatomic) id metadataView;
@property(strong, nonatomic) id post;
@end

@interface PostToolbarView : UIView
@property(strong, nonatomic) id post;

//custom elements
@property(strong, nonatomic) UIButton *undeleteButton;
@end

@interface PostSelfTextPartCell
- (id)_viewControllerForAncestor;
@end

@interface PostMetadataView
@property(strong, nonatomic) id post;
@end
