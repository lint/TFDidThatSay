
#import "Apollo.h"
#import "assets/TFHelper.h"

static BOOL isEnabled;
static BOOL isApolloEnabled;
static BOOL isTFDeletedOnly;
static CGFloat pushshiftRequestTimeoutValue;
static BOOL shouldApolloHaveButton;

%group Apollo

NSDictionary* apolloBodyAttributes = nil;

BOOL shouldAddUndeleteCell = NO;
id apolloCommentCell;
id apolloCommentController;

BOOL shouldAddUndeleteCellForContext = NO;
id apolloCommentCellForContext;
id apolloCommentsControllerForContext;


%hook ApolloButtonNode
%end

%hook IconActionTableViewCell
%end


%hook RKComment

- (BOOL)isDeleted {
	return NO;
}

- (BOOL)isModeratorRemoved {
	return NO;
}

%end

//1.8+, unsure why this is all I needed to add for 1.8 support, the rest of this still works even w/o changing RKComment and RKLink references
%hook RDKComment

- (BOOL)isDeleted {
	return NO;
}

- (BOOL)isModeratorRemoved {
	return NO;
}

%end


%hook RKLink
%property(strong, nonatomic) NSString *undeleteAuthor;

- (id)author {
	return [self undeleteAuthor] ? [self undeleteAuthor] : %orig;
}

%end


%hook RDKLink
%property(strong, nonatomic) NSString *undeleteAuthor;

- (id)author {
	return [self undeleteAuthor] ? [self undeleteAuthor] : %orig;
}

%end


%hook MarkdownRenderer

+ (id)attributedStringFromHTML:(id)arg1 attributes:(id)arg2 compact:(BOOL)arg3 {

	apolloBodyAttributes = [arg2 copy];

	return %orig;
}

// fix for v1.10.6 no longer getting text attributes, meaning text color was not showing properly
+ (id)attributedStringFromHTML:(id)arg1 attributes:(id)arg2 compact:(BOOL)arg3 snoomojiMapping:(id)arg4 {

	apolloBodyAttributes = [arg2 copy];

	return %orig;
}

+ (id)attributedStringFromHTML:(id)arg1 attributes:(id)arg2 compact:(BOOL)arg3 snoomojiMapping:(id)arg4 snoomojiInfo:(id)arg5 {

	apolloBodyAttributes = [arg2 copy];

	return %orig;
}

%end


%hook ActionController

- (id)tableView:(id)arg1 cellForRowAtIndexPath:(NSIndexPath *)arg2 {

	if (shouldAddUndeleteCell) {
		if ([arg2 row] == [self tableView:arg1 numberOfRowsInSection:0] - 1) {

			id undeleteCell = [arg1 dequeueReusableCellWithIdentifier:@"IconActionCell" forIndexPath:arg2];
			id prevCell = [arg1 dequeueReusableCellWithIdentifier:@"IconActionCell"]; // is this necessary?

			UIImageView *prevCellImageView = MSHookIvar<UIImageView *>(prevCell, "iconImageView");
			CGSize prevImageSize = [[prevCellImageView image] size];

			UIImage *undeleteImage;

			//if (@available(iOS 13.0, *)){
			if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"13.0")) {

				undeleteImage = [UIImage systemImageNamed:@"eye"];

				if (!undeleteImage){
					undeleteImage = [UIImage imageWithContentsOfFile:@"/var/mobile/Library/Application Support/TFDidThatSay/eye160dark.png"];
				} else {
					CGSize squareSize = CGSizeMake(undeleteImage.size.width, undeleteImage.size.width);

					UIGraphicsBeginImageContextWithOptions(squareSize, NO, 0);
					[undeleteImage drawInRect:CGRectMake(0, (squareSize.height - undeleteImage.size.height) / 2, squareSize.width, undeleteImage.size.height)];
					undeleteImage = UIGraphicsGetImageFromCurrentImageContext();
    				UIGraphicsEndImageContext();
				}
			} else {
				undeleteImage = [UIImage imageWithContentsOfFile:@"/var/mobile/Library/Application Support/TFDidThatSay/eye160dark.png"];
			}

			CGFloat undeleteImageSizeValue = prevImageSize.width > prevImageSize.height ? prevImageSize.width : prevImageSize.height;

			if (undeleteImageSizeValue == 0) {
				undeleteImageSizeValue = 25;
			}

			UIGraphicsBeginImageContextWithOptions(CGSizeMake(undeleteImageSizeValue, undeleteImageSizeValue), NO, 0);
			[undeleteImage drawInRect:CGRectMake(0, 0, undeleteImageSizeValue, undeleteImageSizeValue)];
			undeleteImage = [UIGraphicsGetImageFromCurrentImageContext() imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
			UIGraphicsEndImageContext();

			UILabel *undeleteLabel = MSHookIvar<UILabel *>(undeleteCell, "actionTitleLabel");
			UIImageView *undeleteImageView = MSHookIvar<UIImageView *>(undeleteCell, "iconImageView");

			undeleteLabel.text = @"TF Did That Say?";
			undeleteImageView.image = undeleteImage;

			// fix undelete cell being green when moderator cell is present

			UIColor *contentColor = [UIColor colorWithRed:0.137 green:0.6 blue:1 alpha:1];
			[undeleteImageView setTintColor:contentColor];

			NSMutableAttributedString *newAttribuedText = [[NSMutableAttributedString alloc] initWithAttributedString:undeleteLabel.attributedText];
			[newAttribuedText addAttribute:NSForegroundColorAttributeName value:contentColor range:NSMakeRange(0, [newAttribuedText length])];
			undeleteLabel.attributedText = newAttribuedText;

			MSHookIvar<UIImageView *>(undeleteCell, "disclosureIndicator").image = nil;

			return undeleteCell;
		}
	}

	return %orig;
}

- (void)tableView:(id)arg1 didSelectRowAtIndexPath:(NSIndexPath *)arg2 {

	if (shouldAddUndeleteCell) {
		if ([arg2 row] == [self tableView:arg1 numberOfRowsInSection:0] - 1){

			if (apolloCommentCell) {
				[apolloCommentCell undeleteCellWasSelected];
			} else {
				[apolloCommentController undeleteCellWasSelected];
			}
		}
	}

	%orig;
}

- (NSInteger)tableView:(id)arg1 numberOfRowsInSection:(NSInteger)arg2 {

	if (shouldAddUndeleteCell){
		return %orig + 1;
	} else {
		return %orig;
	}
}

- (id)animationControllerForDismissedController:(id)arg1 {

	shouldAddUndeleteCell = NO;

	return %orig;
}

%end


%hook CommentCellNode
%property(strong,nonatomic) UIButton *undeleteButton;

- (void)moreOptionsTappedWithSender:(id)arg1 {

	if (!shouldApolloHaveButton){

		NSString *author = [MSHookIvar<RKComment *>(self, "comment") author];

		if ([%c(TFHelper) shouldShowUndeleteButtonWithInfo:author isDeletedOnly:isTFDeletedOnly]) {
			shouldAddUndeleteCell = YES;
			apolloCommentCell = self;
			apolloCommentController = nil;
		}
	}

	%orig;
}

- (void)longPressedWithGestureRecognizer:(id)arg1 {

	if (!shouldApolloHaveButton){

		NSString *author = [MSHookIvar<RKComment *>(self, "comment") author];

		if ([%c(TFHelper) shouldShowUndeleteButtonWithInfo:author isDeletedOnly:isTFDeletedOnly]) {
			shouldAddUndeleteCell = YES;
			apolloCommentCell = self;
			apolloCommentController = nil;
		}
	}

	%orig;
}

- (void)didLoad {
	%orig;

	if (shouldApolloHaveButton) {

		NSString *author = [MSHookIvar<RKComment *>(self, "comment") author];

		if ([%c(TFHelper) shouldShowUndeleteButtonWithInfo:author isDeletedOnly:isTFDeletedOnly]) {

			CGFloat imageSize = 20.0f;

			UIButton *undeleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
			[undeleteButton addTarget:self action:@selector(didTapUndeleteButton:) forControlEvents:UIControlEventTouchUpInside];
			undeleteButton.frame = CGRectMake(0, 0, imageSize, imageSize);

			UIImage* undeleteImage = [UIImage imageWithContentsOfFile:@"/var/mobile/Library/Application Support/TFDidThatSay/eye160dark.png"];
			[undeleteButton setImage:undeleteImage forState:UIControlStateNormal];

			[[self view] addSubview:undeleteButton];
			[self setUndeleteButton:undeleteButton];
		}
	} else {

		id actionDelegate = MSHookIvar<id>(self, "actionDelegate");
		[actionDelegate setCommentCellNode:self];

	}
}

- (void)_layoutSublayouts {
	%orig;

	if (shouldApolloHaveButton) {
		if ([self undeleteButton]) {

			CGFloat imageSize = 20.0f;

			id moreNode = MSHookIvar<id>(self, "moreOptionsNode");
			id ageNode = MSHookIvar<id>(self, "ageNode");

			CGRect nodeFrame = [moreNode frame];
			CGFloat centerHeight = (nodeFrame.size.height + nodeFrame.origin.y * 2) / 2.0f;
			CGFloat nodeSpacing = [ageNode frame].origin.x - nodeFrame.origin.x - nodeFrame.size.width;

			[[self undeleteButton] setFrame:CGRectMake(nodeFrame.origin.x - imageSize - nodeSpacing, centerHeight - (imageSize / 2), imageSize, imageSize)];
		}
	}
}

%new
- (void)didTapUndeleteButton:(id)sender {

	[sender setEnabled:NO];

	id comment = MSHookIvar<id>(self, "comment");

	[%c(TFHelper) getUndeleteDataWithID:[[comment fullName] componentsSeparatedByString:@"_"][1] isComment:YES timeout:pushshiftRequestTimeoutValue extraData:@{@"sender" : sender} completionTarget:self completionSelector:@selector(completeUndeleteCommentAction:)];
}

%new
- (void)undeleteCellWasSelected {

	RKComment *comment = MSHookIvar<RKComment *>(self, "comment");

	[%c(TFHelper) getUndeleteDataWithID:[[comment fullName] componentsSeparatedByString:@"_"][1] isComment:YES timeout:pushshiftRequestTimeoutValue extraData:nil completionTarget:self completionSelector:@selector(completeUndeleteCommentAction:)];
}

%new
- (void)completeUndeleteCommentAction:(NSDictionary *)data {

	RKComment *comment = MSHookIvar<RKComment *>(self, "comment");
	id bodyNode = MSHookIvar<id>(self, "bodyNode");
	id authorNode = MSHookIvar<id>(self, "authorNode");

	NSString *author = data[@"author"];
	NSString *body = data[@"body"];

	[comment setAuthor:author];
	[comment setBody:body];

	NSAttributedString *prevAuthorAttributedString = [authorNode attributedTitleForState:UIControlStateNormal];
	NSDictionary *authorStringAttributes = [prevAuthorAttributedString attributesAtIndex:0 longestEffectiveRange:nil inRange:NSMakeRange(0, [prevAuthorAttributedString length])];
	NSAttributedString *newAuthorAttributedString = [[NSAttributedString alloc] initWithString:author attributes:authorStringAttributes];

	[authorNode setAttributedTitle:newAuthorAttributedString forState:UIControlStateNormal];
	[bodyNode setAttributedString:[%c(MarkdownRenderer) attributedStringFromMarkdown:body withAttributes:apolloBodyAttributes]];

	if ([data objectForKey:@"sender"]) {
		[data[@"sender"] setEnabled:YES];
	}
}

%end


%hook CommentsViewController
%property(strong, nonatomic) id headerCellNode;

- (void)moreOptionsBarButtonItemTappedWithSender:(id)arg1 {

	RKLink *post = MSHookIvar<RKLink *>(self, "link");
	NSString *author = [post author];

	if ([post isSelfPost]) {
		if ([%c(TFHelper) shouldShowUndeleteButtonWithInfo:author isDeletedOnly:isTFDeletedOnly]) {
			shouldAddUndeleteCell = YES;
			apolloCommentCell = nil;
			apolloCommentController = self;
		}
	}

	%orig;
}

%new
- (void)undeleteCellWasSelected {

	RKLink *post = MSHookIvar<RKLink *>(self, "link");

	[%c(TFHelper) getUndeleteDataWithID:[[post fullName] componentsSeparatedByString:@"_"][1] isComment:NO timeout:pushshiftRequestTimeoutValue extraData:nil completionTarget:self completionSelector:@selector(completeUndeletePostAction:)];
}

%new
- (void)completeUndeletePostAction:(NSDictionary *)data {

	RKLink *post = MSHookIvar<RKLink *>(self, "link");

	id headerCellNode = [self headerCellNode];
	id bodyNode = MSHookIvar<id>(headerCellNode, "bodyNode");
	id postInfoNode = MSHookIvar<id>(headerCellNode, "postInfoNode");
	id authorNode = MSHookIvar<id>(postInfoNode, "authorButtonNode");

	NSString *author = data[@"author"];
	NSString *authorTextString = [NSString stringWithFormat:@"by %@", author];
	NSString *body = data[@"body"];

	[post setUndeleteAuthor:author];
	[post setSelfText:body];

	NSAttributedString *prevAuthorAttributedString = [authorNode attributedTitleForState:UIControlStateNormal];
	NSDictionary *authorStringAttributes = [prevAuthorAttributedString attributesAtIndex:0 longestEffectiveRange:nil inRange:NSMakeRange(0, [prevAuthorAttributedString length])];
	NSAttributedString* newAuthorAttributedString = [[NSAttributedString alloc] initWithString:authorTextString attributes:authorStringAttributes];

	[authorNode setAttributedTitle:newAuthorAttributedString forState:UIControlStateNormal];
	[bodyNode setAttributedString:[%c(MarkdownRenderer) attributedStringFromMarkdown:body withAttributes:apolloBodyAttributes]];
}

%end


%hook CommentsHeaderCellNode

- (void)didLoad {
	%orig;

	[[self closestViewController] setHeaderCellNode:self];
}

- (void)_layoutSublayouts {
	%orig;

	[[self closestViewController] setHeaderCellNode:self];
}

- (void)longPressedWithGestureRecognizer:(id)arg1 {

	RKLink *post = MSHookIvar<RKLink *>(self, "link");
	NSString *author = [post author];

	if ([post isSelfPost]) {
		if ([%c(TFHelper) shouldShowUndeleteButtonWithInfo:author isDeletedOnly:isTFDeletedOnly]){
			shouldAddUndeleteCell = YES;
			apolloCommentCell = nil;
			apolloCommentController = self;
		}
	}

	%orig;
}

%end


%hook UIMenu

- (id)menuByReplacingChildren:(id)arg5 {

	if (shouldAddUndeleteCellForContext) {

		UIAction *action = [UIAction actionWithTitle:@"TF Did That Say?" image:[UIImage systemImageNamed:@"eye"] identifier:@"testident" handler:^(__kindof UIAction* _Nonnull action) {

				id commentCell = apolloCommentCellForContext;
				id commentsController = apolloCommentsControllerForContext;

				if (commentCell) {
					[commentCell undeleteCellWasSelected];
				} else {
					[commentsController undeleteCellWasSelected];
				}
		}];

		arg5 = [arg5 arrayByAddingObject:action];
	}

	return %orig;
}

%end


%hook CommentSectionController
%property(strong, nonatomic) id commentCellNode;

- (id)contextMenuInteraction:(id)arg1 configurationForMenuAtLocation:(CGPoint)arg2 {

	if (!shouldApolloHaveButton) {

		NSString *author = [MSHookIvar<RKComment *>(self, "comment") author];

		if ([%c(TFHelper) shouldShowUndeleteButtonWithInfo:author isDeletedOnly:isTFDeletedOnly]) {
			shouldAddUndeleteCellForContext = YES;
			apolloCommentCellForContext = [self commentCellNode];
			apolloCommentsControllerForContext = nil;
		}
	}

	return %orig;
}

%new
- (void)contextMenuInteraction:(id)arg1 willEndForConfiguration:(id)arg2 animator:(id)arg3 {

	shouldAddUndeleteCellForContext = NO;
	apolloCommentCellForContext = nil;
	apolloCommentsControllerForContext = nil;
}

%end


%hook CommentsHeaderSectionController

- (id)contextMenuInteraction:(id)arg1 configurationForMenuAtLocation:(CGPoint)arg2 {

	id commentsController = MSHookIvar<id>(self, "viewController");

	RKLink *post = MSHookIvar<RKLink *>(commentsController, "link");
	NSString *author = [post author];

	if ([post isSelfPost]) {
		if ([%c(TFHelper) shouldShowUndeleteButtonWithInfo:author isDeletedOnly:isTFDeletedOnly]) {
			shouldAddUndeleteCellForContext = YES;
			apolloCommentCellForContext = nil;
			apolloCommentsControllerForContext = commentsController;
		}
	}

	return %orig;
}

%new
- (void)contextMenuInteraction:(id)arg1 willEndForConfiguration:(id)arg2 animator:(id)arg3 {

	shouldAddUndeleteCellForContext = NO;
	apolloCommentCellForContext = nil;
	apolloCommentsControllerForContext = nil;
}

%end

%end


static void loadPrefs(){
	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/User/Library/Preferences/com.lint.undelete.prefs.plist"];

	if (prefs){
		isEnabled = [prefs objectForKey:@"isEnabled"] ? [[prefs objectForKey:@"isEnabled"] boolValue] : YES;
		isApolloEnabled = [prefs objectForKey:@"isApolloEnabled"] ? [[prefs objectForKey:@"isApolloEnabled"] boolValue] : YES;
		isTFDeletedOnly = [prefs objectForKey:@"isTFDeletedOnly"] ? [[prefs objectForKey:@"isTFDeletedOnly"] boolValue] : YES;
		pushshiftRequestTimeoutValue = [prefs objectForKey:@"requestTimeoutValue"] ? [[prefs objectForKey:@"requestTimeoutValue"] doubleValue] : 10;
		shouldApolloHaveButton = [prefs objectForKey:@"shouldApolloHaveButton"] ? [[prefs objectForKey:@"shouldApolloHaveButton"] boolValue] : NO;
	} else {
		isEnabled = YES;
		isApolloEnabled = YES;
		isTFDeletedOnly = YES;
		pushshiftRequestTimeoutValue = 10;
		shouldApolloHaveButton = NO;
	}
}

static void prefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
  loadPrefs();
}


%ctor {

	loadPrefs();

	NSString* processName = [[NSProcessInfo processInfo] processName];

	if ([processName isEqualToString:@"Apollo"]){
		if (isApolloEnabled && isEnabled){

			CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)prefsChanged, CFSTR("com.lint.undelete.prefs.changed"), NULL, CFNotificationSuspensionBehaviorCoalesce);

			%init(Apollo, CommentsHeaderCellNode = objc_getClass("Apollo.CommentsHeaderCellNode"), CommentCellNode = objc_getClass("Apollo.CommentCellNode"), ApolloButtonNode = objc_getClass("Apollo.ApolloButtonNode"), ActionController = objc_getClass("Apollo.ActionController"), IconActionTableViewCell = objc_getClass("Apollo.IconActionTableViewCell"), CommentsViewController = objc_getClass("Apollo.CommentsViewController"), CommentSectionController = objc_getClass("Apollo.CommentSectionController"), CommentsHeaderSectionController = objc_getClass("Apollo.CommentsHeaderSectionController"));
		}
	}
}
