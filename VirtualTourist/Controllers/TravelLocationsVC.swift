//
//  TravelLocationsVC.swift
//  VirtualTourist
//
//  Created by Wojtek Materka on 10/02/2016.
//  Copyright © 2016 Wojtek Materka. All rights reserved.
//

import UIKit
import MapKit

class TravelLocationsVC: UIViewController, MKMapViewDelegate {
    
    // MARK: - Properties
    
    @IBOutlet weak var travelMap: MKMapView!
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        
        // load all locations as annotations and add to the locationMap
        
        // recognise long press on the map
        let longPress = UILongPressGestureRecognizer(target: self, action: "userPressedOnMap:")
        longPress.minimumPressDuration = 1.0
        travelMap.addGestureRecognizer(longPress)
    }
    
    
    // MARK: - Actions
    
    func userPressedOnMap(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state != .Began { return }
        // TODO: implement drag gesture
        print("user pressed on map for longer")
        
        let touchPoint = gestureRecognizer.locationInView(travelMap)
        let newCoord = travelMap.convertPoint(touchPoint, toCoordinateFromView: travelMap)
        
        
        let newAnnotation = MKPointAnnotation()
        newAnnotation.coordinate = newCoord

        travelMap.addAnnotation(newAnnotation)
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.animatesDrop = true
            pinView!.pinTintColor = UIColor(red: 0.984, green: 0.227, blue: 0.184, alpha: 1.00)
            pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        //TODO: Segue if a pin is tapped
    }
    

}



