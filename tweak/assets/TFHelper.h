
@interface TFHelper : NSObject

+(void) getUndeleteDataWithID:(NSString *) ident isComment:(BOOL) isComment timeout:(CGFloat) timeout extraData:(NSDictionary *) extra completionTarget:(id) target completionSelector:(SEL) sel;

@end
