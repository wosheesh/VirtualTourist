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


class PhotoAlbumVC: UIViewController, MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    
    // MARK: - Properties
    
    // used to keep track of selected picture cells - for UI updates and deletions.
    var selectedIndexes = [NSIndexPath]()
    
    // for communicating changes between CoreData and CollectionView
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    @IBOutlet weak var locationMap: MKMapView!
    @IBOutlet weak var photoCollection: UICollectionView!
    @IBOutlet weak var collectionLabel: UILabel!
    @IBOutlet weak var bottomButton: UIBarButtonItem!
    
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
        
        updateBottomButton()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // TODO: pre-fetch the pictures after dropping the pin
        
        // load the array of pictures from the area around the pin
        // add them to a the collection view
        
        if pin.pictures.isEmpty {
            
            FlickrClient.sharedInstance().searchPhotosByCoords(pin.coordinate) { results, errorString in
                if let errorString = errorString {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.photoCollection.hidden = true
                        self.collectionLabel.hidden = false
                        self.collectionLabel.text = errorString
                    })
                } else {
                    
                    let picturesFound = Picture.picturesFromFlickrResults(self.pin, results: results!, context: self.sharedContext)
                    
                    print("💾 creating \(picturesFound.count)Picture objects")
                    self.saveContext()
 
                }

            }
        } else {
            print("this pin already had some data --> 🖼")
        }
        

    }
    
    // MARK: - 💥 Actions

    @IBAction func bottomButtonClicked(sender: AnyObject) {
        if selectedIndexes.isEmpty {
            deleteAllPictures()
        } else {
            deleteSelectedPictures()
        }
    }
    
    func deleteAllPictures() {
        for picture in fetchedResultsController.fetchedObjects as! [Picture] {
            sharedContext.deleteObject(picture)
        }
        
        saveContext()
        
        print("🔥 Deleted all pictures in current collection")
    }
    
    func deleteSelectedPictures() {
        var picturesToDelete = [Picture]()
        
        for indexPath in selectedIndexes {
            picturesToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Picture)
        }
        
        for picture in picturesToDelete {
            sharedContext.deleteObject(picture)
        }
        
        saveContext()
        
        selectedIndexes = [NSIndexPath]()
        print("⚡️ removed selected pictures")
    }
    
    func updateBottomButton() {
        if selectedIndexes.count > 0 {
            bottomButton.title = "Remove Photos"
        } else {
            bottomButton.title = "New Collection"
        }
    }

    
    
    // MARK: - 💾 Core Data
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Picture")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    
    // MARK: - UICollectionViewDelegate, UICollectionViewDataSource
    
    func configureCell(cell: PictureCell, atIndexPath indexPath: NSIndexPath) {
        let pic = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Picture
        
        cell.imagePathString = pic.picturePath
        
        if let index = selectedIndexes.indexOf(indexPath) {
            cell.picPlaceholderLabel.alpha = 0.5
        } else {
            cell.picPlaceholderLabel.alpha = 1.0
        }
        
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        
        print("number of pictureCells: \(sectionInfo.numberOfObjects)")
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PictureCell", forIndexPath: indexPath) as! PictureCell
        
        self.configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PictureCell
        
        // toggle the cell presences in the helper index
        if let index = selectedIndexes.indexOf(indexPath) {
            selectedIndexes.removeAtIndex(index)
        } else {
            selectedIndexes.append(indexPath)
        }
        
        // change the appearance of the cell
        configureCell(cell, atIndexPath: indexPath)
        
        // change the bottom button text
        updateBottomButton()
    }

    // MARK: - Fetched Results Controller Delegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
        print("in controllerWillChangeContent")
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
        case .Delete:
            deletedIndexPaths.append(indexPath!)
        case .Update:
            updatedIndexPaths.append(indexPath!)
        case .Move:
            print("move an item - not expected")
        default:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        print("ControllerDidChangeContent inserted: \(insertedIndexPaths.count) deleted: \(deletedIndexPaths.count)")
        
        photoCollection.performBatchUpdates({ () -> Void in
            for indexPath in self.insertedIndexPaths {
                self.photoCollection.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.photoCollection.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.photoCollection.reloadItemsAtIndexPaths([indexPath])
                
            }
            }, completion: nil)
    }
    
}

   
    
