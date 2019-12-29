
#import "TFHelper.h"

@implementation TFHelper

+(void) getUndeleteDataWithID:(NSString *) ident isComment:(BOOL) isComment timeout:(CGFloat) timeout extraData:(NSDictionary *) extra completionTarget:(id) target completionSelector:(SEL) sel{

	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	NSOperationQueue *queue = [[NSOperationQueue alloc] init];
	
	if (isComment){
		[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.pushshift.io/reddit/search/comment/?ids=%@&fields=author,body", ident]]];
	} else {
		[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.pushshift.io/reddit/search/submission/?ids=%@&fields=author,selftext", ident]]];
	}
	
	[request setHTTPMethod:@"GET"];
	[request setTimeoutInterval:timeout];

	[NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
	
		NSString *author = @"[author]";
		NSString *body = @"[body]";

		if (data != nil && error == nil){
			id jsonData = [[NSJSONSerialization JSONObjectWithData:data options:0 error:&error] objectForKey:@"data"];
			if ([jsonData count] != 0){
				author = [jsonData[0] objectForKey:@"author"];
				body = isComment ? [jsonData[0] objectForKey:@"body"] : [jsonData[0] objectForKey:@"selftext"];
				if ([body isEqualToString:@"[deleted]"] || [body isEqualToString:@"[removed]"]){
					body = @"[pushshift was unable to archive this]";
				}
			} else {
				body = @"[pushshift has not archived this yet]";
			}
		} else if (error != nil || data == nil){
			body = [NSString stringWithFormat:@"[an error occured while attempting to contact pushshift api (%@)]", [error localizedDescription]];
		}
		
		NSMutableDictionary *result =  [@{@"author" : author, @"body" : body} mutableCopy];
		
		if (extra){
			[result addEntriesFromDictionary:extra];
		}
		
		[target performSelectorOnMainThread:sel withObject:result waitUntilDone:NO];
	}];
}

@end