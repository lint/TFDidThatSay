
#import "BaconReader.h"
#import "assets/MMMarkdown.h"

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
	
	id comment = [tfCommentCellView comment];
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	NSOperationQueue *queue = [[NSOperationQueue alloc] init];

	[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.pushshift.io/reddit/search/comment/?ids=%@&fields=author,body", [comment serverID]]]];
	[request setHTTPMethod:@"GET"];
	[request setTimeoutInterval:pushshiftRequestTimeoutValue];

	[NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
	
		NSString *author = @"[author]";
		NSString *body = @"[body]";

		if (data != nil && error == nil){
			id jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
			if ([[jsonData objectForKey:@"data"] count] != 0){
				author = [[jsonData objectForKey:@"data"][0] objectForKey:@"author"];
				body = [[jsonData objectForKey:@"data"][0] objectForKey:@"body"];
				if ([body isEqualToString:@"[deleted]"] || [body isEqualToString:@"[removed]"]){
					body = @"[pushshift was unable to archive this]";
				}
			} else {
				body = @"[pushshift has not archived this yet]";
			}
		} else if (error != nil || data == nil){
			body = [NSString stringWithFormat:@"[an error occured while attempting to contact pushshift api (%@)]", [error localizedDescription]];
		}
		
		[comment setAuthor:author];
		[comment setBody:body];
		[comment setBody_html:[%c(MMMarkdown) HTMLStringWithMarkdown:body extensions:MMMarkdownExtensionsGitHubFlavored error:nil]];
		[comment setAttributedDescriptionString:nil];
		
		NSAttributedString *commentAttrString = [%c(BRUtils) attributedDescriptionForComment:comment];
		[comment setAttributedDescriptionString:commentAttrString];
		
		[[[self detailPage] tableView] performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
	}];
}

%new
-(void) handleUndeletePostAction{
	
	id post = [self story];
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	NSOperationQueue *queue = [[NSOperationQueue alloc] init];

	[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.pushshift.io/reddit/search/submission/?ids=%@&fields=author,selftext", [post serverID]]]];
	[request setHTTPMethod:@"GET"];
	[request setTimeoutInterval:pushshiftRequestTimeoutValue];

	[NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
		
		NSString *author = @"[author]";
		NSString *body = @"[body]";

		if (data != nil && error == nil){
			id jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
			if ([[jsonData objectForKey:@"data"] count] != 0){
				author = [[jsonData objectForKey:@"data"][0] objectForKey:@"author"];
				body = [[jsonData objectForKey:@"data"][0] objectForKey:@"selftext"];
				if ([body isEqualToString:@"[deleted]"] || [body isEqualToString:@"[removed]"]){
					body = @"[pushshift was unable to archive this]";
				}
			} else {
				body = @"[pushshift has not archived this yet]";
			}
		} else if (error != nil || data == nil){
			body = [NSString stringWithFormat:@"[an error occured while attempting to contact pushshift api (%@)]", [error localizedDescription]];
		}
		
		tfPostAuthor = author;
		tfPostSelftext = [%c(MMMarkdown) HTMLStringWithMarkdown:body extensions:MMMarkdownExtensionsGitHubFlavored error:nil];
	
		[[self detailPage] performSelectorOnMainThread:@selector(refreshTouched) withObject:nil waitUntilDone:NO];
		
	}];
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