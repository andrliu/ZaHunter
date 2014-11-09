//
//  MapViewController.m
//  ZaHunter
//
//  Created by Andrew Liu on 11/8/14.
//  Copyright (c) 2014 Andrew Liu. All rights reserved.
//

#import "MapViewController.h"
#import "ALMapItem.h"
#define kSpanDelta 0.08;
@import CoreLocation;
@import MapKit;


@interface MapViewController () <CLLocationManagerDelegate,MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property MKPointAnnotation *userAnnotation;

@end

@implementation MapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    self.userAnnotation = [[MKPointAnnotation alloc]init];
    self.userAnnotation.title = @"Current Location";
    self.userAnnotation.coordinate = self.currentLocation.coordinate;
    [self.mapView addAnnotation:self.userAnnotation];

    for (ALMapItem *pizzria in self.mapItemArray)
    {
        MKPointAnnotation *annotation = [MKPointAnnotation new];
        annotation.title = pizzria.mapItem.name;
        annotation.subtitle = [NSString stringWithFormat: @"Rating: %d", pizzria.rating ];
        annotation.coordinate =  pizzria.mapItem.placemark.location.coordinate;
        [self.mapView addAnnotation:annotation];
    }

    MKCoordinateSpan coordinateSpan;
    coordinateSpan.latitudeDelta = kSpanDelta;
    coordinateSpan.longitudeDelta = kSpanDelta;
    MKCoordinateRegion region = MKCoordinateRegionMake(self.currentLocation.coordinate, coordinateSpan);
    [self.mapView setRegion:region animated:YES];
}

-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKPinAnnotationView *pin = [[MKPinAnnotationView alloc]initWithAnnotation:annotation
                                                              reuseIdentifier:nil];
    pin.canShowCallout = YES;

    pin.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];

    if (![annotation isEqual:self.userAnnotation])
    {
        UIImage *templateImage = [[UIImage imageNamed:@"pizzria"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        UIImageView *imageView = [[UIImageView alloc]initWithImage:templateImage];
        if ([annotation.subtitle containsString:@"4"] || [annotation.subtitle containsString:@"5"])
        {
            imageView.tintColor = [UIColor redColor];
            pin.leftCalloutAccessoryView = imageView;
        }
        if ([annotation.subtitle containsString:@"3"])
        {
            imageView.tintColor = [UIColor blackColor];
            pin.leftCalloutAccessoryView = imageView;
        }
        if ([annotation.subtitle containsString:@"1"] || [annotation.subtitle containsString:@"2"])
        {
            imageView.tintColor = [UIColor greenColor];
            pin.leftCalloutAccessoryView = imageView;
        }
    }

    return pin;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[MKPolyline class]])
    {
        MKPolyline *route = overlay;
        MKPolylineRenderer *routeRenderer = [[MKPolylineRenderer alloc] initWithPolyline:route];
        routeRenderer.strokeColor = [UIColor greenColor];
        return routeRenderer;
    }
    else
    {
        return nil;
    }
}

- (void)getDirectionsTo:(MKPointAnnotation *) annotation
{
    CLLocationCoordinate2D currentCoordinate = CLLocationCoordinate2DMake(self.currentLocation.coordinate.latitude, self.currentLocation.coordinate.longitude);
    MKPlacemark *currentPlacemark = [[MKPlacemark alloc]initWithCoordinate:currentCoordinate addressDictionary:nil];
    MKMapItem *currentMapItem = [[MKMapItem alloc]initWithPlacemark:currentPlacemark];

    CLLocationCoordinate2D destinationCoordinate = CLLocationCoordinate2DMake(annotation.coordinate.latitude, annotation.coordinate.longitude);
    MKPlacemark *destinationPlacemark = [[MKPlacemark alloc]initWithCoordinate:destinationCoordinate addressDictionary:nil];
    MKMapItem *destinationMapItem = [[MKMapItem alloc]initWithPlacemark:destinationPlacemark];

    MKDirectionsRequest *request = [MKDirectionsRequest new];
    request.source = currentMapItem;
    request.destination = destinationMapItem;
    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        if (error)
        {
            [self Error:error];
        }
        else
        {
            NSArray *routes = response.routes;
            MKRoute *route = routes.firstObject;
            [self.mapView addOverlay:route.polyline level:MKOverlayLevelAboveRoads];
        }
    }];
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    MKPointAnnotation *annotation = view.annotation;
    [mapView removeOverlays:mapView.overlays];
    if (![annotation isEqual:self.userAnnotation])
    {
        [self getDirectionsTo:annotation];
    }
}

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

@end
