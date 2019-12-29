
#import "Apollo.h"
#import "assets/TFHelper.h"

static BOOL isTFDeletedOnly;
static BOOL isApolloEnabled;
static CGFloat pushshiftRequestTimeoutValue;

%group Apollo

NSDictionary* apolloBodyAttributes = nil;

%hook ApolloApolloButtonNode
%end

%hook RKComment

-(BOOL) isDeleted{
	return NO;
}

-(BOOL) isModeratorRemoved{
	return NO;
}
%end


%hook MarkdownRenderer

+(id) attributedStringFromHTML:(id)arg1 attributes:(id) arg2 compact:(BOOL) arg3{

	apolloBodyAttributes = [arg2 copy];
	
	return %orig;
}
%end


%hook ApolloCommentCellNode
%property(strong,nonatomic) id undeleteButton;

-(void) didLoad {
	%orig;
	
	id commentBody = [MSHookIvar<id>(self, "comment") body];
	
	if ((isTFDeletedOnly && ([commentBody isEqualToString:@"[deleted]"] || [commentBody isEqualToString:@"[removed]"])) || !isTFDeletedOnly) {
	
		CGFloat imageSize = 20.0f;

		UIButton *undeleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[undeleteButton addTarget:self action:@selector(didTapUndeleteButton:) forControlEvents:UIControlEventTouchUpInside];
		undeleteButton.frame = CGRectMake(0, 0, imageSize, imageSize);
		
		UIImage* undeleteImage = [UIImage imageWithContentsOfFile:@"/var/mobile/Library/Application Support/TFDidThatSay/eye160dark.png"];
		[undeleteButton setImage:undeleteImage forState:UIControlStateNormal];

		[[self view] addSubview:undeleteButton];
		[self setUndeleteButton:undeleteButton];
	
	}
}

-(void) _layoutSublayouts{
	%orig;
	
	if ([self undeleteButton]){
	
		CGFloat imageSize = 20.0f;

		id moreNode = MSHookIvar<id>(self, "moreOptionsNode");
		id ageNode = MSHookIvar<id>(self, "ageNode");

		CGRect nodeFrame = [moreNode frame];
		CGFloat centerHeight = (nodeFrame.size.height + nodeFrame.origin.y * 2) / 2.0f;
		CGFloat nodeSpacing =[ageNode frame].origin.x - nodeFrame.origin.x - nodeFrame.size.width;

		[[self undeleteButton] setFrame:CGRectMake(nodeFrame.origin.x - imageSize - nodeSpacing, centerHeight - (imageSize / 2), imageSize, imageSize)];
	}
}

%new
-(void) didTapUndeleteButton:(id) sender{
	
	[sender setEnabled:NO];

	id comment = MSHookIvar<id>(self, "comment");
	
	[%c(TFHelper) getUndeleteDataWithID:[[comment fullName] componentsSeparatedByString:@"_"][1] isComment:YES timeout:pushshiftRequestTimeoutValue extraData:@{@"sender" : sender} completionTarget:self completionSelector:@selector(completeUndeleteCommentAction:)];
}

%new
-(void) completeUndeleteCommentAction:(NSDictionary *) data{
	
	id comment = MSHookIvar<id>(self, "comment");
	id bodyNode = MSHookIvar<id>(self, "bodyNode");
	id authorNode = MSHookIvar<id>(self, "authorNode");
	id authorTextNode = [authorNode subnodes][0];
	
	NSString *author = data[@"author"];
	
	id prevAuthorAttributedString = [authorTextNode attributedString];
	NSDictionary *authorStringAttributes = [prevAuthorAttributedString attributesAtIndex:0 longestEffectiveRange:nil inRange:NSMakeRange(0, [prevAuthorAttributedString length])];
	NSAttributedString *newAuthorAttributedString = [[NSAttributedString alloc] initWithString:author attributes:authorStringAttributes];

	[authorTextNode setAttributedText:newAuthorAttributedString];
	[authorTextNode setAttributedString:newAuthorAttributedString];
	
	[comment setAuthor:author];
	
	[bodyNode setAttributedString:[%c(MarkdownRenderer) attributedStringFromMarkdown:data[@"body"] withAttributes:apolloBodyAttributes]];
	
	[data[@"sender"] setEnabled:YES];
}

%end


%hook ApolloCommentsHeaderCellNode
%property(strong, nonatomic) id undeleteButton;

-(void) didLoad{
	%orig;
	
	id post = MSHookIvar<id>(self, "link");
	id postBody = [post selfText];

	if ([post isSelfPost]){
		if ((isTFDeletedOnly && ([postBody isEqualToString:@"[deleted]"] || [postBody isEqualToString:@"[removed]"])) || !isTFDeletedOnly) {

			CGFloat imageSize = 20.0f;

			UIButton *undeleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
			[undeleteButton addTarget:self action:@selector(didTapUndeleteButton:) forControlEvents:UIControlEventTouchUpInside];
			
			UIImage* undeleteImage = [UIImage imageWithContentsOfFile:@"/var/mobile/Library/Application Support/TFDidThatSay/eye160dark.png"];
			[undeleteButton setImage:undeleteImage forState:UIControlStateNormal];
			undeleteButton.frame = CGRectMake(0, 0, imageSize, imageSize);

			[[self view] addSubview:undeleteButton];
			[self setUndeleteButton:undeleteButton];
		}
	}
}

-(void) _layoutSublayouts{
	%orig;
	
	if ([self undeleteButton]){
		
		CGFloat imageSize = 20.0f;
		
		id postInfoNode = MSHookIvar<id>(self, "postInfoNode");
		id ageNode = MSHookIvar<id>(postInfoNode, "ageButtonNode");

		CGFloat centerHeight = [postInfoNode frame].origin.y + ([ageNode frame].size.height + [ageNode frame].origin.y * 2) / 2.0f;
		CGFloat buttonXPos = [postInfoNode frame].origin.x + [postInfoNode frame].size.width - imageSize;
		
		[[self undeleteButton] setFrame:CGRectMake(buttonXPos, centerHeight - (imageSize / 2), imageSize, imageSize)];
	}
}

%new
-(void) didTapUndeleteButton:(id) sender{
	
	[sender setEnabled:NO];
	
	id post = MSHookIvar<id>(self, "link");
	
	[%c(TFHelper) getUndeleteDataWithID:[[post fullName] componentsSeparatedByString:@"_"][1] isComment:NO timeout:pushshiftRequestTimeoutValue extraData:@{@"sender" : sender} completionTarget:self completionSelector:@selector(completeUndeletePostAction:)];
}

%new
-(void) completeUndeletePostAction:(NSDictionary *) data{
	
	id bodyNode = MSHookIvar<id>(self, "bodyNode");
	id postInfoNode = MSHookIvar<id>(self, "postInfoNode");
	id authorNode = MSHookIvar<id>(postInfoNode, "authorButtonNode");
	id authorTextNode = [authorNode subnodes][0];
	
	NSString *author = data[@"author"];
	
	//id post = MSHookIvar<id>(self, "link");
	//MSHookIvar<NSString*>(post, "_author") = author; //Crashes when clicking on author name. You will have to search the author name to go find the profile.

	author = [NSString stringWithFormat:@"by %@", author];

	id prevAuthorAttributedString = [authorTextNode attributedString];
	NSDictionary *authorStringAttributes = [prevAuthorAttributedString attributesAtIndex:0 longestEffectiveRange:nil inRange:NSMakeRange(0, [prevAuthorAttributedString length])];
	NSAttributedString* newAuthorAttributedString = [[NSAttributedString alloc] initWithString:author attributes:authorStringAttributes];

	[authorTextNode setAttributedText:newAuthorAttributedString];
	[authorTextNode setAttributedString:newAuthorAttributedString];
	
	[bodyNode setAttributedString:[%c(MarkdownRenderer) attributedStringFromMarkdown:data[@"body"] withAttributes:apolloBodyAttributes]];
	
	[data[@"sender"] setEnabled:YES];
}

%end

%end


static void loadPrefs(){
	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/User/Library/Preferences/com.lint.undelete.prefs.plist"];
	
	if (prefs){
		
		if ([prefs objectForKey:@"isApolloEnabled"] != nil) {
			isApolloEnabled = [[prefs objectForKey:@"isApolloEnabled"] boolValue];
		} else {
			isApolloEnabled = YES;
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
		isApolloEnabled = YES;
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
	
	if ([processName isEqualToString:@"Apollo"]){
		if (isApolloEnabled){
			
			CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, prefsChanged, CFSTR("com.lint.undelete.prefs.changed"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
			
			%init(Apollo, ApolloCommentsHeaderCellNode = objc_getClass("Apollo.CommentsHeaderCellNode"), ApolloCommentCellNode = objc_getClass("Apollo.CommentCellNode"), ApolloApolloButtonNode = objc_getClass("Apollo.ApolloButtonNode"));
		}
	}
}
