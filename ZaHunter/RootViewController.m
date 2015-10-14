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
@property (weak, nonatomic) IBOutlet UILabel *totalTimeLabel;
@property NSInteger totalTime;

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.pizzerias = [[NSMutableArray alloc] init];
    self.totalTime = 0;

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
    request.region = MKCoordinateRegionMake(self.userLocation.coordinate, MKCoordinateSpanMake(0.01,0.01));

    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];
    [search startWithCompletionHandler:^(MKLocalSearchResponse * _Nullable response, NSError * _Nullable error) {

        for (MKMapItem *item in response.mapItems){
            Pizzeria *pizzeria = [[Pizzeria alloc] init];
            pizzeria.mapItem = item;
            pizzeria.distanceFromUser = [self.userLocation distanceFromLocation:pizzeria.mapItem.placemark.location];

            if (pizzeria.distanceFromUser < 10000)
                [self.pizzerias addObject:pizzeria];

        }

       dispatch_async(dispatch_get_main_queue(), ^{

           [self.pizzerias sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"distanceFromUser" ascending:YES]]];

           //insert find routes
           [self huntAllTheZas];

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
        cell.textLabel.text = pizzeria.mapItem.name;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%f", pizzeria.distanceFromUser];
    }

    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (self.pizzerias.count < 4) {
        return self.pizzerias.count;
    } else if (self.pizzerias.count > 4) {
        return 4;
    }
    return 1;
}


- (void)huntAllTheZas {

    for (int i=0;i<4;i++) {
        [self getDirectionsTo:[self.pizzerias[i] mapItem]];
    }

}




- (void)getDirectionsTo:(MKMapItem *)destinationItem {
    MKDirectionsRequest *request = [MKDirectionsRequest new];


    if ([destinationItem isEqual:[self.pizzerias[0] mapItem]]) {
        request.source = [MKMapItem mapItemForCurrentLocation];
    } else if ([destinationItem isEqual:[self.pizzerias[1] mapItem]]) {
        request.source = [self.pizzerias[0] mapItem];
    } else if ([destinationItem isEqual:[self.pizzerias[2] mapItem]]) {
        request.source = [self.pizzerias[1] mapItem];
    } else if ([destinationItem isEqual:[self.pizzerias[3] mapItem]]) {
        request.source = [self.pizzerias[2] mapItem];
    }

    request.destination = destinationItem;

    request.transportType = MKDirectionsTransportTypeWalking;
    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];

    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse * _Nullable response, NSError * _Nullable error) {
        NSArray *routes = response.routes;
        MKRoute *route = routes.firstObject;

        self.totalTime += 50;
        self.totalTime += floor(route.expectedTravelTime/60);
        [self updateHuntTime];
        /*
        int x=1;
        NSMutableString *directionString = [NSMutableString string];
        for (MKRouteStep *step in route.steps) {
            NSLog(@"%@",step.instructions);
            [directionString appendFormat:@"%d: %@\n",x++,step.instructions];
        }
        //self.textView.text = directionString;
         */


    }];
    
}

- (void)updateHuntTime{
    self.totalTimeLabel.text = [NSString stringWithFormat:@"%li",self.totalTime];
}

@end
