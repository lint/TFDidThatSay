/* ---- Reddit v3 & v4 ---- */

/* -- Comment Interfaces -- */

@interface Comment
//v4 
@property(strong,nonatomic) id pk;
@property(strong, nonatomic) NSString *bodyText;
@property(strong, nonatomic) NSString *author;
@property(strong, nonatomic) id bodyRichTextAttributed;
@property(strong, nonatomic) id bodyAttributedText;

//v3
-(id)pkWithoutPrefix;
@end

@interface CommentsViewController : NSObject
@property(strong,nonatomic) id postData;
-(void) reloadCommentsWithNewCommentsHighlight:(BOOL) arg1 autoScroll:(BOOL) arg2 animated:(BOOL) arg3;
-(void) reloadCommentsSection:(BOOL) arg1;
-(void) reloadPostSection:(BOOL) arg1;
-(void) feedPostViewDidUpdatePost:(id) arg1 shouldReloadFeed:(BOOL) arg2;
-(void) updateFloatingViews;
@end

@interface CommentActionSheetViewController : UIViewController
@property(strong,nonatomic) Comment *comment;
@property(strong,nonatomic) id commentTreeNode;
@property(strong,nonatomic) CommentsViewController *commentActionSheetDelegate;
-(id)animationControllerForDismissedController:(id) arg1;
@end


/* ---- Reddit v4 ---- */


/* -- Comment Interfaces -- */

@interface CommentTreeNode
@property(strong,nonatomic) Comment *comment;

//custom elements
@property(strong,nonatomic) id commentTreeHeaderNode;
@property(strong,nonatomic) id commentTreeCommandBarNode;
@end

@interface CommentTreeDisplayNode
@property(strong,nonatomic) id commentNode;
@end

@interface CommentTreeHeaderNode
@property(strong,nonatomic) id commentTreeNode;
-(void) updateContentViewsForData:(id)arg1;
@end

@interface CommentTreeCommandBarNode
@property(strong,nonatomic) id commentTreeNode;
@property(strong,nonatomic) id delegate;
@property(strong,nonatomic) UIView* view;
@property(strong,nonatomic) id overflowButtonNode;
@property(assign,nonatomic) CGRect frame;
@end

@interface CommentTreeHeaderView
@property(strong,nonatomic) id commentTreeNode;

-(void) updateContentViewsForData:(id) arg1;
@end

/* -- Post Interfaces -- */

@interface Post
@property(strong,nonatomic) NSString *author;
@property(strong,nonatomic) NSString *selfText;
@property(strong,nonatomic) id selfTextAttributed;
@property(strong,nonatomic) id selfPostRichTextAttributed;
@property(strong,nonatomic) id previewFeedPostTextString;
@property(assign,nonatomic) BOOL isSelfPost;
@property(strong,nonatomic) NSString *pk;
@end

@interface PostDetailViewController
@property(strong,nonatomic) id selfTextNode;
-(void) configureSelfTextNode;

//custom elements
@property(strong,nonatomic) id feedPostTextWithThumbnailNode;
@property(strong,nonatomic) id feedPostDetailCellNode;
@end

@interface PostActionSheetViewController : UIViewController
@property(strong,nonatomic) Post *post;
@property(strong,nonatomic) id postActionSheetDelegate;
@end

@interface PostDetailNavigationItemHandler
@property(strong,nonatomic) id controller;
@property(strong,nonatomic) id presenter;
@end

@interface FeedPostDetailCellNode
@property(strong,nonatomic) id textNode;
@property(strong,nonatomic) id delegate;
@property(strong,nonatomic) id contentNode;
@property(strong,nonatomic) id titleNode;
@end

@interface FeedPostTitleNode
@property(strong,nonatomic) id delegate;
-(void) configureNodes;
@end

@interface FeedPostDetailDelegator
@property(strong,nonatomic) id viewController;
@end

@interface FeedPostContentNode
-(void) configureSelfTextNode;
@end

/* -- Other Interfaces -- */

@interface RichTextDisplayNode
@property(strong,nonatomic) id attributedText;
@end

@interface RUIActionSheetItem : NSObject
@property(strong,nonatomic) id leftIconImage;
-(id) initWithLeftIconImage:(id) arg1 text:(id) arg2 identifier:(id) arg3 context:(id) arg4;
@end


@interface ActionSheetItem : NSObject
// <= 4.17
@property(strong,nonatomic) id leftIconImage;
-(id) initWithLeftIconImage:(id) arg1 text:(id) arg2 identifier:(id) arg3 context:(id) arg4;
@end

@interface RUITheme
@property(strong,nonatomic) id bodyTextColor;
@end

@interface NSAttributedStringMarkdownParser
+(id) currentConfig;
+(id) attributedStringUsingCurrentConfig:(id) arg1;
-(id) attributedStringFromMarkdownString:(id) arg1;
-(id) initWithConfig:(id) arg1;
@end

@interface ThemeManager

+(id) sharedManager;

// >= 4.45.0
@property(strong,nonatomic) id darkTheme;
@property(strong,nonatomic) id lightTheme;
-(id) initWithAppSettings:(id) arg1;

// < 4.45.0
@property(strong,nonatomic) id dayTheme;
@property(strong,nonatomic) id nightTheme;
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
@property (strong, nonatomic) id undeleteButton;
-(id)overflowButton;
-(id) comment;
-(id) delegate;
@end

/* -- Other Interfaces -- */

@interface MarkDownParser
+(id)attributedStringFromMarkdownString:(id)arg1;
@end
