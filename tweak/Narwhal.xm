
#import "Narwhal.h"

%group Narwhal

UIAlertController* recreateActionSheet(id controller, id comment, NSInteger commentIndex){
	
	UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:nil];
	
	UIAlertAction* pmAction = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"private message %@", [comment author]] style:nil handler:^(UIAlertAction* action){[controller _handleActionSheetPrivateMessage:comment];}];
	UIAlertAction* viewProfileAction = [UIAlertAction actionWithTitle:@"view profile" style:nil handler:^(UIAlertAction* action){[controller _handleActionSheetViewProfile:comment];}];
	UIAlertAction* shareAction = [UIAlertAction actionWithTitle:@"share comment" style:nil handler:^(UIAlertAction* action){[controller _handleActionSheetShareComment:comment];}];
	UIAlertAction* copyAction = [UIAlertAction actionWithTitle:@"copy text" style:nil handler:^(UIAlertAction* action){[controller _handleActionSheetCopyCommentText:comment];}];
	UIAlertAction* reportAction = [UIAlertAction actionWithTitle:@"report comment" style:nil handler:^(UIAlertAction* action){[controller _handleActionSheetReportComment:comment];}];
	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:nil];
	
	[alert addAction:pmAction];
	[alert addAction:viewProfileAction];
	[alert addAction:shareAction];
	[alert addAction:copyAction];
	
	if ([comment isSaved]){
		UIAlertAction* unsaveAction = [UIAlertAction actionWithTitle:@"unsave comment" style:nil handler:^(UIAlertAction* action){[controller _handleActionSheetUnsaveComment:comment index:commentIndex];}];
		[alert addAction:unsaveAction];
		
	} else {
		UIAlertAction* saveAction = [UIAlertAction actionWithTitle:@"save comment" style:nil handler:^(UIAlertAction* action){[controller _handleActionSheetSaveComment:comment index:commentIndex];}];
		[alert addAction:saveAction];
	}
	
	if ([[[comment parentID] componentsSeparatedByString:@"_"][0] isEqualToString:@"t1"]){
		UIAlertAction* viewParentAction = [UIAlertAction actionWithTitle:@"view parent" style: nil handler:^(UIAlertAction* action){[controller _handleActionSheetViewParent:comment];}];
		[alert addAction:viewParentAction];
	}
	
	if ([[comment author] isEqualToString:[[%c(NRTAuthManager) sharedManager] currentUsername]]) {
		UIAlertAction* editAction = [UIAlertAction actionWithTitle:@"edit comment" style:nil handler:^(UIAlertAction* action){[controller _handleActionSheetEditComment:comment];}];
		UIAlertAction* deleteAction = [UIAlertAction actionWithTitle:@"delete comment" style:nil handler:^(UIAlertAction* action){[controller _handleActionSheetDeleteComment:comment];}];
		
		[alert addAction:editAction];
		[alert addAction:deleteAction];
	}
	
	[alert addAction:reportAction];
	[alert addAction:cancelAction];
		
	UIAlertAction* undeleteAction = [UIAlertAction actionWithTitle:@"tf did that say?" style:nil handler:^(UIAlertAction* action){[controller handleUndeleteCommentAction:comment];}];
	[alert addAction:undeleteAction];
	
	return alert;
}

void getUndeleteCommentData(id controller, id comment){
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	NSOperationQueue *queue = [[NSOperationQueue alloc] init];

	[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.pushshift.io/reddit/search/comment/?ids=%@&fields=author,body",[[comment fullName] componentsSeparatedByString:@"_"][1]]]];
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
				if (!body){
					body = @"[wtf]";
				}
				if (!author){
					author = @"[wtf]";
				}
			} else {
				body = @"[pushshift has not archived this yet]";
			}
		} else if (error != nil || data == nil){
			body = @"[an error occured]";
		}
		
		[controller performSelectorOnMainThread:@selector(completeUndeleteComment:) withObject:@{@"body":body, @"author":author, @"comment":comment} waitUntilDone:NO];
	}];
	
}


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
-(void) handleUndeleteCommentAction:(id) comment{
	getUndeleteCommentData(self, comment);
}

%new
-(void) handleUndeletePostAction{
	
	id post = [self link];
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	NSOperationQueue *queue = [[NSOperationQueue alloc] init];

	[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.pushshift.io/reddit/search/submission/?ids=%@&fields=author,selftext",[[post fullName] componentsSeparatedByString:@"_"][1]]]];
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
		
		[self performSelectorOnMainThread:@selector(completeUndeletePost:) withObject:@{@"body":body, @"author":author, @"post":post} waitUntilDone:NO];
		
	}];
	
	
}

-(void) swipeCell:(id) arg1 didEndDragWithState:(NSUInteger) arg2{

	if (arg2 == 2){
		
		if ([arg1 isKindOfClass:[%c(NRTCommentTableViewCell) class]]) {
		
			id comment = [arg1 comment];
			NSInteger commentIndex = [[[self commentsManager] comments] indexOfObject:comment];
			
			UIAlertController* alert = recreateActionSheet(self, comment, commentIndex);			
			
			[self presentViewController:alert animated:YES completion:nil];
		
		} else {
			%orig;
		}
	} else {
		%orig;
	}
}


-(void) _dotsButtonTouched:(id) arg1{
	
	id post = [self link];
	BOOL shouldHaveUndeleteAction = NO;
	
	UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:nil];
	
	UIAlertAction* undeletePostAction;
	
	UIAlertAction* sharePostAction = [UIAlertAction actionWithTitle:@"share reddit post" style:nil handler:^(UIAlertAction* action){[self _handleActionSheetSharePost];}];
	UIAlertAction* sortCommentsAction = [UIAlertAction actionWithTitle:@"sort comments" style:nil handler:^(UIAlertAction* action){[self _handleActionSheetSortComments];}];
	UIAlertAction* refreshCommentsAction = [UIAlertAction actionWithTitle:@"refresh comments" style:nil handler:^(UIAlertAction* action){[self _handleActionSheetRefreshComments];}];
	UIAlertAction* reportPostAction = [UIAlertAction actionWithTitle:@"report post" style:nil handler:^(UIAlertAction* action){[self _handleActionSheetReportPost];}];
	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:nil];
	
	[alert addAction:sharePostAction];
	[alert addAction:sortCommentsAction];
	[alert addAction:refreshCommentsAction];
	
	if ([self linkTextOffscreenCell]){
		UIAlertAction* refreshPostAction = [UIAlertAction actionWithTitle:@"refresh post" style:nil handler:^(UIAlertAction* action){[self _handleActionSheetRefreshPost];}];
		[alert addAction:refreshPostAction];
		
		undeletePostAction = [UIAlertAction actionWithTitle:@"tf did that say?" style:nil handler:^(UIAlertAction* action){[self handleUndeletePostAction];}];
		shouldHaveUndeleteAction = YES;
	}
	
	if ([[post author] isEqualToString:[[%c(NRTAuthManager) sharedManager] currentUsername]]){
		UIAlertAction* editPostAction = [UIAlertAction actionWithTitle:@"edit post" style:nil handler:^(UIAlertAction* action){[self _handleActionSheetEditPost];}];
		UIAlertAction* deletePostAction = [UIAlertAction actionWithTitle:@"delete post" style:nil handler:^(UIAlertAction* action){[self _handleActionSheetDeletePost];}];
		
		[alert addAction:editPostAction];
		[alert addAction:deletePostAction];
	}
	
	[alert addAction:reportPostAction];
	[alert addAction:cancelAction];
	
	if (shouldHaveUndeleteAction){
		[alert addAction:undeletePostAction];
	}
	
	[self presentViewController:alert animated:YES completion:nil];
	
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

%new
-(void) handleUndeleteCommentAction:(id) comment{
	getUndeleteCommentData(self, comment);
}

-(void) swipeCell:(id) arg1 didEndDragWithState:(NSUInteger) arg2{

	if (arg2 == 2){
		
		if ([arg1 isKindOfClass:[%c(NRTCommentTableViewCell) class]]) {
		
			id comment = [arg1 comment];
			NSInteger commentIndex = [[[self commentsManager] comments] indexOfObject:comment];
			
			UIAlertController* alert = recreateActionSheet(self, comment, commentIndex);	
			
			[[self parentController]  presentViewController:alert animated:YES completion:nil];
		
		} else {
			%orig;
		}
	} else {
		%orig;
	}
}

%end

%end

%ctor {
	NSString* processName = [[NSProcessInfo processInfo] processName];

	if ([processName isEqualToString:@"narwhal"]){			
		%init(Narwhal);
	}
}

