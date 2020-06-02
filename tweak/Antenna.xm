
#import "Antenna.h"
#import "assets/TFHelper.h"
#import "assets/MMMarkdown/MMMarkdown.h"

static BOOL isEnabled;
static BOOL isAntennaEnabled;
static BOOL isTFDeletedOnly;
static CGFloat pushshiftRequestTimeoutValue;

%group Antenna

BOOL shouldHaveAntennaUndeleteAction = NO;
id tfAntennaController;
id tfAntennaCommentCell;

%hook RCPostSwift
%end

%hook RCCommentTextSwift
%end


%hook RCCommentSwift

- (BOOL)isCommentDeleted{
	return NO;
}

%end


%hook RCPostCommentsController

- (void)didLongPressCell:(id)arg1 gesture:(id)arg2 {

	NSString *commentBody = [[[arg1 comment] commentText] body];

	if ([%c(TFHelper) shouldShowUndeleteButtonWithInfo:commentBody isDeletedOnly:isTFDeletedOnly]){
		tfAntennaController = self;
		tfAntennaCommentCell = arg1;
		shouldHaveAntennaUndeleteAction = YES;
	}

	%orig;

	shouldHaveAntennaUndeleteAction = NO;
}

%new
- (void)handleUndeleteCommentAction{

	[%c(TFHelper) getUndeleteDataWithID:[[tfAntennaCommentCell comment] itemId] isComment:YES timeout:pushshiftRequestTimeoutValue extraData:nil completionTarget:self completionSelector:@selector(completeUndeleteCommentAction:)];
}

%new
- (void)completeUndeleteCommentAction:(NSDictionary *)data {

	id comment = [tfAntennaCommentCell comment];
	id commentText = [comment commentText];

	NSString *body = data[@"body"];

	[comment setAuthor:data[@"author"]];
	[commentText setBody:body];
	[commentText setBodyHTML:[%c(MMMarkdown) HTMLStringWithMarkdown:body extensions:MMMarkdownExtensionsGitHubFlavored error:nil]];

	[commentText setBodyAttributedString:nil];
	[commentText setBodyAttributedStringForPreview:nil];
	[commentText setTextHeightCache:nil];
	[self setCommentHeightCache:nil];

	[tfAntennaCommentCell updateWithModelObject:comment];
	[[[self delegate] tableView] reloadData];
}

%end


%hook AHKActionSheet

- (void)show {

	if (shouldHaveAntennaUndeleteAction) {

		UIImage *undeleteImage = [UIImage imageWithContentsOfFile:@"/var/mobile/Library/Application Support/TFDidThatSay/eye160dark.png"];

		AHKActionSheetItem *actionItem = [self items][0];
		CGSize actionItemImageSize = [[actionItem image] size];
		CGSize newUndeleteImageSize = CGSizeMake(actionItemImageSize.width * 2, actionItemImageSize.height * 2);

		UIGraphicsBeginImageContext(newUndeleteImageSize);
		[undeleteImage drawInRect:CGRectMake(0, 0, newUndeleteImageSize.width, newUndeleteImageSize.height)];
		undeleteImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();

		undeleteImage = [[UIImage alloc] initWithCGImage:[undeleteImage CGImage] scale:2 orientation:UIImageOrientationUp];

		[self addButtonWithTitle:@"TF did that say?" image:undeleteImage type:0 handler:^{[tfAntennaController handleUndeleteCommentAction];}];
	}

	%orig;
}

%end


%hook RCPostActionsSectionHeader
%property(strong, nonatomic) UIButton *undeleteButton;

- (void)layoutSubviews {

	BOOL isAbleToUndeletePost = NO;

	id post = [[self delegate] postInternal];
	NSString *postBody = [[post selfCommentText] body];

	if ([post isSelfPost]){
		if ([%c(TFHelper) shouldShowUndeleteButtonWithInfo:postBody isDeletedOnly:isTFDeletedOnly]){
			isAbleToUndeletePost = YES;

			NSMutableArray *barButtons = [self defaultHeaderButtons];

			if ([barButtons count] <= 5){
				UIView *tempView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];

				[barButtons addObject:tempView];
			}

			%orig;

			if (![self undeleteButton]){
				UIButton *undeleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
				[undeleteButton addTarget:[[self delegate] headerCellController] action:@selector(handleUndeletePostAction:) forControlEvents:UIControlEventTouchUpInside];

				[undeleteButton setImage:[[UIImage imageWithContentsOfFile:@"/var/mobile/Library/Application Support/TFDidThatSay/eye160dark.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
				undeleteButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
				undeleteButton.tintColor = [barButtons[4] defaultColor];

				[self addSubview:undeleteButton];
				[self setUndeleteButton:undeleteButton];
			}

			[[self undeleteButton] setFrame:[barButtons[[barButtons count] - 1] frame]];
		}
	}

	if (!isAbleToUndeletePost){
		%orig;
	}
}

%end


%hook RCPostHeaderCellController

%new
- (void)handleUndeletePostAction:(id)sender {

	[sender setEnabled:NO];

	[%c(TFHelper) getUndeleteDataWithID:[[self post] itemId] isComment:NO timeout:pushshiftRequestTimeoutValue extraData:@{@"sender" : sender} completionTarget:self completionSelector:@selector(completeUndeletePostAction:)];
}

%new
- (void)completeUndeletePostAction:(NSDictionary *)data {

	id post = [self post];
	id postText = [post selfCommentText];

	NSString *body = data[@"body"];

	[post setAuthor:data[@"author"]];
	[postText setBody:body];
	[postText setBodyHTML:[%c(MMMarkdown) HTMLStringWithMarkdown:body extensions:MMMarkdownExtensionsGitHubFlavored error:nil]];

	[postText setBodyAttributedString:nil];
	[postText setBodyAttributedStringForPreview:nil];
	[postText setTextHeightCache:nil];

	[self loadView];
	[[self tableView] reloadData];

	[data[@"sender"] setEnabled:YES];
}

%end

%end


static void loadPrefs(){
	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/User/Library/Preferences/com.lint.undelete.prefs.plist"];

	if (prefs){
		isEnabled = [prefs objectForKey:@"isEnabled"] ? [[prefs objectForKey:@"isEnabled"] boolValue] : YES;
		isAntennaEnabled = [prefs objectForKey:@"isAntennaEnabled"] ? [[prefs objectForKey:@"isAntennaEnabled"] boolValue] : YES;
		isTFDeletedOnly = [prefs objectForKey:@"isTFDeletedOnly"] ? [[prefs objectForKey:@"isTFDeletedOnly"] boolValue] : YES;
		pushshiftRequestTimeoutValue = [prefs objectForKey:@"requestTimeoutValue"] ? [[prefs objectForKey:@"requestTimeoutValue"] doubleValue] : 10;
	} else {
		isEnabled = YES;
		isAntennaEnabled = YES;
		isTFDeletedOnly = YES;
		pushshiftRequestTimeoutValue = 10;
	}
}

static void prefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
  loadPrefs();
}


%ctor{
	loadPrefs();

	NSString* processName = [[NSProcessInfo processInfo] processName];

	if ([processName isEqualToString:@"amrc"]){
		if (isAntennaEnabled && isEnabled){

			CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)prefsChanged, CFSTR("com.lint.undelete.prefs.changed"), NULL, CFNotificationSuspensionBehaviorCoalesce);

			%init(Antenna, RCCommentSwift = objc_getClass("amrc.RCCommentSwift"), RCPostSwift = objc_getClass("amrc.RCPostSwift"), RCCommentTextSwift = objc_getClass("amrc.RCCommentTextSwift"));
		}
	}
}
