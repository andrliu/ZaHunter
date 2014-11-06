//
//  ListViewController.m
//  ZaHunter
//
//  Created by Andrew Liu on 11/5/14.
//  Copyright (c) 2014 Andrew Liu. All rights reserved.
//

#import "ListViewController.h"
@import CoreLocation;
@import MapKit;

@interface ListViewController () <UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property CLLocationManager *manager;
@property NSMutableArray *listArray;

@end

@implementation ListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.listArray = [NSMutableArray array];
//MARK CLLocationManager
    self.manager = [[CLLocationManager alloc]init];
    [self.manager startUpdatingLocation];
    [self.manager requestWhenInUseAuthorization];
    self.manager.delegate = self;

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.listArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];

    MKMapItem *mapItem = self.listArray [indexPath.row];

    cell.textLabel.text = mapItem.name;

    CLLocationDistance meters = [newLocation distanceFromLocation:oldLocation];

    request.source = [MKMapItem mapItemForCurrentLocation];

    request.destination = destinationItem;


    return cell;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    for (CLLocation *location in locations)
    {
        if (location.verticalAccuracy <100 && location.horizontalAccuracy < 100)
        {
            [self reverseGeocode:location];
            [self.manager stopUpdatingLocation];
            break;
        }
    }
}

- (void)reverseGeocode:(CLLocation *)location
{
    CLGeocoder *geocoder = [CLGeocoder new];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, id error)
     {
         CLPlacemark *placemark = placemarks.firstObject;
         [self findPizzeriaNear: placemark.location];
     }];
}

- (void)findPizzeriaNear:(CLLocation *)location
{
    MKLocalSearchRequest *request = [MKLocalSearchRequest new];
    request.naturalLanguageQuery = @"pizzeria";
    request.region = MKCoordinateRegionMake(location.coordinate, MKCoordinateSpanMake(50, 50));
    MKLocalSearch *search = [[MKLocalSearch alloc]initWithRequest:request];
    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error)
     {
         NSArray *mapItems = response.mapItems;

         for (MKMapItem *mapItem in mapItems)
         {
             [self.listArray addObject:mapItem];
         }

        [self.tableView reloadData];

     }];
}


@end
