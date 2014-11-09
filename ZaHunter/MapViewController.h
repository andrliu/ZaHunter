//
//  MapViewController.h
//  ZaHunter
//
//  Created by Andrew Liu on 11/8/14.
//  Copyright (c) 2014 Andrew Liu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface MapViewController : UIViewController
@property NSMutableArray *mapItemArray;
@property CLLocation *currentLocation;

@end
