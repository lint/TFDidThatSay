
/* -- Votable Interfaces -- */

@interface BRVotable 
@property(strong, nonatomic) NSString *serverID;
@property(strong, nonatomic) NSAttributedString *attributedDescriptionString;
@property(assign, nonatomic) CGSize cellSize;
@end

@interface BRComment : BRVotable
@property(strong, nonatomic) NSString *author;
@property(strong, nonatomic) NSString *body;
@property(strong, nonatomic) NSString *body_html;
@end

@interface BRStory : BRVotable
@property(strong, nonatomic) NSString *author;
@property(strong, nonatomic) NSString *selftext;
@property(strong, nonatomic) NSString *selftext_html;
@property(assign, nonatomic) BOOL is_selfValue;
@end

/* -- Comment Interfaces -- */

@interface CommentCell
@property(strong, nonatomic) id cellView;
@end

@interface CommentCellView
@property(strong, nonatomic) id comment;
@property(strong, nonatomic) id parentDelegate;
@end

@interface BRComposeCommentViewController : NSObject
@property(assign, nonatomic) BOOL editComment;
@end

/* -- Post Interfaces -- */

@interface  StoryDetailView
@property(strong, nonatomic) UITableView *tableView;
-(void) refreshTouched;
@end

@interface StoryDetailViewController
@property(strong, nonatomic) id story;
@property(strong, nonatomic) id detailPage;

//custom elements
-(void) handleUndeleteCommentAction;
-(void) handleUndeletePostAction;
@end

/* -- Other Interfaces -- */

@interface BRUtils
+(id) attributedDescriptionForComment:(id) arg1;
+(id) createAttributedStringFromHTML:(id) arg1 options:(id) arg2;
@end
