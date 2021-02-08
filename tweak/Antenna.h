
#import <UIKit/UIKit.h>

/* -- Comment Interfaces -- */

@interface RCCommentSwift
@property(strong, nonatomic) NSString *author;
@property(strong, nonatomic) NSString *itemId;
@property(strong, nonatomic) id commentText;
@end

@interface RCCommentTextSwift
@property(strong, nonatomic) NSString *author;
@property(strong, nonatomic) NSString *body;
@property(strong, nonatomic) NSString *bodyHTML;
@property(strong, nonatomic) NSAttributedString *bodyAttributedString;
@property(strong, nonatomic) NSAttributedString *bodyAttributedStringForPreview;
@property(strong, nonatomic) id textHeightCache;
@end

@interface RCCommentCell : NSObject
@property(strong, nonatomic) id comment;
- (void)updateWithModelObject:(id)arg1;
@end

@interface RCPostCommentsController
@property(strong, nonatomic) id postCommentsCollector;
@property(strong, nonatomic) id delegate;
@property(strong, nonatomic) NSMutableDictionary *commentHeightCache;
- (void)controllerWillChangeContent:(id)arg1;
- (void)controllerDidChangeContent:(id)arg1;
- (void)controller:(id)arg1 didChange:(id)arg2 at:(id)arg3 for:(long long)arg4 newIndexPath:(id)arg5;

//custom elements
- (void)handleUndeleteCommentAction;
@end

@interface AHKActionSheet
@property(strong, nonatomic) NSMutableArray *items;
- (void)addButtonWithTitle:(id)arg1 image:(id)arg2 type:(long long)arg3 handler:(id)arg4;
@end

@interface AHKActionSheetItem
@property(strong, nonatomic) UIImage *image;
@end

/* -- Post Interfaces -- */

@interface RCPostSwift
@property(strong, nonatomic) NSString *author;
@property(strong, nonatomic) NSNumber *isSelf;
@property(strong, nonatomic) NSString *itemId;
@property(strong, nonatomic) id selfCommentText;
- (BOOL)isSelfPost;
@end

@interface RCPostActionsSectionHeader : UIView
@property(strong, nonatomic) NSMutableArray *defaultHeaderButtons;
@property(strong, nonatomic) id delegate;

//custom elements
@property(strong, nonatomic) UIButton *undeleteButton;
@end

@interface RCPostSectionHeaderButton
@property(strong, nonatomic) UIColor *defaultColor;
@end

@interface RCPostDownloadViewController
@property(strong, nonatomic) UITableView *tableView;
@property(strong, nonatomic) id headerCellController;
@property(strong, nonatomic) id postInternal;
@end

@interface RCPostHeaderCellController : NSObject
@property(strong, nonatomic) id post;
@property(strong, nonatomic) UITableView *tableView;
- (void)loadView;

//custom elements
- (void)handleUndeletePostAction:(id)arg1;
@end
