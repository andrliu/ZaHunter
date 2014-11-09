//
//  ListViewController.m
//  ZaHunter
//
//  Created by Andrew Liu on 11/5/14.
//  Copyright (c) 2014 Andrew Liu. All rights reserved.
//

#import "ListViewController.h"
#import "MapViewController.h"
#import "ALMapItem.h"
@import CoreLocation;
@import MapKit;

@interface ListViewController () <UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate, UITabBarControllerDelegate>
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property CLLocationManager *manager;
@property NSMutableArray *currentArray;
@property NSMutableArray *listArray;
@property NSMutableArray *ETAArray;
@property CLLocation *currentLocation;
@property int totalETA;

@end

@implementation ListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.currentArray = [NSMutableArray array];
    self.listArray = [NSMutableArray array];
    self.ETAArray = [NSMutableArray array];

//MARK CLLocationManager start updating current location
    self.manager = [[CLLocationManager alloc]init];
    [self.manager startUpdatingLocation];
    [self.manager requestWhenInUseAuthorization];
    self.manager.delegate = self;
    self.tabBarController.delegate = self;

    [self.tableView reloadData];
}


- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    MapViewController *mvc = [self.tabBarController.viewControllers objectAtIndex:1];
    mvc.mapItemArray = self.currentArray;
    mvc.currentLocation = self.currentLocation;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.currentArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];

    ALMapItem *destination = self.currentArray [indexPath.row];

    cell.textLabel.text = destination.mapItem.name;

    double kilometers = destination.distance / 1000;

    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%0.02f km)", destination.address, kilometers];

    return cell;
}

//MARK: custom error alert
- (void)Error:(NSError *)error
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                   message:error.localizedDescription
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleDefault
                                                   handler:nil];
    [alert addAction:action];

    [self presentViewController:alert animated:YES completion:nil];
}

//MARK: locationManager fail with error
- (void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [self Error:error];
}

//MARK: stop updating location once locating in a certain distance range
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

//MARK: use first object of placemarks to get location address
- (void)reverseGeocode:(CLLocation *)location
{
    CLGeocoder *geocoder = [CLGeocoder new];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error)
         {
             if (error)
             {
                 [self Error:error];
             }
             else
             {
                 CLPlacemark *placemark = placemarks.firstObject;
                 self.currentLocation = placemark.location;
                 [self findPizzeriaNear: placemark.location];
             }
         }
     ];
}

//MARK: find placemark locations based on current location
- (void)findPizzeriaNear:(CLLocation *)location
{
    MKLocalSearchRequest *request = [MKLocalSearchRequest new];
    request.naturalLanguageQuery = @"Pizzeria";
    request.region = MKCoordinateRegionMake(location.coordinate, MKCoordinateSpanMake(0.2, 0.2));
    MKLocalSearch *search = [[MKLocalSearch alloc]initWithRequest:request];
    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error)
         {
            if (error)
            {
                [self Error:error];
            }
            else
            {
                NSArray *mapItems = response.mapItems;

                for (MKMapItem *mapItem in mapItems)
                {
                    ALMapItem *pizzria = [[ALMapItem alloc] init];

                    pizzria.mapItem = mapItem;

                    pizzria.address = [NSString stringWithFormat:@"%@ %@ %@ %@", mapItem.placemark.subThoroughfare,mapItem.placemark.thoroughfare,mapItem.placemark.locality, mapItem.placemark.administrativeArea];

                    pizzria.distance = [mapItem.placemark.location distanceFromLocation: self.manager.location];

                    [self.listArray addObject:pizzria];

                }

                self.listArray = [[self.listArray sortedArrayUsingComparator:^NSComparisonResult(ALMapItem *obj1, ALMapItem *obj2)
                {

                    if (obj1.distance < obj2.distance)
                    {
                        return (NSComparisonResult)NSOrderedAscending;
                    }

                    if (obj1.distance > obj2.distance)
                    {
                        return (NSComparisonResult)NSOrderedDescending;
                    }
                    return (NSComparisonResult)NSOrderedSame;

                }] mutableCopy];

                [self.ETAArray addObject:[MKMapItem mapItemForCurrentLocation]];

                for (ALMapItem *pizzria in self.listArray)
                {
                    if (pizzria.distance < 10000 && self.currentArray.count <4 )
                    {
                        [self.currentArray addObject:pizzria];
                        [self.ETAArray addObject:pizzria.mapItem];
                    }
                }

                [self.ETAArray addObject:[MKMapItem mapItemForCurrentLocation]];

                for (int i = 0; i < self.ETAArray.count - 1 ; i++)
                {
                    [self getETAFrom:self.ETAArray[i] to:self.ETAArray[i+1] type:MKDirectionsTransportTypeWalking];
                }

                [self.tableView reloadData];
            }
         }
     ];

}


- (void)getETAFrom:(MKMapItem *)sourceItem to:(MKMapItem *)destinationItem type:(MKDirectionsTransportType)transportType
{
    
    MKDirectionsRequest *request = [MKDirectionsRequest new];
    request.source = sourceItem;
    request.destination = destinationItem;
    request.transportType = transportType;
    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
    [directions calculateETAWithCompletionHandler:^(MKETAResponse *response, NSError *error)
     {
        if (error)
        {
            [self Error:error];
        }
        else
        {
            double timeETA = response.expectedTravelTime;
            int ETA = (timeETA + 3000)/60;
            self.totalETA = self.totalETA + ETA;
            [self.tableView reloadData];
       }
    }];
}

- (IBAction)directionOption:(UISegmentedControl *)sender
{
    if (sender.selectedSegmentIndex == 1)
    {
        self.totalETA = 0;
        for (int i = 0; i < self.ETAArray.count - 1 ; i++)
        {
            [self getETAFrom:self.ETAArray[i] to:self.ETAArray[i+1] type:MKDirectionsTransportTypeAutomobile];
        }
    }
    else
    {
        self.totalETA = 0;
        for (int i = 0; i < self.ETAArray.count - 1 ; i++)
        {
            [self getETAFrom:self.ETAArray[i] to:self.ETAArray[i+1] type:MKDirectionsTransportTypeWalking];
        }
    }
}

- (IBAction)editOnButtonPressed:(UIButton *)editButton
{
    self.tableView.editing = YES;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Confirmation"
                                                                   message:@"Are you sure you would like to delete this item?"
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *delete = [UIAlertAction actionWithTitle:@"Delete"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action)
                             {
                                 [self.listArray removeObjectAtIndex:indexPath.row];
                                 [self.currentArray removeObjectAtIndex:indexPath.row];
                                 [self.ETAArray removeObjectAtIndex:indexPath.row];
                                 self.tableView.editing = NO;
                                 [self.tableView reloadData];
                                 [self directionOption:self.segmentedControl];
                             }
                             ];

    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil];

    [alert addAction:delete];

    [alert addAction:cancel];

    [self presentViewController:alert animated:YES completion:nil];
    [self.tableView reloadData];
}

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (self.currentArray.count == 0)
    {
        return nil;
    }
    else
    {
        NSString *ETA = [NSString stringWithFormat:@"ETA: %d mins", self.totalETA];
        return ETA;
    }
}

@end
