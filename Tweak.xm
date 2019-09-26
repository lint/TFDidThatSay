
#include "Tweak.h"

%group Redditv4

%hook CommentTreeNode
%property(assign,nonatomic)id commentTreeHeaderNode;
%property(assign,nonatomic)id commentTreeCommandBarNode;
%property(assign,nonatomic)BOOL isLoadingArchivedComment;
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
	[[self commentTreeNode] setIsLoadingArchivedComment:NO];
}
%end


/*
%hook ASCollectionView

-(id) dequeueReusableCellWithReuseIdentifier: (id) arg1 forIndexPath:(id) arg2{
	id orig = %orig;
	
	if ([orig isKindOfClass:[%c(_ASCollectionViewCell) class]]){
	
		id node = [[orig node] contentNode];
		
		if ([node isKindOfClass:[%c(CommentTreeDisplayNode) class]]) {
			id commentNode = [node commentNode];
			
			if ([commentNode isLoadingArchivedComment]){
			
				//[[[commentNode commentTreeCommandBarNode] activityIndicator] startAnimating];
			
			}
		}
	}
	return orig;
}
%end
*/


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
		
		[commentTreeNode setIsLoadingArchivedComment:YES];

		/*
		id isNightMode = [[[%c(AccountManager) sharedManager] defaults] objectForKey:@"kUseNightKey"];
		if (isNightMode){
			UIActivityIndicatorView* activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		} else {
			UIActivityIndicatorView* activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		}
		[self setActivityIndicator:activityIndicator];
		[activityIndicator startAnimating];
		[sender addSubview:activityIndicator];
		*/

		NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
		NSOperationQueue *queue = [[NSOperationQueue alloc] init];

		[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.pushshift.io/reddit/search/comment/?ids=%@&fields=author,body",[[comment pk] componentsSeparatedByString:@"_"][1]]]];
		[request setHTTPMethod:@"GET"];		

		[NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
		
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
			
			
			[commentTreeNode setIsLoadingArchivedComment:NO];
			//[activityIndicator stopAnimating];
			
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
					   
					author = [[jsonData objectForKey:@"data"][0] objectForKey:@"author"];
					body = [[jsonData objectForKey:@"data"][0] objectForKey:@"selftext"];
					   
					if ([body isEqualToString:@"[deleted]"] || [body isEqualToString:@"[removed]"]){
						body = @"[comment was unable to be archived]";
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
				
			
				[[[[self postActionSheetDelegate] controller] feedPostDetailCellNode] configureSelfTextNode];
				
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




%ctor{
	
	NSString* version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	NSArray* versionArray = [version componentsSeparatedByString:@"."];
		
	if ([versionArray[0] isEqualToString:@"4"]){
		%init(Redditv4);	
	} else if ([versionArray[0] isEqualToString:@"3"]) {
		
	}

}





