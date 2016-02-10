//
//  TravelLocationsVC.swift
//  VirtualTourist
//
//  Created by Wojtek Materka on 10/02/2016.
//  Copyright © 2016 Wojtek Materka. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsVC: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    // MARK: - Properties
    
    @IBOutlet weak var travelMap: MKMapView!
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // perform CoreData fetch
        do {
            try fetchedResultsController.performFetch()
            print("fetched pins")
        } catch {
            print("Failed to perform fetch for Pins")
        }
        
        // set the delegate for fetchedResultsController
        fetchedResultsController.delegate = self
        
        // declare annotations array for the map
        var annotations = [MKPointAnnotation]()
        
        // load all locations as Pins from context
        let locations = loadAllPins()
        print(locations)
        
        // ... and and add them to the locationMap
        for location in locations {
            let lat = CLLocationDegrees(location.latitude) 
            let long = CLLocationDegrees(location.longitude)
            let coordinate = CLLocationCoordinate2DMake(lat, long)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            annotations.append(annotation)
        }
        
        // add annotations to the mapView
        travelMap.addAnnotations(annotations)
        
        // add a gesture recogniser to the map for adding pins
        let longPress = UILongPressGestureRecognizer(target: self, action: "userPressedOnMap:")
        longPress.minimumPressDuration = 1.0
        travelMap.addGestureRecognizer(longPress)
    }
    
    
    
    // MARK: - Actions
    
    func userPressedOnMap(gestureRecognizer: UIGestureRecognizer) {
        
        // TODO: implement drag gesture
        if gestureRecognizer.state != .Began { return }
        print("user pressed on map for longer")
        
        let touchPoint = gestureRecognizer.locationInView(travelMap)
        let newCoord = travelMap.convertPoint(touchPoint, toCoordinateFromView: travelMap)
        
        let newAnnotation = MKPointAnnotation()
        newAnnotation.coordinate = newCoord
        
        // add a new Pin object to the database
        let pinToBeAdded = Pin(coordinates: newCoord, context: sharedContext)

        // add the new annotation to the map
        travelMap.addAnnotation(newAnnotation)
        
        // save the change in the CoreData
        saveContext()
    }
    
    // MARK: - CoreData Helpers
    
    func loadAllPins() -> [Pin] {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        do {
            return try sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
        } catch _ {
            return [Pin]()
        }
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = []
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultsController
    }()
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
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



