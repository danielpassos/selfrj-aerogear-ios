#import "AGTalkListViewController.h"
#import "AGPipeService.h"
#import "AGTalkFormViewController.h"

@implementation AGTalkListViewController {
    NSArray *_tasks;
}

- (id)init {
    self = [super init];
    if (self) {
        self.navigationItem.title = @"List of talks";

        UIBarButtonItem *buttonShowTalkForm = [[UIBarButtonItem alloc]
                initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                     target:self action:@selector(showTalkForm)];

        self.navigationItem.rightBarButtonItem = buttonShowTalkForm;
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[AGPipeService sharedInstance].talkPipe read:^(id responseObject) {
        _tasks = responseObject;

        // update table with the newly fetched data
        [self.tableView reloadData];

    }                                         failure:^(NSError *error) {
        NSLog(@"An error has occured during read! \n%@", error);
    }];

}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_tasks count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    NSUInteger row = [indexPath row];
    
    cell.textLabel.text = [[_tasks objectAtIndex:row] objectForKey:@"title"];
    
    return cell;
}

- (void)showTalkForm {
    AGTalkFormViewController *form = [[AGTalkFormViewController alloc] init];
    form.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:form];
    [self.navigationController presentModalViewController:nav animated:YES];
}

@end