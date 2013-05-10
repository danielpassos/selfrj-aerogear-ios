#import "AeroGear.h"

@interface AGPipeService : NSObject

@property(readonly, nonatomic) id<AGPipe> talkPipe;

+ (AGPipeService *)sharedInstance;

@end
