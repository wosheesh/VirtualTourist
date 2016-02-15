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
    
    // MARK: - 🔄 LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // some UI setup
        collectionLabel.hidden = true
        
        // subscribe to search notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "flickrSearchDidStart", name: notificationForSearchStart, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "flickrSearchDidEnd", name: notificationForSearchEnd, object: nil)
        
        // perform the fetch from CoreData
        print("💾 starting fetch in PhotoAlbum")
        do {
            try fetchedResultsController.performFetch()
            print("💾 performed PhotoAlbum fetch")
        } catch let error as NSError {
            print("🆘 💾failed to perform fetch on \(__FUNCTION__), error: \(error)")
        }
        
        // load the pin passed from TravelLocationsVC to the mapView and center the view
        locationMap.addAnnotation(pin)
        let span = MKCoordinateSpanMake(0.5, 0.5)
        let region = MKCoordinateRegion(center: pin.coordinate, span: span)
        locationMap.setRegion(region, animated: true)
        


        updateBottomButton()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

    }
    
    // MARK: - 💥 Actions

    @IBAction func bottomButtonClicked(sender: AnyObject) {
        if selectedIndexes.isEmpty {
            deleteAllPictures()
            
            // search Flickr
            
            Search().Flickr(pin, context: sharedContext)
            // TODO: Update collection view after data reloaded
            
            self.collectionLabel.text = "Looking for photos..."
            
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
    
    // MARK: - 📬 Notification handling

    func flickrSearchDidStart() {
        print("📬 flickrSearchDidStart")
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.photoCollection.hidden = true
            self.collectionLabel.hidden = false
            self.collectionLabel.text = "Looking for photos..."
            self.bottomButton.enabled = false
        })
        
        
    }
    
    func flickrSearchDidEnd() {
        print("📬 flickrSearchDidEnd")
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.bottomButton.enabled = true
        })
        
    }
    
    // MARK: - 💾 Core Data
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Picture")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        print("💾 instantiated fetchedREsultsController in PhotoAlbum")
        return fetchedResultsController
    }()
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    
    // MARK: -  UICollectionViewDelegate, UICollectionViewDataSource
    
    func configureCell(cell: PictureCell, atIndexPath indexPath: NSIndexPath) {
        let pic = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Picture
        
        cell.imagePathString = pic.picturePath
        
        if let _ = selectedIndexes.indexOf(indexPath) {
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
        let numberOfCells = sectionInfo.numberOfObjects
        
        if numberOfCells == 0 {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.photoCollection.hidden = true
                self.collectionLabel.hidden = false
                self.collectionLabel.text = "No Photos found at this location"
                self.updateBottomButton()
            })
        } else {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.photoCollection.hidden = false
                self.collectionLabel.hidden = true
                self.updateBottomButton()
            })
        }

        print("number of pictureCells: \(numberOfCells)")
        return numberOfCells
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

    // MARK: - 🐕 Fetched Results Controller Delegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        print(" 🐕 in controllerWillChangeContent")
        
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        

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
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        print(" 🐕 ControllerDidChangeContent inserted: \(insertedIndexPaths.count) deleted: \(deletedIndexPaths.count)")
        
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

   
    
