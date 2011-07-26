//
//  FloorUpdateViewController.m
//  RealTimeCongress
//
//  Created by Stephen Searles on 6/4/11.
//  Copyright 2011 Sunlight Labs. All rights reserved.
//

#import "FloorUpdateViewController.h"
#import "FloorUpdate.h"
#import "SunlightLabsRequest.h"
#import "GANTracker.h"

@interface NSString (CancelRequest)

- (void)cancelRequest;

@end

@implementation NSString (CancelRequest)

- (void)cancelRequest {
    
}

@end

@implementation FloorUpdateViewController

@synthesize control;
@synthesize floorUpdatesTableView;

- (void)dealloc
{
    [control release];
    [floorUpdates release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)receiveFloorUpdate:(NSNotification *)notification {
    [connection release];
    connection = nil;
    NSDictionary * userInfo = [notification userInfo];
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    NSDateFormatter *updateDayFomatter = [[NSDateFormatter alloc] init];
    [updateDayFomatter setDateFormat:@"EEEE, MMMM dd"];
    NSMutableString * floorUpdateText = [NSMutableString stringWithCapacity:100];
    
    for (id update in [userInfo objectForKey:@"floor_updates"]) {
        NSDate * date = [dateFormatter dateFromString:[update objectForKey:@"timestamp"]];
        for (id str in [update objectForKey:@"events"]) {
            str = [str stringByReplacingOccurrencesOfString:@"\n" withString:@""];
            [floorUpdateText appendFormat:@"%@",str];
        }
        if (control.selectedSegmentIndex == 1) {
            NSString *prependString = [NSString stringWithFormat: @"Spoke: Senator %@", floorUpdateText];
            [floorUpdateText setString:prependString];
        }
        FloorUpdate * floorUpdate = [[[FloorUpdate alloc] initWithDisplayText:floorUpdateText atDate:date] autorelease];
        
        // Check if the date has been added to update days array. Add it if it hasn't.
        NSString *updateDay = [updateDayFomatter stringFromDate:[floorUpdate date]];
        if (![updateDays containsObject: updateDay]) {
            [updateDays addObject:updateDay];
        }

        // Check if there is an array for the update day. If there isn't, create an array to store updates for that day. 
        if ([updateDayDictionary objectForKey:updateDay] == nil) {
            [updateDayDictionary setObject:[NSMutableArray array] forKey:updateDay];
            // Add the update to its respective array
            [[updateDayDictionary objectForKey:updateDay] addObject:floorUpdate];
        }
        else {
            // Add the update to its respective array if it already exists
            [[updateDayDictionary objectForKey:updateDay] addObject:floorUpdate];
        }
        
        [floorUpdateText setString:@""];
    }
    
    id last = [[floorUpdates lastObject] retain];
    [floorUpdates removeObject:[floorUpdates lastObject]];
    [floorUpdates removeAllObjects];
    
    for (NSString *updateDayString in updateDays) {
        [floorUpdates addObject:[updateDayDictionary objectForKey:updateDayString]];
    }
    
    [floorUpdates addObject:last];
    [last release];
    [self.floorUpdatesTableView reloadData];
}

- (void)refresh {
    //Track page view based on selected chamber control button
    NSError *error;
    if (control.selectedSegmentIndex == 0) {
        //Register a page view to the Google Analytics tracker
        if (![[GANTracker sharedTracker] trackPageview:@"/floor-updates/house"
                                             withError:&error]) {
            // Handle error here
        }
    }
    
    else {
        //Register a page view to the Google Analytics tracker
        if (![[GANTracker sharedTracker] trackPageview:@"/floor-updates/senate"
                                             withError:&error]) {
            // Handle error here
        }
    }
    page = 0;
    if (connection) {
        [connection cancel];
        [connection release];
    }
    //[floorUpdates makeObjectsPerformSelector:@selector(cancelRequest)];
    for (id obj in floorUpdates) {
        if (obj != @"LoadingRow") {
            [obj makeObjectsPerformSelector:@selector(cancelRequest)];
        }
    }
    [floorUpdates removeAllObjects];
    [updateDays removeAllObjects];
    [floorUpdates addObject:@"LoadingRow"];
    [self.floorUpdatesTableView reloadData];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationItem.title = @"Floor Updates";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh)];
    [control addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    page = 0;
    self.floorUpdatesTableView.allowsSelection = NO;
    if (!floorUpdates) {
        floorUpdates = [[NSMutableArray alloc] initWithCapacity:20];
        [floorUpdates addObject:@"LoadingRow"];
    }
    
    //Array to keep track of the unique days for each update
    if (!updateDays){
        updateDays = [[NSMutableArray alloc] initWithCapacity:20];
    }
    
    // Create a dictionary to associate updates with days
    updateDayDictionary = [[NSMutableDictionary dictionary] retain];
    
    [super viewWillAppear:animated];
    
    //Track page view based on selected chamber control button
    NSError *error;
    if (control.selectedSegmentIndex == 0) {
        //Register a page view to the Google Analytics tracker
        if (![[GANTracker sharedTracker] trackPageview:@"/floor-updates/house"
                                             withError:&error]) {
            // Handle error here
        }
    }
    
    else {
        //Register a page view to the Google Analytics tracker
        if (![[GANTracker sharedTracker] trackPageview:@"/floor-updates/senate"
                                             withError:&error]) {
            // Handle error here
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if ([updateDays count] > 0) {
        return ([updateDays count]+1);
    }
    else{
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if ([[floorUpdates objectAtIndex:section] isEqual:@"LoadingRow"]) {
        return 1;
    }
    else{
        NSArray *sectionArray = [floorUpdates objectAtIndex:section];
        return [sectionArray count];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[floorUpdates objectAtIndex:indexPath.section] isEqual:@"LoadingRow"]) {
        return 44.0;
    }
    else{
        NSArray *sectionArray = [floorUpdates objectAtIndex:indexPath.section];
        return [[sectionArray objectAtIndex:indexPath.row] textHeight] + 60;
        //55 = the height of the table cell wihtout the event text (76 - 21)
    }
}
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == [floorUpdates indexOfObject:[floorUpdates lastObject]]) {
        NSLog(@"Load data");
        page += 1;
        NSString * chamber = [control selectedSegmentIndex] == 0 ? @"house" : @"senate";
        connection = [[SunlightLabsConnection alloc] initWithSunlightLabsRequest:[[[SunlightLabsRequest alloc] initFloorUpdateRequestWithParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%ul",page],@"page",chamber,@"chamber", nil]] autorelease]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveFloorUpdate:) name:SunglightLabsRequestFinishedNotification object:connection];
        [connection sendRequest];
    }
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[floorUpdates objectAtIndex:indexPath.section] isEqual:@"LoadingRow"]) {
        NSLog(@"Loading Row Cell loaded");
        static NSString *CellIdentifier = @"LoadingCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"LoadingTableViewCell" owner:self options:nil] objectAtIndex:0];
        }
        return cell;
    }
    
    else if ([[[floorUpdates objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] isMemberOfClass:[FloorUpdate class]]) {
        NSArray *sectionArray = [floorUpdates objectAtIndex:indexPath.section];
        static NSString *CellIdentifier = @"FloorUpdateCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"FloorUpdateTableViewCell" owner:self options:nil] objectAtIndex:0];
        }
        [(UILabel *)[cell viewWithTag:1] setText:[[sectionArray objectAtIndex:indexPath.row] displayDate]];
        [(UITextView *)[cell viewWithTag:2] setFrame:CGRectMake([cell viewWithTag:2].frame.origin.x, [cell viewWithTag:2].frame.origin.y, [cell viewWithTag:2].frame.size.width,[[sectionArray objectAtIndex:indexPath.row] textViewHeightRequired])];
        [(UITextView *)[cell viewWithTag:2] setText:[[sectionArray objectAtIndex:indexPath.row] displayText]];
        return cell;
    }  
    
    else {
        static NSString * cellIdentifier = @"Cell";
        UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        return cell;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    // Sets the title of each section to the legislative day
    if ([updateDays count] > 0) {
        if (section == [updateDays count]) {
            return nil;
        }
        else {
            return [updateDays objectAtIndex:section];
        }
        
    }
    else {
        return [NSString stringWithString:@"No events logged"];
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {}


@end
