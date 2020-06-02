
/* -- Comment Interfaces -- */

@interface RKComment
@property(assign,nonatomic) NSString* author;
@property(assign,nonatomic) NSString* parentID;
@property(assign,nonatomic) NSString* body;
@property(assign,nonatomic) NSString* fullName;

- (BOOL)isSaved;
@end

@interface NRTCommentsManager
@property(assign,nonatomic) NSMutableArray* comments;

- (void)updateComment:(id)arg1 fromEdited:(id)arg2;
@end

/* -- Post Interfaces -- */

@interface RKLink
@property(assign,nonatomic) NSString* author;
@property(assign,nonatomic) NSString* selfText;
@property(assign,nonatomic) NSString* fullName;
@end

@interface NRTLinkTitleCell
- (void)configureCellForLink:(id)arg1;
@end

@interface NRTLinkTextCell
@property(assign,nonatomic) id bodyLabel;

- (void)configureCellForText:(id)arg1 links:(id)arg2;
@end

/* -- Other Interfaces -- */

@interface NRTAuthManager
@property(assign,nonatomic) NSString* currentUsername;

+ (id)sharedManager;
@end

@interface NRTMarkdownManager
+ (id)attributedStringFromMarkdown:(id)arg1 type:(id)arg2;
@end

@interface NRTAttributedLabel
@property(assign,nonatomic) id attributedText;
@end

@interface NRTMediaViewController : UIViewController
@end

@interface NRTLinkViewController : UIViewController
@property(assign,nonatomic) id comment;
@property(assign,nonatomic) id commentsManager;
@property(assign,nonatomic) id linkTextOffscreenCell;
@property(assign,nonatomic) id linkTitleOffscreenCell;
@property(assign,nonatomic) id link;
@property(assign,nonatomic) id linkText;
@property(assign,nonatomic) id tableView;

- (void)_handleActionSheetCopyCommentText:(id)arg1;
- (void)_handleActionSheetDeleteComment:(id)arg1;
- (void)_handleActionSheetDeletePost;
- (void)_handleActionSheetEditComment:(id)arg1;
- (void)_handleActionSheetEditPost;
- (void)_handleActionSheetOpenChrome;
- (void)_handleActionSheetOpenSafari;
- (void)_handleActionSheetPrivateMessage:(id)arg1;
- (void)_handleActionSheetRefreshComments;
- (void)_handleActionSheetRefreshPost;
- (void)_handleActionSheetReportComment:(id)arg1;
- (void)_handleActionSheetReportPost;
- (void)_handleActionSheetSaveComment:(id)arg1 index:(NSUInteger)arg2;
- (void)_handleActionSheetShareComment:(id)arg1;
- (void)_handleActionSheetShareLink;
- (void)_handleActionSheetSharePost;
- (void)_handleActionSheetSortComments;
- (void)_handleActionSheetUnsaveComment:(id)arg1 index:(NSUInteger)arg2;
- (void)_handleActionSheetViewParent:(id)arg1;
- (void)_handleActionSheetViewProfile:(id)arg1;

//custom elements
- (void) handleUndeleteAction:(id)arg1;
- (void) handleUndeletePostAction;
- (void) mainThreadTest:(id)arg1;
@end

@interface NRTMediaTableViewDataSource
@property(assign,nonatomic) id commentsManager;
@property(assign,nonatomic) id parentController;

- (void)_handleActionSheetCopyCommentText:(id)arg1;
- (void)_handleActionSheetDeleteComment:(id)arg1;
- (void)_handleActionSheetDeletePost;
- (void)_handleActionSheetEditComment:(id)arg1;
- (void)_handleActionSheetEditPost;
- (void)_handleActionSheetOpenChrome;
- (void)_handleActionSheetOpenSafari;
- (void)_handleActionSheetPrivateMessage:(id)arg1;
- (void)_handleActionSheetRefreshComments;
- (void)_handleActionSheetRefreshPost;
- (void)_handleActionSheetReportComment:(id)arg1;
- (void)_handleActionSheetReportPost;
- (void)_handleActionSheetSaveComment:(id)arg1 index:(NSUInteger)arg2;
- (void)_handleActionSheetShareComment:(id)arg1;
- (void)_handleActionSheetShareLink;
- (void)_handleActionSheetSharePost;
- (void)_handleActionSheetSortComments;
- (void)_handleActionSheetUnsaveComment:(id)arg1 index:(NSUInteger)arg2;
- (void)_handleActionSheetViewParent:(id)arg1;
- (void)_handleActionSheetViewProfile:(id)arg1;

//custom elements
- (void)handleUndeleteCommentAction:(id)comment;
@end
