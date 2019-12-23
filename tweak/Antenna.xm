
#import "Antenna.h"
#import "assets/MMMarkdown.h"

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

-(BOOL) isCommentDeleted{
	return NO;
}

%end


%hook RCPostCommentsController

-(void) didLongPressCell:(id) arg1 gesture:(id) arg2 {
	
	NSString *commentBody = [[[arg1 comment] commentText] body];
	
	if ((isTFDeletedOnly && ([commentBody isEqualToString:@"[deleted]"] || [commentBody isEqualToString:@"[removed]"])) || !isTFDeletedOnly){
		tfAntennaController = self;
		tfAntennaCommentCell = arg1;
		shouldHaveAntennaUndeleteAction = YES;
	}
	
	%orig;
	
	shouldHaveAntennaUndeleteAction = NO;
}

%new
-(void) handleUndeleteCommentAction{
	
	id comment = [tfAntennaCommentCell comment];
	id commentText = [comment commentText];
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	NSOperationQueue *queue = [[NSOperationQueue alloc] init];

	[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.pushshift.io/reddit/search/comment/?ids=%@&fields=author,body",[comment itemId]]]];
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
		[commentText setBody:body];
		[commentText setBodyHTML:[%c(MMMarkdown) HTMLStringWithMarkdown:body extensions:MMMarkdownExtensionsGitHubFlavored error:nil]];
		
		[commentText setBodyAttributedString:nil];
		[commentText setBodyAttributedStringForPreview:nil];
		[commentText setTextHeightCache:nil];
		[self setCommentHeightCache:nil];
		
		[tfAntennaCommentCell performSelectorOnMainThread:@selector(updateWithModelObject:) withObject:comment waitUntilDone:YES];
		[[[self delegate] tableView] performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
	}];
}

%end


%hook AHKActionSheet 

-(void)show{
	
	if (shouldHaveAntennaUndeleteAction){
		
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

-(void) layoutSubviews{
	
	BOOL isAbleToUndeletePost = NO;
	
	id post = [[self delegate] postInternal];
	NSString *postBody = [[post selfCommentText] body];
	
	if ([post isSelfPost]){
		if ((isTFDeletedOnly && ([postBody isEqualToString:@"[deleted]"] || [postBody isEqualToString:@"[removed]"])) || !isTFDeletedOnly) {
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
-(void) handleUndeletePostAction:(id) sender{
	
	[sender setEnabled:NO];
	
	id post = [self post];
	id postText = [post selfCommentText];
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	NSOperationQueue *queue = [[NSOperationQueue alloc] init];

	[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.pushshift.io/reddit/search/submission/?ids=%@&fields=author,selftext",[post itemId]]]];
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
		
		[post setAuthor:author];
		[postText setBody:body];
		[postText setBodyHTML:[%c(MMMarkdown) HTMLStringWithMarkdown:body extensions:MMMarkdownExtensionsGitHubFlavored error:nil]];
		
		[postText setBodyAttributedString:nil];
		[postText setBodyAttributedStringForPreview:nil];
		[postText setTextHeightCache:nil];
		
		[self performSelectorOnMainThread:@selector(loadView) withObject:nil waitUntilDone:YES];
		[[self tableView] performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
		
		[sender setEnabled:YES];
	}];
}

%end

%end


static void loadPrefs(){
	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/User/Library/Preferences/com.lint.undelete.prefs.plist"];
	
	if (prefs){
		
		if ([prefs objectForKey:@"isAntennaEnabled"] != nil){
			isAntennaEnabled = [[prefs objectForKey:@"isAntennaEnabled"] boolValue];
		} else {
			isAntennaEnabled = YES;
		}
		
		if ([prefs objectForKey:@"isTFDeletedOnly"] != nil){
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
		if (isAntennaEnabled){
			
			CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, prefsChanged, CFSTR("com.lint.undelete.prefs.changed"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
			
			%init(Antenna, RCCommentSwift = objc_getClass("amrc.RCCommentSwift"), RCPostSwift = objc_getClass("amrc.RCPostSwift"), RCCommentTextSwift = objc_getClass("amrc.RCCommentTextSwift"));
		}
	}
}
