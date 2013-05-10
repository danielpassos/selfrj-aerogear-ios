#import "AGPipeService.h"

static NSString * const baseURL = @"http://10.10.10.4:3000";

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
        
        // create the Pipeline object pointing to the remote application
        AGPipeline *pipeline = [AGPipeline pipelineWithBaseURL:[NSURL URLWithString:baseURL]];
        
        // once pipeline is constructed setup the pipes that will
        // point to the remote application REST endpoints
        _talkPipe = [pipeline pipe:^(id<AGPipeConfig> config) {
            [config setName:@"talks"];
            [config setEndpoint:@"ag"];
        }];
        // ...any other pipes
    }

    return self;
}
@end
