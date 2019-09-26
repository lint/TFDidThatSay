

/* -- Comment Interfaces -- */


@interface Comment 
@property(assign,nonatomic) id bodyRichTextAttributed;
@property(assign,nonatomic) id pk;
@end

@interface CommentTreeNode
@property(assign,nonatomic) id comment;

//custom elements
@property(assign,nonatomic) id commentTreeHeaderNode;
@property(assign,nonatomic) id commentTreeCommandBarNode;
@property(assign,nonatomic) BOOL isLoadingArchivedComment;
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
@end

@interface FeedPostDetailDelegator
@property(assign,nonatomic) id viewController;
@end


/* -- Other Interfaces -- */


@interface RichTextDisplayNode
@property(assign,nonatomic) id attributedText;
@end

@interface RUIActionSheetItem : NSObject
@property(assign,nonatomic) id leftIconImage;
-(id) initWithLeftIconImage:(id) arg1 text:(id) arg2 identifier:(id) arg3 context:(id) arg4;
@end

@interface NSAttributedStringMarkdownParser
+(id) currentConfig;
+(id) attributedStringUsingCurrentConfig:(id) arg1;
-(id) attributedStringFromMarkdownString:(id) arg1;
-(id) initWithConfig:(id) arg1;
@end


/* -- ActivityIndicator Interfaces -- */


@interface AccountManager
@property(assign,nonatomic) id defaults;
+(id) sharedManager;
@end

@interface _ASCollectionViewCell
@property(assign,nonatomic) id node;
@end

@interface CellDisplayNodeWrapper
@property(assign,nonatomic) id contentNode; 
@end



