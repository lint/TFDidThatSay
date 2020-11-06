
#import "TFHelper.h"

@implementation TFHelper

+ (void)getUndeleteDataWithID:(NSString *)ident isComment:(BOOL)isComment timeout:(CGFloat)timeout extraData:(NSDictionary *)extra completionTarget:(id)target completionSelector:(SEL)sel {

	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	//NSOperationQueue *queue = [[NSOperationQueue alloc] init];

	if (isComment){
		[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.pushshift.io/reddit/search/comment/?ids=%@&fields=author,body", ident]]];
	} else {
		[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.pushshift.io/reddit/search/submission/?ids=%@&fields=author,selftext", ident]]];
	}

	[request setHTTPMethod:@"GET"];
	[request setTimeoutInterval:timeout];

	NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
	//[NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {

		NSString *author = @"[author]";
		NSString *body = @"[body]";

		if (data) {
			id jsonData = [[NSJSONSerialization JSONObjectWithData:data options:0 error:&error] objectForKey:@"data"];
			if (jsonData && [jsonData count] != 0) {
				author = [jsonData[0] objectForKey:@"author"];
				body = isComment ? [jsonData[0] objectForKey:@"body"] : [jsonData[0] objectForKey:@"selftext"];
				if ([body isEqualToString:@"[deleted]"] || [body isEqualToString:@"[removed]"]){
					body = [NSString stringWithFormat:@"[pushshift was unable to archive this %@]", isComment ? @"comment" : @"post"];
				}
			} else {
				body = [NSString stringWithFormat:@"[no data for this %@ was returned by pushshift]", isComment ? @"comment" : @"post"];
			}
		}

		if (error) {
			body = [NSString stringWithFormat:@"[an error occurred while attempting retrieve data from the pushshift api]\n\nHTTP Status Code: %li\n\nError Description: %@",
			(long)((NSHTTPURLResponse *)response).statusCode, [error localizedDescription]];
		}

		NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:@{@"author" : author, @"body" : body}];

		if (extra){
			[result addEntriesFromDictionary:extra];
		}

		[target performSelectorOnMainThread:sel withObject:result waitUntilDone:NO];
	}];
	[dataTask resume];
}

+ (BOOL)shouldShowUndeleteButtonWithInfo:(NSString *) content isDeletedOnly:(BOOL) isDeletedOnly{

	if (!isDeletedOnly){
		return YES;
	} else {
		if ([content isEqualToString:@"[deleted]"] || [content isEqualToString:@"[removed]"]){
			return YES;
		} else if ([content hasPrefix:@"[pushshift"] || [content hasPrefix:@"[an error occured"]){
			return YES;
		}
	}

	return NO;
}

@end
