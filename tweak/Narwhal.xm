
#import "Narwhal.h"

static BOOL isNarwhalEnabled;
static BOOL isTFDeletedOnly;
static CGFloat pushshiftRequestTimeoutValue;

%group Narwhal

BOOL shouldHaveUndeleteAction = NO;
id tfComment;
id tfController;

void getUndeleteCommentData(id controller, id comment){
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	NSOperationQueue *queue = [[NSOperationQueue alloc] init];

	[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.pushshift.io/reddit/search/comment/?ids=%@&fields=author,body",[[comment fullName] componentsSeparatedByString:@"_"][1]]]];
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
		
		[controller performSelectorOnMainThread:@selector(completeUndeleteComment:) withObject:@{@"body":body, @"author":author, @"comment":comment} waitUntilDone:NO];
	}];
	
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

%new
-(void) completeUndeleteComment:(id) data{

	id comment = data[@"comment"];

	if (comment){

		MSHookIvar<NSString*>(comment, "_author") = data[@"author"];
		MSHookIvar<NSString*>(comment, "_body") = data[@"body"];
		
		[[self commentsManager] updateComment:comment fromEdited:comment];
	}
}

%new 
-(void) completeUndeletePost:(id) data{

	id post = data[@"post"];

	MSHookIvar<NSString*>(post, "_author") = data[@"author"];
	
	NSAttributedString* postBodyAttributedString = [%c(NRTMarkdownManager) attributedStringFromMarkdown:data[@"body"] type:0];
	[self setLinkText:postBodyAttributedString];
		
	[[self tableView] reloadData];
}

%new
-(void) handleUndeletePostAction{
	
	id post = [self link];
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	NSOperationQueue *queue = [[NSOperationQueue alloc] init];

	[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.pushshift.io/reddit/search/submission/?ids=%@&fields=author,selftext",[[post fullName] componentsSeparatedByString:@"_"][1]]]];
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
		
		[self performSelectorOnMainThread:@selector(completeUndeletePost:) withObject:@{@"body":body, @"author":author, @"post":post} waitUntilDone:NO];
		
	}];
}

-(void) swipeCell:(id) arg1 didEndDragWithState:(NSUInteger) arg2{

	if (arg2 == 2){
		if ([arg1 isKindOfClass:[%c(NRTCommentTableViewCell) class]]) {
			
			NSString *commentBody = MSHookIvar<NSString*>([arg1 comment], "_body");
			
			if ((isTFDeletedOnly && ([commentBody isEqualToString:@"[deleted]"] || [commentBody isEqualToString:@"[removed]"])) || !isTFDeletedOnly){
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
		
		if ((isTFDeletedOnly && ([postBody isEqualToString:@"[deleted]"] || [postBody isEqualToString:@"[removed]"])) || !isTFDeletedOnly){
			tfController = self;
			tfComment = nil;
			shouldHaveUndeleteAction = YES;
		}
	}
	
	%orig;
	
	shouldHaveUndeleteAction = NO;
}

%end


%hook NRTMediaTableViewDataSource

%new
-(void) completeUndeleteComment:(id) data{

	id comment = data[@"comment"];

	if (comment){

		MSHookIvar<NSString*>(comment, "_author") = data[@"author"];
		MSHookIvar<NSString*>(comment, "_body") = data[@"body"];
		
		[[self commentsManager] updateComment:comment fromEdited:comment];
	}
}

-(void) swipeCell:(id) arg1 didEndDragWithState:(NSUInteger) arg2{

	if (arg2 == 2){
		if ([arg1 isKindOfClass:[%c(NRTCommentTableViewCell) class]]) {
			
			NSString *commentBody = MSHookIvar<NSString*>([arg1 comment], "_body");
			
			if ((isTFDeletedOnly && ([commentBody isEqualToString:@"[deleted]"] || [commentBody isEqualToString:@"[removed]"])) || !isTFDeletedOnly){
				tfComment = [arg1 comment];
				tfController = self;
				shouldHaveUndeleteAction = YES;
			}
		} 
	} 
	
	%orig;
	
	shouldHaveUndeleteAction = NO;
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
