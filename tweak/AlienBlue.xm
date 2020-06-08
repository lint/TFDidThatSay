
#import "AlienBlue.h"
#import "assets/TFHelper.h"
#import "assets/MMMarkdown/MMMarkdown.h"

static BOOL isEnabled;
static BOOL isAlienBlueEnabled;
static BOOL isTFDeletedOnly;
static CGFloat pushshiftRequestTimeoutValue;

%group AlienBlue

%hook CommentOptionsDrawerView

- (id)initWithNode:(id)arg1 {
	id orig = %orig;

	NSString *author;

	if ([self isPostHeader]) {
		author = [[arg1 post] author];
	} else {
		author = [[(CommentNode *)arg1 comment] author];
	}

	if ([%c(TFHelper) shouldShowUndeleteButtonWithInfo:author isDeletedOnly:isTFDeletedOnly]){

		CGSize refSize = [[self buttons][0] frame].size;

		UIButton *undeleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[undeleteButton setFrame:CGRectMake(0, 0, refSize.width, refSize.height)];

		if ([self isPostHeader]){
			[undeleteButton addTarget:self action:@selector(didTapPostUndeleteButton:) forControlEvents:UIControlEventTouchUpInside];
		} else {
			[undeleteButton addTarget:self action:@selector(didTapCommentUndeleteButton:) forControlEvents:UIControlEventTouchUpInside];
		}

		if ([%c(Resources) isNight]) {
			[undeleteButton setImage:[UIImage imageWithContentsOfFile:@"/var/mobile/Library/Application Support/TFDidThatSay/eye160dark.png"] forState:UIControlStateNormal];
		} else {
			[undeleteButton setImage:[UIImage imageWithContentsOfFile:@"/var/mobile/Library/Application Support/TFDidThatSay/eye160light.png"] forState:UIControlStateNormal];
		}

		undeleteButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
		undeleteButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);

		[self addButton:undeleteButton];
	}

	return orig;
}

%new
- (void)didTapCommentUndeleteButton:(id)sender {

	[sender setEnabled:NO];

	id comment = [[self node] comment];

	[%c(TFHelper) getUndeleteDataWithID:[comment ident] isComment:YES timeout:pushshiftRequestTimeoutValue extraData:@{@"sender" : sender} completionTarget:self completionSelector:@selector(completeUndeleteCommentAction:)];
}

%new
- (void)completeUndeleteCommentAction:(NSDictionary *)data {

	id comment = [[self node] comment];

	NSString *body = data[@"body"];

	NSString *bodyHTML = [%c(MMMarkdown) HTMLStringWithMarkdown:body extensions:MMMarkdownExtensionsGitHubFlavored error:nil];

	[comment setAuthor:data[@"author"]];
	[comment setBody:body];
	[comment setBodyHTML:bodyHTML];

	[[self delegate] respondToStyleChange];

	[data[@"sender"] setEnabled:YES];
}

%new
- (void)didTapPostUndeleteButton:(id)sender {

	[sender setEnabled:NO];

	id post = [[self node] post];

	[%c(TFHelper) getUndeleteDataWithID:[post ident] isComment:NO timeout:pushshiftRequestTimeoutValue extraData:@{@"sender" : sender} completionTarget:self completionSelector:@selector(completeUndeletePostAction:)];
}

%new
- (void)completeUndeletePostAction:(NSDictionary *)data {

	id post = [[self node] post];
	id postComment = [[self node] comment]; //Don't know why he used a comment to store info about a post, but it exists

	NSString *body = data[@"body"];

	NSString *bodyHTML = [%c(MMMarkdown) HTMLStringWithMarkdown:body extensions:MMMarkdownExtensionsGitHubFlavored error:nil];

	[post setAuthor:data[@"author"]];
	[post setSelftext:body];
	[postComment setBodyHTML:bodyHTML];

	[[self delegate] respondToStyleChange];

	[data[@"sender"] setEnabled:YES];
}

%end

%end


static void loadPrefs(){
	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/User/Library/Preferences/com.lint.undelete.prefs.plist"];

	if (prefs){
		isEnabled = [prefs objectForKey:@"isEnabled"] ? [[prefs objectForKey:@"isEnabled"] boolValue] : YES;
		isAlienBlueEnabled = [prefs objectForKey:@"isAlienBlueEnabled"] ? [[prefs objectForKey:@"isAlienBlueEnabled"] boolValue] : YES;
		isTFDeletedOnly = [prefs objectForKey:@"isTFDeletedOnly"] ? [[prefs objectForKey:@"isTFDeletedOnly"] boolValue] : YES;
		pushshiftRequestTimeoutValue = [prefs objectForKey:@"requestTimeoutValue"] ? [[prefs objectForKey:@"requestTimeoutValue"] doubleValue] : 10;
	} else {
		isEnabled = YES;
		isAlienBlueEnabled = YES;
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

	if ([processName isEqualToString:@"AlienBlue"] || [processName isEqualToString:@"AlienBlueHD"]){
		if (isAlienBlueEnabled && isEnabled){

			CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)prefsChanged, CFSTR("com.lint.undelete.prefs.changed"), NULL, CFNotificationSuspensionBehaviorCoalesce);

			%init(AlienBlue);
		}
	}
}
