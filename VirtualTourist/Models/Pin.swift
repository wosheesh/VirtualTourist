//
//  Pin.swift
//  VirtualTourist
//
//  Created by Wojtek Materka on 10/02/2016.
//  Copyright © 2016 Wojtek Materka. All rights reserved.
//

import CoreData
import MapKit

@objc

// Making Pin a subclass of MKAnnotation for easier interfacing with mapViews
class Pin: NSManagedObject, MKAnnotation {
    
    // MARK: - 🎛 Properties
    
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    @NSManaged var pictures: [Picture]
    
    // MARK: - 🌱 Init
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(annotationLatitude: Double, annotationLongitude: Double, context: NSManagedObjectContext) {
        
        // Core Data
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Init Properties
        latitude = NSNumber(double: annotationLatitude)
        longitude = NSNumber(double: annotationLongitude)
    }
    
    // MARK: - 📍 MKAnnotation subclass
    
    var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: latitude as Double, longitude: longitude as Double)
        }
        
        set (newValue) {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }
    
}