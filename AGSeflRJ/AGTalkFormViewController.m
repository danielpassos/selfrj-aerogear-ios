#import "AGTalkFormViewController.h"
#import "AGPipeService.h"

@interface AGTalkFormViewController ()

@end

@implementation AGTalkFormViewController

- (id)init {
    self = [super init];
    if (self) {
        self.navigationItem.title = @"Talk";

        UIBarButtonItem *buttonCancel = [[UIBarButtonItem alloc]
                initWithTitle:@"Cancel"
                        style:UIBarButtonItemStylePlain
                       target:self
                       action:@selector(hideTalkForm)];

        self.navigationItem.leftBarButtonItem = buttonCancel;

        UIBarButtonItem *buttonSave = [[UIBarButtonItem alloc]
                initWithTitle:@"Save"
                        style:UIBarButtonItemStylePlain
                       target:self
                       action:@selector(saveTalk)];
        self.navigationItem.rightBarButtonItem = buttonSave;

    }

    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) hideTalkForm {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)saveTalk {



}

@end
