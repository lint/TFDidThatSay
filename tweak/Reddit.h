
/* ---- Reddit v4 ---- */


/* -- Comment Interfaces -- */

@interface CommentTreeNode
@property(assign,nonatomic) id comment;

//custom elements
@property(assign,nonatomic) id commentTreeHeaderNode;
@property(assign,nonatomic) id commentTreeCommandBarNode;
@end

@interface CommentTreeDisplayNode
@property(assign,nonatomic) id commentNode;
@end

@interface CommentTreeHeaderNode
@property(assign,nonatomic) id commentTreeNode;
-(void) updateContentViewsForData:(id)arg1;
@end

@interface CommentTreeCommandBarNode
@property(assign,nonatomic) id commentTreeNode;
@property(assign,nonatomic) id delegate;
@property(assign,nonatomic) UIView* view;
@property(assign,nonatomic) id overflowButtonNode;
@property(assign,nonatomic) CGRect frame;

//custom elements
@property(assign,nonatomic) id activityIndicator;
@property(assign,nonatomic) id undeleteButton;
@end

@interface CommentActionSheetViewController : UIViewController
@property(assign,nonatomic) id comment;
@property(assign,nonatomic) id commentTreeNode;
-(id)animationControllerForDismissedController:(id) arg1;
@end

/* -- Post Interfaces -- */

@interface Post
@property(assign,nonatomic) id author;
@property(assign,nonatomic) BOOL isSelfPost;
@property(assign,nonatomic) id selfText;
@property(assign,nonatomic) id selfTextAttributed;
@property(assign,nonatomic) id selfPostRichTextAttributed;
@end

@interface PostDetailViewController
@property(assign,nonatomic) id selfTextNode;
-(void) configureSelfTextNode;

//custom elements
@property(assign,nonatomic) id feedPostTextWithThumbnailNode;
@property(assign,nonatomic) id feedPostDetailCellNode;
@end

@interface PostActionSheetViewController : UIViewController
@property(assign,nonatomic) id post;
@property(assign,nonatomic) id postActionSheetDelegate;
@end

@interface PostDetailNavigationItemHandler
@property(assign,nonatomic) id controller;
@property(assign,nonatomic) id presenter;
@end

@interface FeedPostDetailCellNode
@property(assign,nonatomic) id textNode;
@property(assign,nonatomic) id delegate;
@property(assign,nonatomic) id contentNode;
@end

@interface FeedPostDetailDelegator
@property(assign,nonatomic) id viewController;
@end

@interface FeedPostContentNode
-(void) configureSelfTextNode;
@end


/* -- Other Interfaces -- */


@interface RichTextDisplayNode
@property(assign,nonatomic) id attributedText;
@end

@interface RUIActionSheetItem : NSObject
@property(assign,nonatomic) id leftIconImage;
-(id) initWithLeftIconImage:(id) arg1 text:(id) arg2 identifier:(id) arg3 context:(id) arg4;
@end

@interface RUITheme
@property(assign,nonatomic) id bodyTextColor;
@end

@interface NSAttributedStringMarkdownParser
+(id) currentConfig;
+(id) attributedStringUsingCurrentConfig:(id) arg1;
-(id) attributedStringFromMarkdownString:(id) arg1;
-(id) initWithConfig:(id) arg1;
@end

@interface ThemeManager

// >= 4.45.0
@property(assign,nonatomic) id darkTheme;
@property(assign,nonatomic) id lightTheme;
-(id) initWithAppSettings:(id) arg1;

// < 4.45.0
@property(assign,nonatomic) id dayTheme;
@property(assign,nonatomic) id nightTheme;
-(id) initWithTraitCollection:(id) arg1 appSettings:(id) arg2;
@end

@interface AppSettings
+(id) sharedSettings;
@end

@interface AccountManager
@property(assign,nonatomic) id defaults;
+(id) sharedManager;
@end

/* ---- Reddit v3 ---- */


/* -- Comment Interfaces -- */

@interface CommentCell : UIView
-(id) delegate;
-(id) comment;
-(id) commentView;
@end

@interface CommentView
-(void) configureSubviews;
-(void) layoutSubviews;
-(id) commandView;
-(id) comment;
-(id) delegate;
@end

@interface CommentCommandView
@property (nonatomic, assign) id undeleteButton;
-(id)overflowButton;
-(id) comment;
-(id) delegate;
@end

@interface CommentsViewController
-(void) reloadCommentsWithNewCommentsHighlight:(BOOL) arg1 autoScroll:(BOOL) arg2 animated:(BOOL) arg3;
-(void)updateFloatingViews;
@end

/* -- Other Interfaces -- */

@interface MarkDownParser
+(id)attributedStringFromMarkdownString:(id)arg1;
@end



/* ---- Reddit v3 & v4 ---- */


@interface Comment
//v4 
@property(assign,nonatomic) id bodyRichTextAttributed;
@property(assign,nonatomic) id pk;

//v3
-(id)pkWithoutPrefix;
@end
