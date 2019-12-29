
#import "Beam.h"
#import "assets/TFHelper.h"

static BOOL isBeamEnabled;
static BOOL isTFDeletedOnly;
static CGFloat pushshiftRequestTimeoutValue;

%group Beam

%hook CommentCell
%property(strong, nonatomic) UIButton *undeleteButton;

-(void) layoutSubviews{
	%orig;
	
	UIButton *undeleteButton = [self undeleteButton];
	
	if (undeleteButton){
		if ([self isCollapsed]){
			[undeleteButton setHidden:YES];
		} else {
			[undeleteButton setHidden:NO];
		}
	} else {
		
		NSString *commentBody = [[self comment] content];
	
		if ((isTFDeletedOnly && ([commentBody isEqualToString:@"[deleted]"] || [commentBody isEqualToString:@"[removed]"])) || !isTFDeletedOnly){
			
			CGFloat authorTextHeight = [[self authorButton] frame].size.height;
			
			undeleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
			[undeleteButton addTarget:self action:@selector(handleUndeleteCommentAction:) forControlEvents:UIControlEventTouchUpInside];
			
			[undeleteButton setImage:[UIImage imageWithContentsOfFile:@"/var/mobile/Library/Application Support/TFDidThatSay/eye160dark.png"] forState:UIControlStateNormal];
			undeleteButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
			undeleteButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
			
			undeleteButton.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width - authorTextHeight - 5, 5, authorTextHeight, authorTextHeight);
			
			[[self commentContentView] addSubview:undeleteButton];
			[self setUndeleteButton:undeleteButton];
		}
	}
}

%new
-(void) handleUndeleteCommentAction:(id) sender{
	
	[sender setEnabled:NO];
	
	[%c(TFHelper) getUndeleteDataWithID:[[self comment] identifier] isComment:YES timeout:pushshiftRequestTimeoutValue extraData:@{@"sender" : sender} completionTarget:self completionSelector:@selector(completeUndeleteCommentAction:)];
}

%new
-(void) completeUndeleteCommentAction:(NSDictionary *) data{
	
	id comment = [self comment];
	
	[comment setAuthor:data[@"author"]];
	[comment setContent:data[@"body"]];
	[comment setMarkdownString:nil];
	
	[self setCommentDidChange:YES];
	[self reloadContents];
	[[MSHookIvar<id>(self, "delegate") tableView] reloadData];
	
	[data[@"sender"] setEnabled:YES];
}

%end


%hook PostSelfTextPartCell

-(void) setSelected:(BOOL) arg1 animated:(BOOL) arg2{
	%orig;
	
	id postViewController = [self _viewControllerForAncestor];
	
	if ([postViewController isMemberOfClass:objc_getClass("beam.PostDetailEmbeddedViewController")]){
	
		[postViewController setSelfTextView:self];
		[postViewController setPost:[self post]];
	}
}

%end


%hook PostMetadataView

-(void) layoutSubviews{
	%orig;
	
	id postViewController = MSHookIvar<id>(self, "delegate");
	
	if ([postViewController isMemberOfClass:objc_getClass("beam.PostDetailEmbeddedViewController")]){
		[postViewController setMetadataView:self];
	}
}

%end


%hook PostToolbarView
%property(strong, nonatomic) UIButton *undeleteButton;

-(void) layoutSubviews{
	%orig;
	
	if (![self undeleteButton] && [[[self post] isSelfText] boolValue] && [MSHookIvar<id>(self, "delegate") isMemberOfClass:objc_getClass("beam.PostDetailEmbeddedViewController")]){
		
		NSString *postBody = [[self post] content];
		
		if ((isTFDeletedOnly && ([postBody isEqualToString:@"[deleted]"] || [postBody isEqualToString:@"[removed]"])) || !isTFDeletedOnly){
		
			id moreButton = MSHookIvar<id>(self, "moreButton");
			
			CGFloat buttonHeight = [moreButton frame].size.height;
			
			UIButton *undeleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
			[undeleteButton addTarget:MSHookIvar<id>(self, "delegate") action:@selector(handleUndeletePostAction:) forControlEvents:UIControlEventTouchUpInside];
			
			[undeleteButton setImage:[UIImage imageWithContentsOfFile:@"/var/mobile/Library/Application Support/TFDidThatSay/eye160dark.png"] forState:UIControlStateNormal];
			undeleteButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
			undeleteButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
			
			undeleteButton.frame = CGRectMake([moreButton frame].origin.x - buttonHeight, 1, buttonHeight, buttonHeight);
			
			[self addSubview:undeleteButton];
			[self setUndeleteButton:undeleteButton];
		}
	}
}

%end

%hook PostDetailEmbeddedViewController
%property(strong, nonatomic) id selfTextView;
%property(strong, nonatomic) id metadataView;
%property(strong, nonatomic) id post;

%new
-(void) handleUndeletePostAction:(id) sender{
	
	[sender setEnabled:NO];
	
	id post = [self post];
	
	if (post){
	
		[%c(TFHelper) getUndeleteDataWithID:[post identifier] isComment:NO timeout:pushshiftRequestTimeoutValue extraData:@{@"sender" : sender} completionTarget:self completionSelector:@selector(completeUndeletePostAction:)];
	}
}

%new
-(void) completeUndeletePostAction:(NSDictionary *) data{
	
	id post = [self post];
	
	[post setAuthor:data[@"author"]];
	[post setContent:data[@"body"]];
	[post setMarkdownString:nil];
	
	if ([self selfTextView]){
		[[self selfTextView] reloadContents];
	}
	
	if ([self metadataView]){
		[[self metadataView] setPost:post];
	}
	
	[[self tableView] reloadData];
	
	[data[@"sender"] setEnabled:YES];
}

%end

%end


static void loadPrefs(){
	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/User/Library/Preferences/com.lint.undelete.prefs.plist"];
	
	if (prefs){
		
		if ([prefs objectForKey:@"isBeamEnabled"] != nil){
			isBeamEnabled = [[prefs objectForKey:@"isBeamEnabled"] boolValue];
		} else {
			isBeamEnabled = YES;
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
		isBeamEnabled = YES;
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

	if ([processName isEqualToString:@"beam"]){		
		if (isBeamEnabled){
			
			CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, prefsChanged, CFSTR("com.lint.undelete.prefs.changed"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
			
			%init(Beam, CommentCell = objc_getClass("beam.CommentCell"), PostDetailEmbeddedViewController = objc_getClass("beam.PostDetailEmbeddedViewController"), PostToolbarView = objc_getClass("beam.PostToolbarView"), PostSelfTextPartCell = objc_getClass("beam.PostSelfTextPartCell"), PostMetadataView = objc_getClass("beam.PostMetadataView"));
		}
	}
}
