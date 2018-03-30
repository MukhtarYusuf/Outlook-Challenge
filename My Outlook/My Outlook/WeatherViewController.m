//
//  WeatherViewController.m
//  My Outlook
//
//  Created by Mukhtar Yusuf on 2/17/17.
//  Copyright © 2017 Mukhtar Yusuf. All rights reserved.
//

#import "WeatherViewController.h"
#import "YQL.h"

@interface WeatherViewController()
@property (weak, nonatomic) IBOutlet UILabel *cityLabel;
@property (weak, nonatomic) IBOutlet UILabel *conditionLabel;
@property (weak, nonatomic) IBOutlet UILabel *tempLabel;
@property (weak, nonatomic) IBOutlet UITableView *forcastView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loading;

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *currentLocation;
@property (strong, nonatomic) NSString *cityState;
@property (strong, nonatomic) NSDictionary *queryResults;
@property (strong, nonatomic) NSArray *dayForecasts;
@property (strong, nonatomic) YQL *yql;
@end

@implementation WeatherViewController

//--Key Paths--
#pragma mark - Key Paths

#define CITY_NAME @"query.results.channel.location.city"
#define CONDITION @"query.results.channel.item.condition.text"
#define TEMP @"query.results.channel.item.condition.temp"
#define DAY_FORECASTS @"query.results.channel.item.forecast"

//Forcast dictionary Keys
#define DAY @"day"
#define HIGH @"high"
#define LOW @"low"
#define TEXT @"text"

//--Location Manager Delegate Methods--
#pragma mark - Location Manager Delegate Methods

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    self.currentLocation = locations[0];
    [self.locationManager stopUpdatingLocation]; //To prevent unnecessary updates and battery drain
    
    CLGeocoder *geoCoder = [[CLGeocoder alloc] init];
    [geoCoder reverseGeocodeLocation:self.currentLocation
                   completionHandler:^(NSArray *placeMarks, NSError *error){
                       if(!error){
                           CLPlacemark *placeMark = placeMarks[0];
                           NSString *city = placeMark.locality;
                           NSString *state = placeMark.administrativeArea;
                           self.cityState = [NSString stringWithFormat:@"%@, %@", city, state];
                           dispatch_queue_t fetchQ = dispatch_queue_create("fetch results", NULL);
                           dispatch_async(fetchQ, ^{
                               [self fetchQueryResults];
                               [self setUpDayForcasts];
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   [self.loading stopAnimating];
                                   [self setUpMainLabels];
                                   [self setUpForcastViewDelegates];
                                   [self.forcastView reloadData];
                               });
                           });
                        }else{
                           self.cityState = @"San Francisco, CA"; //Make SF Default
                           dispatch_queue_t fetchQ = dispatch_queue_create("fetch results", NULL);
                            dispatch_async(fetchQ, ^{
                                [self fetchQueryResults];
                                [self setUpDayForcasts];
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self.loading stopAnimating];
                                    [self setUpMainLabels];
                                    [self setUpForcastViewDelegates];
                                    [self.forcastView reloadData];
                                });
                            });
                        }
                   }];
}


//--UITableView Data Source Methods--
#pragma mark - UITableView Data Source Methods

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.dayForcasts count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = nil;
    NSString *cellIdentifier = @"Forcast Cell";
    
    cell = [self.forcastView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    UILabel *dayLabel = (UILabel *)[cell viewWithTag:1]; //Ideal to use Introspection
    UILabel *conditionLabel = (UILabel *)[cell viewWithTag:2]; //Ideal to use Introspection
    UILabel *highLabel = (UILabel *)[cell viewWithTag:3]; //Ideal to use Introspection
    UILabel *lowLabel = (UILabel *)[cell viewWithTag:4]; //Ideal to use Introspection
    
    NSDictionary *oneDayForcast = (NSDictionary *)self.dayForcasts[indexPath.row];
    
    dayLabel.text = [oneDayForcast valueForKeyPath:DAY];
    conditionLabel.text = [oneDayForcast valueForKeyPath:TEXT];
    highLabel.text = [oneDayForcast valueForKeyPath:HIGH];
    lowLabel.text = [oneDayForcast valueForKeyPath:LOW];
    
    return cell;
}

//--Getters and Setters--
#pragma mark - Getters and Setters

-(CLLocationManager *)locationManager{
    if(!_locationManager)
        _locationManager = [[CLLocationManager alloc] init];
    
    return _locationManager;
}

-(CLLocation *)currentLocation{
    if(!_currentLocation)
        _currentLocation = [[CLLocation alloc] init];
    
    return _currentLocation;
}
-(YQL *)yql{
    if(!_yql)
        _yql = [[YQL alloc] init];
    
    return _yql;
}
-(NSDictionary *)queryResults{
    if(!_queryResults)
        _queryResults = [[NSDictionary alloc] init];
    
    return _queryResults;
}

-(NSArray *)dayForcasts{
    if(!_dayForecasts)
        _dayForecasts = [[NSArray alloc] init];
    
    return _dayForecasts;
}

//--Helper Methods--
#pragma mark - Helper Methods

-(void)fetchQueryResults{
    NSString *queryString = [NSString stringWithFormat:@"select * from weather.forecast where woeid in (select woeid from geo.places(1) where text=\"%@\")", self.cityState];
    self.queryResults = [self.yql query:queryString];
    NSLog(@"Weather: Query Results: %@", self.queryResults);
    NSLog(@"city state: %@", self.cityState);
}

//--Setup Code--
#pragma mark - Setup Code

-(void)setUpMainLabels{
    self.cityLabel.text = [self.queryResults valueForKeyPath:CITY_NAME];
    self.conditionLabel.text = [self.queryResults valueForKeyPath:CONDITION];
    self.tempLabel.text = [NSString stringWithFormat:@"%@°", [self.queryResults valueForKeyPath:TEMP]];
}

-(void)setUpDayForcasts{
    self.dayForecasts = (NSArray *)[self.queryResults valueForKeyPath:DAY_FORECASTS];
}

-(void)setUpForcastViewDelegates{
    self.forcastView.dataSource = self;
    self.forcastView.delegate = self;
}

-(void)setUpLocationManager{
    self.locationManager.delegate = self;
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
        [self.locationManager requestWhenInUseAuthorization];
    
    [self.locationManager startUpdatingLocation];
}

//--View Controller Lifecycle--
#pragma mark - View Controller Lifecycle

-(void)viewDidLoad{
    [super viewDidLoad];
    [self setUpLocationManager];
}
@end
