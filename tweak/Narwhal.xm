
#import "Narwhal.h"
#import "assets/TFHelper.h"

static BOOL isEnabled;
static BOOL isNarwhalEnabled;
static BOOL isTFDeletedOnly;
static CGFloat pushshiftRequestTimeoutValue;

%group Narwhal

BOOL shouldHaveUndeleteAction = NO;
id tfComment;
id tfController;

void getUndeleteCommentData(id controller, id comment){
	[%c(TFHelper) getUndeleteDataWithID:[[comment fullName] componentsSeparatedByString:@"_"][1] isComment:YES timeout:pushshiftRequestTimeoutValue extraData:@{@"comment" : comment} completionTarget:controller completionSelector:@selector(completeUndeleteCommentAction:)];
}


%hook UIViewController

- (void)presentViewController:(id)arg1 animated:(BOOL)arg2 completion:(id)arg3 {

	if ([arg1 isKindOfClass:[UIAlertController class]] && shouldHaveUndeleteAction) {

		UIAlertAction* undeleteAction;

		if (tfComment) {
			undeleteAction = [UIAlertAction actionWithTitle:@"tf did that say?" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){getUndeleteCommentData(tfController, tfComment);}];
		} else {
			undeleteAction = [UIAlertAction actionWithTitle:@"tf did that say?" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){[tfController handleUndeletePostAction];}];
		}

		[arg1 addAction:undeleteAction];
	}

	%orig;
}

%end


%hook NRTLinkViewController

- (void)swipeCell:(id)arg1 didEndDragWithState:(NSUInteger)arg2 {

	if (arg2 == 2) {
		if ([arg1 isKindOfClass:[%c(NRTCommentTableViewCell) class]]) {

			NSString *author = [[arg1 comment] author];

			if ([%c(TFHelper) shouldShowUndeleteButtonWithInfo:author isDeletedOnly:isTFDeletedOnly]){
				tfComment = [arg1 comment];
				tfController = self;
				shouldHaveUndeleteAction = YES;
			}
		}
	}

	%orig;

	shouldHaveUndeleteAction = NO;
}

- (void)_dotsButtonTouched:(id)arg1 {

	if ([self linkTextOffscreenCell]) {

		NSString *author = [[self link] author];

		if ([%c(TFHelper) shouldShowUndeleteButtonWithInfo:author isDeletedOnly:isTFDeletedOnly]) {
			tfController = self;
			tfComment = nil;
			shouldHaveUndeleteAction = YES;
		}
	}

	%orig;

	shouldHaveUndeleteAction = NO;
}

%new
- (void)handleUndeletePostAction {

	id post = [self link];

	[%c(TFHelper) getUndeleteDataWithID:[[post fullName] componentsSeparatedByString:@"_"][1] isComment:NO timeout:pushshiftRequestTimeoutValue extraData:@{@"post" : post} completionTarget:self completionSelector:@selector(completeUndeletePostAction:)];
}

%new
- (void)completeUndeletePostAction:(NSDictionary *)data {

	id post = data[@"post"];

	MSHookIvar<NSString*>(post, "_author") = data[@"author"];

	NSAttributedString* postBodyAttributedString = [%c(NRTMarkdownManager) attributedStringFromMarkdown:data[@"body"] type:0];
	[self setLinkText:postBodyAttributedString];

	[[self tableView] reloadData];
}

%new
- (void)completeUndeleteCommentAction:(NSDictionary *)data {

	id comment = data[@"comment"];

	if (comment) {

		MSHookIvar<NSString*>(comment, "_author") = data[@"author"];
		MSHookIvar<NSString*>(comment, "_body") = data[@"body"];

		[[self commentsManager] updateComment:comment fromEdited:comment];
	}
}

%end


%hook NRTMediaTableViewDataSource

- (void)swipeCell:(id)arg1 didEndDragWithState:(NSUInteger)arg2 {

	if (arg2 == 2) {
		if ([arg1 isKindOfClass:[%c(NRTCommentTableViewCell) class]]) {

			NSString *author = [[arg1 comment] author];

			if ([%c(TFHelper) shouldShowUndeleteButtonWithInfo:author isDeletedOnly:isTFDeletedOnly]) {
				tfComment = [arg1 comment];
				tfController = self;
				shouldHaveUndeleteAction = YES;
			}
		}
	}

	%orig;

	shouldHaveUndeleteAction = NO;
}

%new
- (void)completeUndeleteCommentAction:(NSDictionary *)data {

	id comment = data[@"comment"];

	if (comment) {

		MSHookIvar<NSString*>(comment, "_author") = data[@"author"];
		MSHookIvar<NSString*>(comment, "_body") = data[@"body"];

		[[self commentsManager] updateComment:comment fromEdited:comment];
	}
}

%end

%end


static void loadPrefs(){
	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/User/Library/Preferences/com.lint.undelete.prefs.plist"];

	if (prefs){
		isEnabled = [prefs objectForKey:@"isEnabled"] ? [[prefs objectForKey:@"isEnabled"] boolValue] : YES;
		isNarwhalEnabled = [prefs objectForKey:@"isNarwhalEnabled"] ? [[prefs objectForKey:@"isNarwhalEnabled"] boolValue] : YES;
		isTFDeletedOnly = [prefs objectForKey:@"isTFDeletedOnly"] ? [[prefs objectForKey:@"isTFDeletedOnly"] boolValue] : YES;
		pushshiftRequestTimeoutValue = [prefs objectForKey:@"requestTimeoutValue"] ? [[prefs objectForKey:@"requestTimeoutValue"] doubleValue] : 10;
	} else {
		isEnabled = YES;
		isNarwhalEnabled = YES;
		isTFDeletedOnly = YES;
		pushshiftRequestTimeoutValue = 10;
	}
}

static void prefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
  loadPrefs();
}


%ctor {
	loadPrefs();

	NSString* processName = [[NSProcessInfo processInfo] processName];

	if ([processName isEqualToString:@"narwhal"]){
		if (isNarwhalEnabled && isEnabled){

			CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)prefsChanged, CFSTR("com.lint.undelete.prefs.changed"), NULL, CFNotificationSuspensionBehaviorCoalesce);

			%init(Narwhal);
		}
	}
}
