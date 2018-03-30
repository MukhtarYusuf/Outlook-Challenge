//
//  WeatherViewController.h
//  My Outlook
//
//  Created by Mukhtar Yusuf on 2/17/17.
//  Copyright © 2017 Mukhtar Yusuf. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface WeatherViewController : UIViewController <CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate>

@end
