//
//  RootViewController.m
//  ZaHunter
//
//  Created by Francis Bato on 10/14/15.
//  Copyright © 2015 Francis Bato. All rights reserved.
//

#import "RootViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "Pizzeria.h"

@interface RootViewController () <CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate>

@property CLLocationManager *locationManager;
@property CLLocation *userLocation;
@property NSMutableArray *pizzerias;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.pizzerias = [[NSMutableArray alloc] init];

    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    [self.locationManager requestAlwaysAuthorization];
    [self.locationManager startUpdatingLocation];


}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    CLLocation *location = locations.firstObject;
    if (location.verticalAccuracy < 1000 && location.horizontalAccuracy < 1000){
        [self.locationManager stopUpdatingLocation];
        self.userLocation = location;
        [self findPizzeria];
    }
}

- (void) findPizzeria{
    MKLocalSearchRequest *request = [MKLocalSearchRequest new];
    request.naturalLanguageQuery = @"pizza";
    request.region = MKCoordinateRegionMake(self.userLocation.coordinate, MKCoordinateSpanMake(1,1));

    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];
    [search startWithCompletionHandler:^(MKLocalSearchResponse * _Nullable response, NSError * _Nullable error) {

        for (MKMapItem *item in response.mapItems){
            Pizzeria *pizzeria = (Pizzeria *) item;
            [self.pizzerias addObject:pizzeria];

        }

       dispatch_async(dispatch_get_main_queue(), ^{
           [self.tableView reloadData];

       });
    }];
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    NSLog(@"%@", error);
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellsOnCells"];

    if (self.pizzerias.count){

        Pizzeria *pizzeria = [self.pizzerias objectAtIndex:indexPath.row];
        cell.textLabel.text = pizzeria.name;
//        cell.detailTextLabel.text = [NSString stringWithFormat:@"%f", pizzeria.distanceFromUser];
    }

    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (self.pizzerias.count > 0) {
        return self.pizzerias.count;
    }
    return 1;
}
@end
