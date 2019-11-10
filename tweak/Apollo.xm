
#import <Cephei/HBPreferences.h>
#import "Apollo.h"

HBPreferences *apolloPrefs;
BOOL isApolloDeletedCommentsOnly;
CGFloat apolloRequestTimeoutValue;

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

%new
-(void) didTapUndeleteButton:(id) sender{
	
	[sender setEnabled:NO];

	id bodyNode = MSHookIvar<id>(self, "bodyNode");
	id authorNode = MSHookIvar<id>(self, "authorNode");
	id authorTextNode = [authorNode subnodes][0];
	id comment = MSHookIvar<id>(self, "comment");

	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	NSOperationQueue *queue = [[NSOperationQueue alloc] init];

	[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.pushshift.io/reddit/search/comment/?ids=%@&fields=author,body",[[comment fullName] componentsSeparatedByString:@"_"][1]]]];
	[request setHTTPMethod:@"GET"];
	[request setTimeoutInterval:[apolloPrefs doubleForKey:@"requestTimeoutValue" default:10]];

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
		
		id prevAuthorAttributedString = [authorTextNode attributedString];
		NSDictionary *authorStringAttributes = [prevAuthorAttributedString attributesAtIndex:0 longestEffectiveRange:nil inRange:NSMakeRange(0, [prevAuthorAttributedString length])];
		NSAttributedString* newAuthorAttributedString = [[NSAttributedString alloc] initWithString:author attributes:authorStringAttributes];

		[authorTextNode setAttributedText:newAuthorAttributedString];
		[authorTextNode setAttributedString:newAuthorAttributedString];
		
		[comment setAuthor:author];
		
		[bodyNode setAttributedString:[%c(MarkdownRenderer) attributedStringFromMarkdown:body withAttributes:apolloBodyAttributes]];
		
		[sender setEnabled:YES];
		
	}];
}

-(void) didLoad {
	%orig;
	
	id commentBody = [MSHookIvar<id>(self, "comment") body];
	
	BOOL isDeletedOnly = [apolloPrefs boolForKey:@"isApolloDeletedCommentsOnly"];
	
	if ((isDeletedOnly && ([commentBody isEqualToString:@"[deleted]"] || [commentBody isEqualToString:@"[removed]"])) || !isDeletedOnly) {
	
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

%end


%hook ApolloCommentsHeaderCellNode
%property(strong, nonatomic) id undeleteButton;

%new
-(void) didTapUndeleteButton:(id) sender{
	
	[sender setEnabled:NO];

	id bodyNode = MSHookIvar<id>(self, "bodyNode");
	id postInfoNode = MSHookIvar<id>(self, "postInfoNode");
	id authorNode = MSHookIvar<id>(postInfoNode, "authorButtonNode");
	id authorTextNode = [authorNode subnodes][0];
	id post = MSHookIvar<id>(self, "link");

	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	NSOperationQueue *queue = [[NSOperationQueue alloc] init];

	[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.pushshift.io/reddit/search/submission/?ids=%@&fields=author,selftext",[[post fullName] componentsSeparatedByString:@"_"][1]]]];
	[request setHTTPMethod:@"GET"];
	[request setTimeoutInterval:[apolloPrefs doubleForKey:@"requestTimeoutValue" default:10]];

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
		
		//MSHookIvar<NSString*>(post, "_author") = author; //Crashes when clicking on author name. You will have to search the author name to go find the profile.

		author = [NSString stringWithFormat:@"by %@", author];

		id prevAuthorAttributedString = [authorTextNode attributedString];
		NSDictionary *authorStringAttributes = [prevAuthorAttributedString attributesAtIndex:0 longestEffectiveRange:nil inRange:NSMakeRange(0, [prevAuthorAttributedString length])];
		NSAttributedString* newAuthorAttributedString = [[NSAttributedString alloc] initWithString:author attributes:authorStringAttributes];

		[authorTextNode setAttributedText:newAuthorAttributedString];
		[authorTextNode setAttributedString:newAuthorAttributedString];
		
		[bodyNode setAttributedString:[%c(MarkdownRenderer) attributedStringFromMarkdown:body withAttributes:apolloBodyAttributes]];
		
		[sender setEnabled:YES];
		
	}];
	
}

-(void) didLoad{
	%orig;

	if ([MSHookIvar<id>(self, "link") isSelfPost]){
		
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
%end

%end


%ctor {
	
	apolloPrefs = [[HBPreferences alloc] initWithIdentifier:@"com.lint.undelete.prefs"];
	[apolloPrefs registerBool:&isApolloDeletedCommentsOnly default:YES forKey:@"isApolloDeletedCommentsOnly"];
	[apolloPrefs registerDouble:&apolloRequestTimeoutValue default:10 forKey:@"requestTimeoutValue"];
	
	NSString* processName = [[NSProcessInfo processInfo] processName];
	
	if ([processName isEqualToString:@"Apollo"]){
		%init(Apollo, ApolloCommentsHeaderCellNode = objc_getClass("Apollo.CommentsHeaderCellNode"), ApolloCommentCellNode = objc_getClass("Apollo.CommentCellNode"), ApolloApolloButtonNode = objc_getClass("Apollo.ApolloButtonNode"));
	}
}
