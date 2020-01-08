
#import "Narwhal.h"
#import "assets/TFHelper.h"

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

-(void) presentViewController:(id) arg1 animated:(BOOL) arg2 completion:(id) arg3{
	
	if ([arg1 isKindOfClass:[UIAlertController class]] && shouldHaveUndeleteAction){
		
		UIAlertAction* undeleteAction;
		
		if (tfComment){
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

-(void) swipeCell:(id) arg1 didEndDragWithState:(NSUInteger) arg2{

	if (arg2 == 2){
		if ([arg1 isKindOfClass:[%c(NRTCommentTableViewCell) class]]) {
			
			NSString *commentBody = MSHookIvar<NSString*>([arg1 comment], "_body");
			
			if ([%c(TFHelper) shouldShowUndeleteButtonWithInfo:commentBody isDeletedOnly:isTFDeletedOnly]){
				tfComment = [arg1 comment];
				tfController = self;
				shouldHaveUndeleteAction = YES;
			}
		} 
	} 
	
	%orig;
	
	shouldHaveUndeleteAction = NO;
}

-(void) _dotsButtonTouched:(id) arg1{
	
	if ([self linkTextOffscreenCell]){
		
		NSString *postBody = [[self link] selfText];
		
		if ([%c(TFHelper) shouldShowUndeleteButtonWithInfo:postBody isDeletedOnly:isTFDeletedOnly]){
			tfController = self;
			tfComment = nil;
			shouldHaveUndeleteAction = YES;
		}
	}
	
	%orig;
	
	shouldHaveUndeleteAction = NO;
}

%new
-(void) handleUndeletePostAction{
	
	id post = [self link];
	
	[%c(TFHelper) getUndeleteDataWithID:[[post fullName] componentsSeparatedByString:@"_"][1] isComment:NO timeout:pushshiftRequestTimeoutValue extraData:@{@"post" : post} completionTarget:self completionSelector:@selector(completeUndeletePostAction:)];
}

%new 
-(void) completeUndeletePostAction:(NSDictionary *) data{

	id post = data[@"post"];

	MSHookIvar<NSString*>(post, "_author") = data[@"author"];
	
	NSAttributedString* postBodyAttributedString = [%c(NRTMarkdownManager) attributedStringFromMarkdown:data[@"body"] type:0];
	[self setLinkText:postBodyAttributedString];
	
	[[self tableView] reloadData];
}

%new
-(void) completeUndeleteCommentAction:(NSDictionary *) data{

	id comment = data[@"comment"];

	if (comment){

		MSHookIvar<NSString*>(comment, "_author") = data[@"author"];
		MSHookIvar<NSString*>(comment, "_body") = data[@"body"];
		
		[[self commentsManager] updateComment:comment fromEdited:comment];
	}
}

%end


%hook NRTMediaTableViewDataSource

-(void) swipeCell:(id) arg1 didEndDragWithState:(NSUInteger) arg2{

	if (arg2 == 2){
		if ([arg1 isKindOfClass:[%c(NRTCommentTableViewCell) class]]) {
			
			NSString *commentBody = MSHookIvar<NSString*>([arg1 comment], "_body");
			
			if ([%c(TFHelper) shouldShowUndeleteButtonWithInfo:commentBody isDeletedOnly:isTFDeletedOnly]){
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
-(void) completeUndeleteCommentAction:(NSDictionary *) data{

	id comment = data[@"comment"];

	if (comment){

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
		
		if ([prefs objectForKey:@"isNarwhalEnabled"] != nil){
			isNarwhalEnabled = [[prefs objectForKey:@"isNarwhalEnabled"] boolValue];
		} else {
			isNarwhalEnabled = YES;
		}
		
		if ([prefs objectForKey:@"isTFDeletedOnly"] != nil) {
			isTFDeletedOnly = [[prefs objectForKey:@"isTFDeletedOnly"] boolValue];
		} else {
			isTFDeletedOnly = YES;
		}
		
		if ([prefs objectForKey:@"requestTimeoutValue"] != nil){
			pushshiftRequestTimeoutValue = [[prefs objectForKey:@"requestTimeoutValue"] doubleValue];
		} else {
			pushshiftRequestTimeoutValue = 10;
		}
		
	} else {
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
		if (isNarwhalEnabled){
			
			CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, prefsChanged, CFSTR("com.lint.undelete.prefs.changed"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
			
			%init(Narwhal);
		}
	}
}
