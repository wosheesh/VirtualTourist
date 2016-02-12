//
//  PhotoAlbumVC.swift
//  VirtualTourist
//
//  Created by Wojtek Materka on 10/02/2016.
//  Copyright © 2016 Wojtek Materka. All rights reserved.
//

import UIKit
import MapKit
import CoreData


class PhotoAlbumVC: UIViewController, MKMapViewDelegate {
    
    // MARK: - Properties
    
    @IBOutlet weak var locationMap: MKMapView!
    @IBOutlet weak var photoCollection: UICollectionView!
    @IBOutlet weak var bottomButton: UIButton!
    @IBOutlet weak var collectionLabel: UILabel!
    
    var pin: Pin!
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // some UI setup
        collectionLabel.hidden = true
        
        // load the pin passed from TravelLocationsVC to the mapView and center the view
        locationMap.addAnnotation(pin)
        let span = MKCoordinateSpanMake(0.5, 0.5)
        let region = MKCoordinateRegion(center: pin.coordinate, span: span)
        locationMap.setRegion(region, animated: true)
        
        // perform the fetch from CoreData
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("failed to perform fetch on \(__FUNCTION__), error: \(error)")
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // TODO: pre-fetch the pictures after dropping the pin
        
        // load the array of pictures from the area around the pin
        // add them to a the collection view
        
        if pin.pictures.isEmpty {
            
            FlickrClient.sharedInstance().searchPhotosByCoords(pin.coordinate) { results, errorString in
                if let errorString = errorString {
                    self.photoCollection.hidden = true
                    self.collectionLabel.hidden = false
                    self.collectionLabel.text = errorString
                } else {
                    print("creating Picture objects")
                    let picturesFound = Picture.picturesFromFlickrResults(self.pin, results: results!, context: self.sharedContext)
                    print("saving Picture objects :")
                    self.saveContext()
                    print(picturesFound)

                    
                }

            }
        } else {
            print("this pin had some data -->")
            print("Pin pictures: \(pin.pictures)")
        }
        

    }
    
    
    // MARK: - Core Data
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Picture")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultsController
    }()
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource

// TODO: Add UICollectionViewDataSource delegate in storyboard

extension PhotoAlbumVC: UICollectionViewDelegate {
    
   
    
}