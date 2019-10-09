
#import "Reddit.h"

%group Redditv4

%hook CommentTreeNode
%property(assign,nonatomic)id commentTreeHeaderNode;
%property(assign,nonatomic)id commentTreeCommandBarNode;
%end


%hook CommentTreeHeaderNode

-(void) didLoad{
	%orig;
	
	[[self commentTreeNode] setCommentTreeHeaderNode:self];
}
%end


%hook CommentTreeCommandBarNode
%property(assign,nonatomic) id activityIndicator;
%property(assign,nonatomic) id undeleteButton;

-(void) didLoad{
	%orig;

	[[self commentTreeNode] setCommentTreeCommandBarNode:self];
}
%end


%hook CommentActionSheetViewController

-(void) setItems:(id) arg1{

	UIImage* origImage = [UIImage imageWithContentsOfFile:@"/var/mobile/Library/Application Support/TFDidThatSay/eye160dark.png"];

	CGSize existingImageSize = [[arg1[0] leftIconImage] size];
	CGFloat scale = origImage.size.width / existingImageSize.width;

	UIImage *newImage = [UIImage imageWithCGImage:[origImage CGImage] scale:scale orientation:origImage.imageOrientation];

	id undeleteItem = [[%c(RUIActionSheetItem) alloc] initWithLeftIconImage:newImage text:@"TF did that say?" identifier:@"undeleteItemIdentifier" context:[self comment]];

	%orig([arg1 arrayByAddingObject:undeleteItem]);
	
	[undeleteItem release];

}

-(void) handleDidSelectActionSheetItem:(id) arg1{
	%orig;
	
	if ([[arg1 identifier] isEqualToString:@"undeleteItemIdentifier"]){
		
		[self dismissViewControllerAnimated:YES completion:nil];	
		
		id commentTreeNode = [self commentTreeNode];
		id comment = [commentTreeNode  comment];

		NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
		NSOperationQueue *queue = [[NSOperationQueue alloc] init];

		[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.pushshift.io/reddit/search/comment/?ids=%@&fields=author,body",[[comment pk] componentsSeparatedByString:@"_"][1]]]];
		[request setHTTPMethod:@"GET"];		

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
				body = @"[an error occured]";
			}

			id themeManager  = [[%c(ThemeManager) alloc] initWithTraitCollection:nil appSettings:[%c(AppSettings) sharedSettings]];
			id isNightMode = [[[%c(AccountManager) sharedManager] defaults] objectForKey:@"kUseNightKey"];
			id textColor;
			
			if (isNightMode) {
				textColor = [[themeManager nightTheme] bodyTextColor];
			} else{
				textColor = [[themeManager dayTheme] bodyTextColor];
			}
			
			NSMutableAttributedString *bodyMutableAttributedText = [[NSMutableAttributedString alloc] initWithAttributedString:[%c(NSAttributedStringMarkdownParser) attributedStringUsingCurrentConfig:body]];

			[bodyMutableAttributedText beginEditing];
			[bodyMutableAttributedText enumerateAttribute:NSForegroundColorAttributeName inRange:NSMakeRange(0, bodyMutableAttributedText.length) options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
				[bodyMutableAttributedText removeAttribute:NSForegroundColorAttributeName range:range]; 
				[bodyMutableAttributedText addAttribute:NSForegroundColorAttributeName value:textColor range:range];
			}];
			[bodyMutableAttributedText endEditing];
			

			[comment setValue:bodyMutableAttributedText forKey:@"bodyRichTextAttributed"];

			[comment setValue:author forKey:@"author"];
			[comment setValue:body forKey:@"bodyText"];

			[comment setValue:bodyMutableAttributedText forKey:@"bodyAttributedText"];
			
			[[commentTreeNode commentTreeHeaderNode] updateContentViewsForData:comment];

			[request release];
			[queue release];
			[bodyMutableAttributedText release];
			[themeManager release];
		}];	
	}
}
%end


%hook PostDetailViewController
%property(assign,nonatomic) id feedPostTextWithThumbnailNode;
%property(assign,nonatomic) id feedPostDetailCellNode;
%end


%hook FeedPostDetailCellNode

-(void) didLoad{
	%orig;
	
	[[[self delegate] viewController] setFeedPostDetailCellNode:self];
}
%end


%hook PostActionSheetViewController

-(void) setItems:(id) arg1{
	
	id post = [self post];
	
	if ([post isSelfPost]){

		UIImage* origImage = [UIImage imageWithContentsOfFile:@"/var/mobile/Library/Application Support/TFDidThatSay/eye160dark.png"];

		CGSize existingImageSize = [[arg1[0] leftIconImage] size];
		CGFloat scale = origImage.size.width / existingImageSize.width;

		UIImage *newImage = [UIImage imageWithCGImage:[origImage CGImage] scale:scale orientation:origImage.imageOrientation];

		id undeleteItem = [[%c(RUIActionSheetItem) alloc] initWithLeftIconImage:newImage text:@"TF did that say?" identifier:@"undeleteItemIdentifier" context:[self post]];

		arg1 = [arg1 arrayByAddingObject:undeleteItem];
		
		[undeleteItem release];
	}
	
	%orig;
}


-(void) handleDidSelectActionSheetItem:(id) arg1{
	%orig;
	
	if ([[arg1 identifier] isEqualToString:@"undeleteItemIdentifier"]){
		
		[self dismissViewControllerAnimated:YES completion:nil];
		
		id post = [self post];
		
		if ([post isSelfPost]){
			
			NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
			NSOperationQueue *queue = [[NSOperationQueue alloc] init];

			[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.pushshift.io/reddit/search/submission/?ids=%@&fields=author,selftext",[[post pk] componentsSeparatedByString:@"_"][1]]]];
			[request setHTTPMethod:@"GET"];		

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
					body = @"[an error occured]";
				}
				
				id themeManager  = [[%c(ThemeManager) alloc] initWithTraitCollection:nil appSettings:[%c(AppSettings) sharedSettings]];
				id isNightMode = [[[%c(AccountManager) sharedManager] defaults] objectForKey:@"kUseNightKey"];
				id textColor;
				
				if (isNightMode) {
					textColor = [[themeManager nightTheme] bodyTextColor];
				} else{
					textColor = [[themeManager dayTheme] bodyTextColor];
				}

				NSMutableAttributedString *bodyMutableAttributedText = [[NSMutableAttributedString alloc] initWithAttributedString:[%c(NSAttributedStringMarkdownParser) attributedStringUsingCurrentConfig:body]];

				[bodyMutableAttributedText beginEditing];
				[bodyMutableAttributedText enumerateAttribute:NSForegroundColorAttributeName inRange:NSMakeRange(0, bodyMutableAttributedText.length) options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
					[bodyMutableAttributedText removeAttribute:NSForegroundColorAttributeName range:range]; 
					[bodyMutableAttributedText addAttribute:NSForegroundColorAttributeName value:textColor range:range];
				}];
				[bodyMutableAttributedText endEditing];

				[post setValue:bodyMutableAttributedText forKey:@"selfPostRichTextAttributed"];
				[post setValue:bodyMutableAttributedText forKey:@"previewFeedPostTextString"];
				[post setAuthor:author];
				[post setValue:body forKey:@"selfText"];
				
				if ([[[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] componentsSeparatedByString:@"."][1] integerValue] >= 44){
					[[[[[self postActionSheetDelegate] controller] feedPostDetailCellNode] contentNode] configureSelfTextNode];
				} else {
					[[[[self postActionSheetDelegate] controller] feedPostDetailCellNode] configureSelfTextNode];
				}
							
				[request release];
				[queue release];
				[bodyMutableAttributedText release];
				[themeManager release];
			}];			
		}	
	}
}
%end

%end



%group Redditv3

%hook CommentView

%new
-(void) buttonAction {

	id commentsViewController = [self delegate];
	id comment = [self comment];

	NSError* error;

	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.pushshift.io/reddit/search/comment/?ids=%@&fields=author,body",[comment pkWithoutPrefix]]]];
	[request setHTTPMethod:@"GET"];

	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];

	NSString *author = @"[author]";
	NSString *body = @"[body]";

	if (data != nil && error == nil){
		
		id jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
		   
		author = [[jsonData objectForKey:@"data"][0] objectForKey:@"author"];
		body = [[jsonData objectForKey:@"data"][0] objectForKey:@"body"];
		   
		if ([body isEqualToString:@"[deleted]"] || [body isEqualToString:@"[removed]"]){
			body = @"[comment was unable to be archived]";
		}
		
	} else if (error != nil || data == nil){
		body = @"[an error occured]";
	}

	[comment setValue:author forKey:@"author"];

	[comment setValue:[%c(MarkDownParser) attributedStringFromMarkdownString: body] forKey:@"bodyAttributedText"];
	[comment setValue:body forKey:@"bodyText"];

	[commentsViewController reloadCommentsWithNewCommentsHighlight:NO autoScroll:NO animated:NO];

}


-(id) initWithFrame:(id)arg1{
	id orig = %orig;
	id commandView = [self commandView];

	UIButton *undeleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[undeleteButton addTarget:self action:@selector(buttonAction) forControlEvents:UIControlEventTouchUpInside];

	UIImage* undeleteImage = [UIImage imageWithContentsOfFile:@"/var/mobile/Library/Application Support/TFDidThatSay/eye160dark.png"];
	
	[undeleteButton setImage:undeleteImage forState:UIControlStateNormal];

	[commandView setUndeleteButton:undeleteButton];
	[commandView addSubview:undeleteButton];

	return orig;
}


%end


%hook CommentCommandView
%property (assign, nonatomic) id undeleteButton;

-(void) layoutSubviews{
	%orig;

	UIButton *button = [self undeleteButton];

	button.frame = CGRectMake([[self overflowButton ] frame].origin.x - 32, 0, 32, 32);

}
%end

%end




%ctor{
	
	NSString* processName = [[NSProcessInfo processInfo] processName];
	NSString* version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	NSArray* versionArray = [version componentsSeparatedByString:@"."];
	
	if ([processName isEqualToString:@"Reddit"]){			
		if ([versionArray[0] isEqualToString:@"4"]){
			%init(Redditv4);	
		} else if ([versionArray[0] isEqualToString:@"3"]) {
			%init(Redditv3);
		}
	}
}





