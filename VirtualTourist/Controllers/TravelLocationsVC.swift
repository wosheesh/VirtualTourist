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
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    // MARK: - Lifecycle
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.title = "Virtual Tourist"
        
        
        
    }

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
        
        // load all locations as Pins from context
        let locations = loadAllPins()
        
        // add annotations to the mapView
        travelMap.addAnnotations(locations)
        
        // add a gesture recogniser to the map for adding pins
        let longPress = UILongPressGestureRecognizer(target: self, action: "userPressedOnMap:")
        longPress.minimumPressDuration = 1.0
        travelMap.addGestureRecognizer(longPress)
    }
    
    // MARK: - Actions
    
    func userPressedOnMap(gestureRecognizer: UIGestureRecognizer) {
        
        // TODO: implement drag gesture
        
        let touchPoint = gestureRecognizer.locationInView(travelMap)
        let touchCoord = travelMap.convertPoint(touchPoint, toCoordinateFromView: travelMap)
        
        if UIGestureRecognizerState.Began == gestureRecognizer.state {
            
            // create a new Pin object in CoreData
            let newPin = Pin(annotationLatitude: touchCoord.latitude,
                annotationLongitude: touchCoord.longitude,
                context: sharedContext)
            
            // add the new annotation to the map
            travelMap.addAnnotation(newPin)
            
            // save the change in the CoreData
            saveContext()
        }
  
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
            pinView!.canShowCallout = false
            pinView!.animatesDrop = true
            pinView!.pinTintColor = UIColor(red: 0.984, green: 0.227, blue: 0.184, alpha: 1.00)
            pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        let controller = storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbum") as! PhotoAlbumVC
        
        // passing the selected pin to PhotoAlbumVC
        controller.pin = view.annotation as! Pin
        
        // change the back button title in the next controller by changing current title
        navigationItem.title = "OK"
        
        // using nav controller to push the PhotoAlbumVC
        navigationController!.pushViewController(controller, animated: true)

    }


}



