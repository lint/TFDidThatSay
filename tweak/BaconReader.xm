
#import "BaconReader.h"
#import "assets/TFHelper.h"
#import "assets/MMMarkdown/MMMarkdown.h"

static BOOL isBaconReaderEnabled;
static BOOL isTFDeletedOnly;
static CGFloat pushshiftRequestTimeoutValue;

%group BaconReader

BOOL shouldHaveBRUndeleteAction = NO;
NSString *tfPostSelftext;
NSString *tfPostAuthor;
id tfCommentCellView;
id tfStoryController;


%hook CommentCell
%end

%hook CommentCellView
%end

%hook StoryDetailView
%end


%hook BRComment

-(BOOL) contains_htmlValue{
	return YES;
} 

-(BOOL) primitiveContains_htmlValue{
	return YES;
}

-(BOOL) is_deletedValue{
	return NO;
}

-(BOOL) primitiveIs_deletedValue{
	return NO;
}

%end


%hook BRStory

+(id) storyWithDictionary:(id) arg1 inContext:(id) arg2 {
	id orig = %orig;
	
	if (tfPostSelftext){
		[orig setSelftext_html:tfPostSelftext];
		[orig setAuthor:tfPostAuthor];
		tfPostSelftext = nil;
		tfPostAuthor = nil;
	}
	
	return orig;
}

%end


%hook UIViewController

-(void) presentViewController:(id) arg1 animated:(BOOL) arg2 completion:(id) arg3 {
	
	if ([arg1 isKindOfClass:[UIAlertController class]] && shouldHaveBRUndeleteAction){
		
		UIAlertAction *undeleteAction;
		
		if (tfCommentCellView){
			undeleteAction = [UIAlertAction actionWithTitle:@"TF Did That Say?" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){[tfStoryController handleUndeleteCommentAction];}];
		} else {
			undeleteAction = [UIAlertAction actionWithTitle:@"TF Did That Say?" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){[tfStoryController handleUndeletePostAction];}];
		}
		 
		[arg1 addAction:undeleteAction];
	}
	
	%orig;
}

%end


%hook StoryDetailViewController

-(void) showMoreCommentActions:(id) arg1 showAll:(BOOL) arg2 {
	
	NSString *commentBody = [[arg1 comment] body];
	
	if ((isTFDeletedOnly && ([commentBody isEqualToString:@"[deleted]"] || [commentBody isEqualToString:@"[removed]"])) || !isTFDeletedOnly) {
		shouldHaveBRUndeleteAction = YES;
		tfCommentCellView = arg1;
		tfStoryController = self;
		tfPostSelftext = nil;
	}
	
	%orig;
	
	shouldHaveBRUndeleteAction = NO;
}

-(void) menuTouchedWithSender:(id) arg1 {
	
	if ([[self story] is_selfValue]){
		NSString *postBody = [[self story] selftext];
		
		if ((isTFDeletedOnly && ([postBody isEqualToString:@"[deleted]"] || [postBody isEqualToString:@"[removed]"])) || !isTFDeletedOnly) {
			shouldHaveBRUndeleteAction = YES;
			tfCommentCellView = nil;
			tfStoryController = self;
			tfPostSelftext = nil;
		}
	}
	
	%orig;
	
	shouldHaveBRUndeleteAction = NO;
}

%new
-(void) handleUndeleteCommentAction{
	
	[%c(TFHelper) getUndeleteDataWithID:[[tfCommentCellView comment] serverID] isComment:YES timeout:pushshiftRequestTimeoutValue extraData:nil completionTarget:self completionSelector:@selector(completeUndeleteCommentAction:)];
}

%new
-(void) completeUndeleteCommentAction:(NSDictionary *) data{
	
	id comment = [tfCommentCellView comment];
	
	NSString *body = data[@"body"];
	
	[comment setAuthor:data[@"author"]];
	[comment setBody:body];
	[comment setBody_html:[%c(MMMarkdown) HTMLStringWithMarkdown:body extensions:MMMarkdownExtensionsGitHubFlavored error:nil]];
	[comment setAttributedDescriptionString:nil];
	
	NSAttributedString *commentAttrString = [%c(BRUtils) attributedDescriptionForComment:comment];
	[comment setAttributedDescriptionString:commentAttrString];
	
	[[[self detailPage] tableView] reloadData];
}

%new
-(void) handleUndeletePostAction{
	
	[%c(TFHelper) getUndeleteDataWithID:[[self story] serverID] isComment:NO timeout:pushshiftRequestTimeoutValue extraData:nil completionTarget:self completionSelector:@selector(completeUndeletePostAction:)];
}

%new
-(void) completeUndeletePostAction:(NSDictionary *) data{
	
	tfPostAuthor = data[@"author"];
	tfPostSelftext = [%c(MMMarkdown) HTMLStringWithMarkdown:data[@"body"] extensions:MMMarkdownExtensionsGitHubFlavored error:nil];
	
	[[self detailPage] refreshTouched];
}

%end

%end


static void loadPrefs(){
	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/User/Library/Preferences/com.lint.undelete.prefs.plist"];
	
	if (prefs){
		
		if ([prefs objectForKey:@"isBaconReaderEnabled"] != nil){
			isBaconReaderEnabled = [[prefs objectForKey:@"isBaconReaderEnabled"] boolValue];
		} else {
			isBaconReaderEnabled = YES;
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
		isBaconReaderEnabled = YES;
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

	if ([processName isEqualToString:@"BaconReader"]){		
		if (isBaconReaderEnabled){
			
			CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, prefsChanged, CFSTR("com.lint.undelete.prefs.changed"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
			
			%init(BaconReader, StoryDetailView = objc_getClass("BaconReader.StoryDetailView"), StoryDetailViewController = objc_getClass("BaconReader.StoryDetailViewController"), CommentCellView = objc_getClass("BaconReader.CommentCellView"), CommentCell = objc_getClass("BaconReader.CommentCell"));
		}
	}
}