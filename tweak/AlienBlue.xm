
#import "AlienBlue.h"
#import "assets/MMMarkdown.h"

static BOOL isAlienBlueEnabled;
static BOOL isAlienBlueDeletedOnly;
static CGFloat pushshiftRequestTimeoutValue;

%group AlienBlue

%hook NCommentCell

-(void) setDrawerView:(id) arg1 {
	[arg1 setComment:[self comment]];
	%orig;
}

%end

%hook NCommentPostHeaderCell

-(void) setDrawerView:(id) arg1 {
	[arg1 setPost:[self post]];
	[arg1 setCommentNode:[self node]];
	%orig;
}

%end


%hook CommentOptionsDrawerView
%property(strong, nonatomic) Comment *comment;
%property(strong, nonatomic) Post *post;
%property(strong, nonatomic) CommentPostHeaderNode *commentNode;

-(id) initWithNode:(id) arg1 {
	id orig = %orig;
	
	NSString *body;
	
	if ([self post]) {
		body = [[self post] selftext];
	} else if ([self comment]){
		body = [[self comment] body];
	}
	
	if ((isAlienBlueDeletedOnly && ([body isEqualToString:@"[deleted]"] || [body isEqualToString:@"[removed]"])) || !isAlienBlueDeletedOnly) {
	
		CGSize refSize = [[self buttons][0] frame].size;

		UIButton *undeleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[undeleteButton setFrame:CGRectMake(0, 0, refSize.width, refSize.height)];
		
		if ([self isPostHeader]){
			[undeleteButton addTarget:self action:@selector(didTapPostUndeleteButton) forControlEvents:UIControlEventTouchUpInside];
		} else {
			[undeleteButton addTarget:self action:@selector(didTapCommentUndeleteButton) forControlEvents:UIControlEventTouchUpInside];
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
-(void) didTapCommentUndeleteButton {
	
	Comment *comment = [self comment];
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	NSOperationQueue *queue = [[NSOperationQueue alloc] init];

	[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.pushshift.io/reddit/search/comment/?ids=%@&fields=author,body",[comment ident]]]];
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
		
		NSString *bodyHTML = [%c(MMMarkdown) HTMLStringWithMarkdown:body extensions:MMMarkdownExtensionsGitHubFlavored error:nil];
		
		[comment setAuthor:author];
		[comment setBody:body];
		[comment setBodyHTML:bodyHTML];
		
		[[self delegate] performSelectorOnMainThread:@selector(respondToStyleChange) withObject:nil waitUntilDone:NO];
	}];
}

%new 
-(void) didTapPostUndeleteButton {
	
	Post *post = [self post];
	Comment *postComment = [[self commentNode] comment]; //Don't know why he used a comment to store info about a post, but it exists
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	NSOperationQueue *queue = [[NSOperationQueue alloc] init];

	[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.pushshift.io/reddit/search/submission/?ids=%@&fields=author,selftext",[post ident]]]];
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
		
		NSString *bodyHTML = [%c(MMMarkdown) HTMLStringWithMarkdown:body extensions:MMMarkdownExtensionsGitHubFlavored error:nil];
		
		[post setAuthor:author];
		[post setSelftext:body];
		[postComment setBodyHTML:bodyHTML];
		
		[[self delegate] performSelectorOnMainThread:@selector(respondToStyleChange) withObject:nil waitUntilDone:NO];
		
	}];
}

%end

%end


static void loadPrefs(){
	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/User/Library/Preferences/com.lint.undelete.prefs.plist"];
	
	if (prefs){
		
		if ([prefs objectForKey:@"isAlienBlueEnabled"] != nil){
			isAlienBlueEnabled = [[prefs objectForKey:@"isAlienBlueEnabled"] boolValue];
		} else {
			isAlienBlueEnabled = YES;
		}
		
		if ([prefs objectForKey:@"isAlienBlueDeletedOnly"] != nil){
			isAlienBlueDeletedOnly = [[prefs objectForKey:@"isAlienBlueDeletedOnly"] boolValue];
		} else {
			isAlienBlueDeletedOnly = YES;
		}
		
		if ([prefs objectForKey:@"requestTimeoutValue"] != nil){
			pushshiftRequestTimeoutValue = [[prefs objectForKey:@"requestTimeoutValue"] doubleValue];
		} else {
			pushshiftRequestTimeoutValue = 10;
		}
		
	} else {
		isAlienBlueEnabled = YES;
		isAlienBlueDeletedOnly = YES;
		pushshiftRequestTimeoutValue = 10;
	}	
}

static void prefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
  loadPrefs();
}


%ctor {
	loadPrefs();
	
	NSString* processName = [[NSProcessInfo processInfo] processName];

	if ([processName isEqualToString:@"AlienBlue"]){		
		if (isAlienBlueEnabled){
			
			CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, prefsChanged, CFSTR("com.lint.undelete.prefs.changed"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
			
			%init(AlienBlue);
		}
	}
}

