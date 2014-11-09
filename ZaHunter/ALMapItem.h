//
//  Pizzeria.h
//  ZaHunter
//
//  Created by Andrew Liu on 11/6/14.
//  Copyright (c) 2014 Andrew Liu. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface ALMapItem : NSObject

@property MKMapItem *mapItem;
@property NSString *address;
@property double distance;
@property int rating;

@end
