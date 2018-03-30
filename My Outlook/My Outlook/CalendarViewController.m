//
//  ViewController.m
//  My Outlook
//
//  Created by Mukhtar Yusuf on 2/7/17.
//  Copyright © 2017 Mukhtar Yusuf. All rights reserved.
//

#import "CalendarViewController.h"
#import "TableSectionHeaderView.h"
#import "SelectedBGView.h"
#import "SeparatorView.h"

@interface CalendarViewController ()
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UICollectionView *calendarView;
@property (weak, nonatomic) IBOutlet UITableView *eventsView;
@property (weak, nonatomic) IBOutlet UIView *collectionViewHeader;

@property (strong, nonatomic) NSCalendar *gregorianCalendar;
@property (strong, nonatomic) NSMutableArray *allDates; //Of NSDate
@property (strong, nonatomic) NSDate *todaysDate;
@property (strong, nonatomic) NSDate *firstSunday;
@property (strong, nonatomic) NSDateComponents *totalDays;

@property (strong, nonatomic) NSIndexPath *selectedPath;
@property (strong, nonatomic) NSDictionary *events; //Of {NSUInteger:NSArray}
@property (strong, nonatomic) NSString *monthYearTitle;
@property (strong, nonatomic) NSArray *monthColors; //Of BOOL
@property (strong, nonatomic) NSIndexPath *prevSelectedPath;

@end

@implementation CalendarViewController

const long calendarStart = -1*7*365; // 7 years ago from current date
long finalCalendarStart; //First sunday 7 years ago from current date
const long calendarEnd = 3*365; // 3 years after current date

BOOL updateCalendarWhileScrollingTV;
BOOL isEventViewExpanded;

#define SECTION_HEADER_HEIGHT 30.0

//--Target Action Methods
#pragma mark - Target Action Methods

- (IBAction)reset:(id)sender {
    [self scrollAndSelectTodayAnimated:YES];
}

//--UICollectionView Data Source Methods--
#pragma mark - UICollectionView Data Source Methods

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.totalDays.day;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath{
    
    UICollectionViewCell *dayCell = nil;
    
    NSString *cellIdentifier = @"Day Cell";
    
    
    dayCell = [self.calendarView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    NSDate *dateForCell = self.allDates[indexPath.row];

    NSCalendarUnit unitsForCell = NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear;
    NSDateComponents *componentsForCell = [self.gregorianCalendar components:unitsForCell
                                                                    fromDate:dateForCell];
    NSDateComponents *componentsForToday = [self.gregorianCalendar components:unitsForCell
                                                                     fromDate:self.todaysDate];
    
    UILabel *monthLabel = (UILabel *)[dayCell viewWithTag:1]; //Ideal to Use Introspection Here
    NSDateFormatter *monthFormat = [[NSDateFormatter alloc] init];
    [monthFormat setDateFormat:@"MMM"];
    
    if((componentsForCell.month != componentsForToday.month) && componentsForCell.day == 1)
        monthLabel.text = [monthFormat stringFromDate:dateForCell];
    else
        monthLabel.text = @"";
    
    UILabel *yearLabel = (UILabel *)[dayCell viewWithTag:3]; //Ideal to Use Introspection Here
    NSDateFormatter *yearFormat = [[NSDateFormatter alloc] init];
    [yearFormat setDateFormat:@"YYYY"];
    
    if((componentsForCell.year != componentsForToday.year) && componentsForCell.day == 1)
        yearLabel.text = [yearFormat stringFromDate:dateForCell];
    else
        yearLabel.text = @"";
        
    UILabel *dayLabel = (UILabel *)[dayCell viewWithTag:2]; //Ideal to Use Introspection Here
    dayLabel.text = [NSString stringWithFormat:@"%li", componentsForCell.day];
    
    if([self.monthColors[componentsForCell.month%2] boolValue]) //Set color for month
        dayCell.backgroundColor = [UIColor colorWithRed:248.0/255.0 green:248.0/255.0 blue:255.0/255.0 alpha:1.0];
    else
        dayCell.backgroundColor = [UIColor whiteColor];
    
    if([self.selectedPath isEqual:indexPath]){ //Set background for selected/deselected cell
        dayCell.selectedBackgroundView = [[SelectedBGView alloc] initWithFrame:dayCell.selectedBackgroundView.frame];
        monthLabel.hidden = YES;
        dayLabel.textColor = [UIColor whiteColor];
        yearLabel.hidden = YES;
    }else{
        monthLabel.hidden = NO;
        
        if([self.gregorianCalendar isDateInToday:dateForCell]) //Make text color blue for today's date
            dayLabel.textColor = [UIColor blueColor];
        else
            dayLabel.textColor = [UIColor darkGrayColor];
        
        yearLabel.hidden = NO;
    }
    
    return dayCell;
}

//--UICollectionView Delegate Methods--
#pragma mark - UICollectionView Delegate Methods

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    updateCalendarWhileScrollingTV = NO;

    self.selectedPath = indexPath;
    if(isEventViewExpanded){ //Position selected cell at the top if events view is expanded
        [collectionView scrollToItemAtIndexPath:indexPath
                               atScrollPosition:UICollectionViewScrollPositionTop
                                       animated:YES];
    }else{ //Position selected cell at center if events view is not expanded
        [collectionView scrollToItemAtIndexPath:indexPath
                           atScrollPosition:UICollectionViewScrollPositionCenteredVertically
                                   animated:YES];
    }
    self.prevSelectedPath = indexPath;
    [self updateSelectedCellAtIndexPath:indexPath];
    
    NSIndexPath *tablePath = [NSIndexPath indexPathForRow:0 inSection:indexPath.row];
    [self.eventsView scrollToRowAtIndexPath:tablePath
                           atScrollPosition:UITableViewScrollPositionTop
                                   animated:YES];
}

-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath{
    [self updateDeselectedCellAtIndexPath:indexPath];
}

//--UITableView DataSource Methods--
#pragma mark - UITableView DataSource Methods

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.totalDays.day;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSArray *dayEvents = (NSArray*) self.events[[NSNumber numberWithInteger:section]]; //Ideal to Use Instrospection Here
    
    if(dayEvents)
        return [dayEvents count];
    else
        return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = nil;
    NSString *cellIdentifier = @"Event Cell";
    
    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    NSArray *dayEvents = (NSArray*) self.events[[NSNumber numberWithInteger:indexPath.section]]; //Ideal to Use Instrospection Here
    
    UIFont *cellFont = [UIFont systemFontOfSize:12];
    cell.textLabel.font = cellFont;
    
    if (dayEvents){
        NSString *eventString = (NSString *)dayEvents[indexPath.row];
        NSRange rangeOfDot = [eventString rangeOfString:@"●"];
        NSMutableAttributedString *attrEventString = [[NSMutableAttributedString alloc] initWithString:eventString];
        [attrEventString addAttribute:NSForegroundColorAttributeName
                                value:[UIColor redColor]
                                range:rangeOfDot];
        
        cell.textLabel.attributedText = attrEventString;
    }
    else
        cell.textLabel.text = @"No Events";
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return SECTION_HEADER_HEIGHT;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    CGRect headerFrame = CGRectMake(0, 0, tableView.frame.size.width, SECTION_HEADER_HEIGHT);
    TableSectionHeaderView *view = [[TableSectionHeaderView alloc] initWithFrame:headerFrame];
    
    /*--Better to have these in custom view implementation--*/
    CGFloat labelHeight = 0.5 * view.frame.size.height;
    CGFloat labelWidth = 0.8 * view.frame.size.width;
    CGFloat yLabelOffset = (view.frame.size.height/2.0) - (labelHeight/2.0);
    CGFloat xLabelOffset = 15.0;
    CGRect labelRect = CGRectMake(view.frame.origin.x + xLabelOffset, view.frame.origin.y + yLabelOffset, labelWidth, labelHeight);
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:labelRect];
    
    NSDate *dateForSection = self.allDates[section];
    NSString *prePend = @"";
    
    if([self.gregorianCalendar isDateInYesterday:dateForSection])
        prePend = @"Yesterday  •  ";
    else if([self.gregorianCalendar isDateInToday:dateForSection])
        prePend = @"Today  •  ";
    else if([self.gregorianCalendar isDateInTomorrow:dateForSection])
        prePend = @"Tomorrow  •  ";
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"EEEE, MMMM d"];
    
    UIFont *headerFont = [UIFont systemFontOfSize:13.0];
    headerLabel.font = headerFont;
    headerLabel.text = [NSString stringWithFormat:@"%@%@", prePend, [dateFormat stringFromDate:dateForSection]];
    headerLabel.textColor = [UIColor darkGrayColor];
    headerLabel.minimumScaleFactor = 0.5;
    
    if([self.gregorianCalendar isDate:self.todaysDate
       equalToDate:dateForSection toUnitGranularity:NSCalendarUnitDay]){
        view.strokeColor = [UIColor blueColor];
        headerLabel.textColor = [UIColor blueColor];
    }
    
    [view addSubview:headerLabel];
    
    return view;
}

//--UIScrollView Delegate Methods--
#pragma mark - UIScrollView Delegate Methods

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{ //Expand Events View
    if([scrollView isKindOfClass:[UITableView class]] && !isEventViewExpanded){
        CGFloat cHeightRatio = 0.2;
        CGFloat eHeightRatio = 0.8;
        
        CGFloat newCalendarHeight = cHeightRatio * self.containerView.frame.size.height;
        CGFloat newEventsHeight = eHeightRatio * self.containerView.frame.size.height;
        
        CGRect calendarFrame = CGRectMake(self.calendarView.frame.origin.x, self.calendarView.frame.origin.y, self.calendarView.frame.size.width, newCalendarHeight);
        CGRect eventsFrame = CGRectMake(self.eventsView.frame.origin.x, self.calendarView.frame.origin.y+newCalendarHeight, self.eventsView.frame.size.width, newEventsHeight);

        [UIView animateWithDuration:0.3
                         animations:^{
                             self.calendarView.frame = calendarFrame;
                             self.eventsView.frame = eventsFrame;
                             isEventViewExpanded = YES;
                         }];
    }
    if([scrollView isKindOfClass:[UICollectionView class]] &&isEventViewExpanded){ //Expand Calendar View
        CGFloat cHeightRatio = 0.5;
        CGFloat eHeightRatio = 0.5;
        
        CGFloat newCalendarHeight = cHeightRatio * self.containerView.frame.size.height;
        CGFloat newEventsHeight = eHeightRatio * self.containerView.frame.size.height;
        
        CGRect calendarFrame = CGRectMake(self.calendarView.frame.origin.x, self.calendarView.frame.origin.y, self.calendarView.frame.size.width, newCalendarHeight);
        CGRect eventsFrame = CGRectMake(self.eventsView.frame.origin.x, self.calendarView.frame.origin.y+newCalendarHeight, self.eventsView.frame.size.width, newEventsHeight);
        [UIView animateWithDuration:0.3
                         animations:^{
                             self.eventsView.frame = eventsFrame;
                             self.calendarView.frame = calendarFrame;
                             isEventViewExpanded = NO;
                         }];
    }
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if([scrollView isKindOfClass:[UITableView class]] && updateCalendarWhileScrollingTV == NO){
        updateCalendarWhileScrollingTV = YES;
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if([scrollView isKindOfClass:[UITableView class]] && updateCalendarWhileScrollingTV == YES){
        //Only update calendarView if user triggered scrolling in table view
        NSIndexPath *firstVisibleIndexPath = [[self.eventsView indexPathsForVisibleRows] objectAtIndex:0];
        NSIndexPath *calendarPath = [NSIndexPath indexPathForItem:firstVisibleIndexPath.section inSection:0];
        [self updateDeselectedCellAtIndexPath:self.prevSelectedPath];

        self.selectedPath = calendarPath;
        
        if(isEventViewExpanded){ //Position selected cell at the top if events view is expanded
            [self.calendarView selectItemAtIndexPath:calendarPath
                                            animated:YES
                                      scrollPosition:UICollectionViewScrollPositionTop];
        }else{ //Position selected cell at center if events view is not expanded
            [self.calendarView selectItemAtIndexPath:calendarPath
                                            animated:YES
                                      scrollPosition:UICollectionViewScrollPositionCenteredVertically];
        }
        self.prevSelectedPath = calendarPath;
        
        [self updateSelectedCellAtIndexPath:calendarPath];
    }
}

//--Getters and Setters--
#pragma mark - Getters and Setters

-(NSCalendar *)gregorianCalendar{
    if(!_gregorianCalendar)
        _gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    return _gregorianCalendar;
}

-(NSMutableArray *)allDates{
    if(!_allDates)
        _allDates = [[NSMutableArray alloc] init];
    
    return _allDates;
}

-(NSArray *)monthColors{
    if(!_monthColors){
        _monthColors = @[@YES, @NO];
    }
    return _monthColors;
}

//--Helper Methods--
#pragma mark - Helper Methods

-(void)updateSelectedCellAtIndexPath:(NSIndexPath *)indexPath{
    [self updateMonthYearTitleForDate:self.allDates[indexPath.row]];
    self.navigationItem.title = self.monthYearTitle; //Update nav bar title to display selected month and year
    
    UICollectionViewCell *selectedCell = [self.calendarView cellForItemAtIndexPath:indexPath];

    selectedCell.selectedBackgroundView = [[SelectedBGView alloc] initWithFrame:selectedCell.selectedBackgroundView.frame];
    
    UILabel *monthLabel = (UILabel *)[selectedCell viewWithTag:1];
    UILabel *yearLabel = (UILabel *)[selectedCell viewWithTag:3];
    UILabel *dayLabel = (UILabel *)[selectedCell viewWithTag:2];
    monthLabel.hidden = YES;
    dayLabel.textColor = [UIColor whiteColor];
    yearLabel.hidden = YES;
}

-(void)updateDeselectedCellAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *deselectedCell = [self.calendarView cellForItemAtIndexPath:indexPath];

    deselectedCell.selectedBackgroundView = nil;
    
    UILabel *monthLabel = (UILabel *)[deselectedCell viewWithTag:1];
    UILabel *yearLabel = (UILabel *)[deselectedCell viewWithTag:3];
    UILabel *dayLabel = (UILabel *)[deselectedCell viewWithTag:2];
    
    monthLabel.hidden = NO;
    if([self.gregorianCalendar isDateInToday:self.allDates[indexPath.row]])
        dayLabel.textColor = [UIColor blueColor];
    else
        dayLabel.textColor = [UIColor darkGrayColor];
    yearLabel.hidden = NO;
}

-(void)updateMonthYearTitleForDate:(NSDate *)date{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MMMM YYYY"];
    self.monthYearTitle = [formatter stringFromDate:date];
}

-(NSUInteger)getTodaysIndex{
    NSUInteger todaysIndex;
    NSDateComponents *difference = [[NSDateComponents alloc] init];
    difference = [self.gregorianCalendar components:NSCalendarUnitDay
                                           fromDate:self.firstSunday
                                             toDate:self.todaysDate
                                            options:0];
    todaysIndex = difference.day;
    
    return todaysIndex;
}

//--Setup Code--
#pragma mark - Setup Code

-(void)setUpAllDates{
    for(int i = 0; i < self.totalDays.day; i++){
        NSDate *dateForIndex;
        NSDateComponents *components = [[NSDateComponents alloc] init];
        components.day = finalCalendarStart + i; //Days after first Sunday
        
        dateForIndex = [self.gregorianCalendar dateByAddingComponents:components
                                                               toDate:self.todaysDate options:0];
        [self.allDates insertObject:dateForIndex atIndex:i];
    }
}

-(void)setUpTodaysDate{
    self.todaysDate = [NSDate date];
}

-(void)setUpFirstSunday{
    NSDate *todaysDate = [NSDate date];
    NSDate *sevenYearsBeforeNow;
    NSDateComponents *sevenYearsBefore = [[NSDateComponents alloc] init];
    NSDateComponents *difference = [[NSDateComponents alloc] init]; //Difference between seven years before and first sunday
    sevenYearsBefore.day = calendarStart;
    sevenYearsBeforeNow = [self.gregorianCalendar dateByAddingComponents:sevenYearsBefore
                                                                  toDate:todaysDate
                                                                 options:0];
    self.firstSunday = [self.gregorianCalendar nextDateAfterDate:sevenYearsBeforeNow
                                                matchingUnit:NSCalendarUnitWeekday
                                                       value:1
                                                     options:NSCalendarMatchNextTime];
    difference = [self.gregorianCalendar components:NSCalendarUnitDay
                                           fromDate:sevenYearsBeforeNow
                                             toDate:self.firstSunday
                                            options:0];
    finalCalendarStart = (calendarStart + difference.day) + 1;
}

-(void)setUpTotalDays{
    NSDate *calendarEndDate;
    NSDateComponents *daysToEndDate = [[NSDateComponents alloc] init];
    NSDateComponents *startToEnd = [[NSDateComponents alloc] init];
    
    daysToEndDate.day = calendarEnd;
    
    calendarEndDate = [self.gregorianCalendar dateByAddingComponents:daysToEndDate
                                                              toDate:self.todaysDate
                                                             options:0];
    startToEnd = [self.gregorianCalendar components:NSCalendarUnitDay
                                           fromDate:self.firstSunday
                                             toDate:calendarEndDate
                                            options:0];
    
    self.totalDays = startToEnd;
}

-(void)setUpEvents{
    //Using NSString for simplicity. Could also have Event Objects with overriden description method
    NSArray *eventsForDay = @[@"10:00 AM    ●    Meeting With Max",
                             @"ALL DAY    ●    Become Even More Inspired",
                             @"ALL DAY    ●    Work Hard and Get Things Done!"
                             ];
    NSNumber *keyForDay = [NSNumber numberWithUnsignedInteger:[self getTodaysIndex]];
    self.events = @{ keyForDay : eventsForDay };
}

-(void)setUpCollectionViewHeader{
    NSArray *daySymbols = @[@"S", @"M", @"T", @"W", @"T", @"F", @"S"];
    CGFloat labelWidth = self.collectionViewHeader.frame.size.width/daySymbols.count;
    CGFloat labelHeight = self.collectionViewHeader.frame.size.height;
    
    UIFont *labelFont = [UIFont systemFontOfSize:10];
    
    int dIndex = 0;

    for(double i = 0; i < self.collectionViewHeader.frame.size.width; i+= labelWidth, dIndex++){
        CGRect labelRect = CGRectMake(i, 0, labelWidth, labelHeight);
        UILabel *dSymbolLabel = [[UILabel alloc] initWithFrame:labelRect];
        dSymbolLabel.text = daySymbols[dIndex];
        dSymbolLabel.textAlignment = NSTextAlignmentCenter;
        dSymbolLabel.font = labelFont;
        dSymbolLabel.textColor = [UIColor darkGrayColor];
        
        [self.collectionViewHeader addSubview:dSymbolLabel];
    }
}

-(void)scrollAndSelectTodayAnimated:(BOOL)animated{
    updateCalendarWhileScrollingTV = NO;
    NSUInteger todaysIndex;
    todaysIndex = [self getTodaysIndex];
    NSIndexPath *calendarPath = [NSIndexPath indexPathForRow:todaysIndex inSection:0];
    NSIndexPath *eventPath = [NSIndexPath indexPathForRow:0 inSection:todaysIndex];
    
    [self updateDeselectedCellAtIndexPath:self.prevSelectedPath];

    self.selectedPath = calendarPath;
    
    if(isEventViewExpanded){ //Position selected cell at the top if events view is expanded
        [self.calendarView selectItemAtIndexPath:calendarPath
                                        animated:animated
                                  scrollPosition:UICollectionViewScrollPositionTop];
    }else{ //Position selected cell at center if events view is not expanded
        [self.calendarView selectItemAtIndexPath:calendarPath
                                        animated:animated
                                  scrollPosition:UICollectionViewScrollPositionCenteredVertically];
    }
    [self updateSelectedCellAtIndexPath:calendarPath];
    self.prevSelectedPath = calendarPath;
    
    [self.eventsView scrollToRowAtIndexPath:eventPath
                           atScrollPosition:UITableViewScrollPositionTop
                                   animated:animated];
}


-(void)setUpCalendarViewHeight{ //Because storyboard sizes aren't pixel perfect
    CGRect calendarFrame = CGRectMake(self.calendarView.frame.origin.x, self.calendarView.frame.origin.y, self.calendarView.frame.size.width, self.containerView.frame.size.height/2);
    self.calendarView.frame = calendarFrame;
}

-(void)setUpEventsViewHeight{ //Because storyboard sizes aren't pixel perfect
    CGRect eventsFrame = CGRectMake(self.eventsView.frame.origin.x, self.calendarView.frame.origin.y + self.calendarView.frame.size.height, self.eventsView.frame.size.width, self.containerView.frame.size.height/2);
    self.eventsView.frame = eventsFrame;
}

-(void)setUpFlowLayout{
    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)self.calendarView.collectionViewLayout;
    [flowLayout registerClass:[SeparatorView class] forDecorationViewOfKind:@"SeparatorView"];
    CGSize itemSize = CGSizeMake(self.calendarView.frame.size.width/7, self.calendarView.frame.size.height/5);
    flowLayout.itemSize = itemSize;
}

-(void)setUpNavBar{
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor blueColor],
                                                                      NSFontAttributeName:[UIFont preferredFontForTextStyle:     UIFontTextStyleSubheadline]}];
    self.navigationItem.title = self.monthYearTitle;
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.tintColor = [UIColor lightGrayColor];
    self.navigationController.navigationBar.clipsToBounds = YES;
}

-(void)setUp{
    [self setUpTodaysDate];
    [self setUpFirstSunday];
    [self setUpTotalDays];
    [self setUpEvents];
    [self setUpAllDates];
    [self updateMonthYearTitleForDate:self.todaysDate];
    [self setUpCollectionViewHeader];
    
    self.calendarView.translatesAutoresizingMaskIntoConstraints = YES;
    self.eventsView.translatesAutoresizingMaskIntoConstraints = YES;
    
    self.calendarView.dataSource = self;
    self.calendarView.delegate = self;
    self.eventsView.dataSource = self;
    self.eventsView.delegate = self;
    
    [self setUpCalendarViewHeight];
    [self setUpEventsViewHeight];
    
    [self setUpFlowLayout];
    
    [self scrollAndSelectTodayAnimated:NO];
    [self setUpNavBar];
}

//--View Controller Lifecycle--
#pragma mark - View Controller Lifecycle

-(void)viewDidLoad{
    [super viewDidLoad];
    [self setUp];
}

-(void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
