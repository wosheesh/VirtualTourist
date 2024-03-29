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
    
    // MARK: - 🎛 Properties
    
    @IBOutlet weak var travelMap: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var bottomInfoLabel: UILabel!

    // MARK: - 🔄 Lifecycle
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // reset the title
        navigationItem.title = "Virtual Tourist"
        

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // perform CoreData fetch
        do {
            try fetchedResultsController.performFetch()
            print("📍fetched \(fetchedResultsController.fetchedObjects!.count) pins ")
        } catch {
            print("🆘📍Failed to perform fetch for Pins")
        }

        // set the delegates
        fetchedResultsController.delegate = self
        travelMap.delegate = self
        
        // load and add Pins to the mapView
        travelMap.addAnnotations(loadAllPins())
        
        // add a gesture recogniser to the map for adding pins
        let longPress = UILongPressGestureRecognizer(target: self, action: "userPressedOnMap:")
        longPress.minimumPressDuration = 1.0
        travelMap.addGestureRecognizer(longPress)
    }
    
    // MARK: - 💥 Actions
    
    var pinToBeAdded: Pin? = nil
    
    /// Adds a pin to the mapView and a Pin object to CoreData.
    /// Manages the drag gesture of the pin.
    func userPressedOnMap(gestureRecognizer: UIGestureRecognizer) {
        
        let touchPoint = gestureRecognizer.locationInView(travelMap)
        let touchCoord = travelMap.convertPoint(touchPoint, toCoordinateFromView: travelMap)
        
        switch gestureRecognizer.state {
        case .Began:
            pinToBeAdded = Pin(annotationLatitude: touchCoord.latitude,
                annotationLongitude: touchCoord.longitude, context: sharedContext)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.travelMap.addAnnotation(self.pinToBeAdded!)
            })
        
        // using KVO manually to allow the map view to re-read 
        // the coordinate property through the pinToBeAdded object
        case .Changed:
            pinToBeAdded!.willChangeValueForKey("coordinate")
            pinToBeAdded!.coordinate = touchCoord
            pinToBeAdded!.didChangeValueForKey("coordinate")
            
        case .Ended:
            Search.sharedInstance().searchForPicturesWithPin(pinToBeAdded!, context: sharedContext)
            saveContext()
            
        default:
            return
        }
        
    }
    
    /// Updates the UI for editing or deleting state. 
    /// The button state is later used to distinguish the edition state
    @IBAction func editButtonTouchUp(sender: AnyObject) {
        if editButton.title == "Edit" {
            editButton.title = "Done"
            hideBottomInfoLabel(false)
        } else {
            editButton.title = "Edit"
            hideBottomInfoLabel(true)
        }
        
    }
    
    // MARK: - 💾 CoreData Helpers
    
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
    
    // MARK: - 🗺 MKMapViewDelegate
    
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
        
        print("📍 tapped")
        
        if editButton.title == "Edit" {
            // editing mode:
            
            // pass the selected pin to PhotoAlbumVC
            let controller = storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbum") as! PhotoAlbumVC
            
            controller.pin = view.annotation as! Pin
            
            // change the back button title in the next controller by changing current title
            navigationItem.title = "OK"
            
            navigationController!.pushViewController(controller, animated: true)
            
            // making sure the pin is deselected so it can be tapped again consecutively
            travelMap.deselectAnnotation(view.annotation, animated: true)
            
        } else if editButton.title == "Done" {
            // deleting mode:
            
            let pinToDelete = view.annotation as! Pin
            
            sharedContext.deleteObject(pinToDelete)
            travelMap.removeAnnotation(pinToDelete)
            
      
            saveContext()
            
        }

    }
    
    // MARK: - 🐵 Helpers
    
    /// switches the visibility of the text label on the stackView
    func hideBottomInfoLabel(show: Bool) {
        dispatch_async(dispatch_get_main_queue()) {
            UIView.animateWithDuration(0.25) { () -> Void in
                let label = self.stackView.arrangedSubviews[1]
                label.hidden = show
            }
        }
    }


}



