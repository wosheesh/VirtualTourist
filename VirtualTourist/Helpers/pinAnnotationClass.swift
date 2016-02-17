//
//  PinAnnotationClass.swift
//  VirtualTourist
//
//  Created by Wojtek Materka on 17/02/2016.
//  Copyright © 2016 Wojtek Materka. All rights reserved.
//

import MapKit
import UIKit

class PinAnnotationClass: NSObject, MKAnnotation {
    var title: String? = "Draggable Pin"
    var subtitle: String? = ""
    var coordinate: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
}