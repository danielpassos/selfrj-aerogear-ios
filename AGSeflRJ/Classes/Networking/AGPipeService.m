#import "AGPipeService.h"

static NSString * const baseURL = @"http://localhost:3000";

@implementation AGPipeService

@synthesize talkPipe = _talkPipe;

+ (AGPipeService *)sharedInstance {
    static AGPipeService *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] initWithBaseURL:[NSURL URLWithString:baseURL]];
    });
    
    return _sharedInstance;
}

- (id)initWithBaseURL:(NSURL *)url {
     if (self = [super init]) {
        
        AGPipeline *pipeline = [AGPipeline pipelineWithBaseURL:[NSURL URLWithString:baseURL]];
        
        _talkPipe = [pipeline pipe:^(id<AGPipeConfig> config) {
            [config setName:@"talks"];
            [config setEndpoint:@"ag"];
        }];
        // ...any other pipes
    }

    return self;
}
@end
