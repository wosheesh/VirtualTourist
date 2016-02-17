//
//  PhotoAlbumVC.swift
//  VirtualTourist
//
//  Created by Wojtek Materka on 10/02/2016.
//  Copyright © 2016 Wojtek Materka. All rights reserved.
//

// TODO: improve the picture aspect ratio

import UIKit
import MapKit
import CoreData


class PhotoAlbumVC: UIViewController, MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    
    // MARK: - 🎛 Properties
    
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
        
        // subscribe to search notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "flickrSearchDidStart", name: notificationForSearchStart, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "flickrSearchDidEnd:", name: notificationForSearchEnd, object: nil)
        
        // perform the fetch from CoreData
        print("💾 starting fetch in PhotoAlbum")
        do {
            try fetchedResultsController.performFetch()
            print("💾 performed PhotoAlbum fetch")
            
        } catch let error as NSError {
            print("🆘 💾failed to perform fetch on \(__FUNCTION__), error: \(error)")
        }
        
        // some UI setup
        updateUI("Didn't find anything here...")
        updateBottomButton()
        
        // load the pin passed from TravelLocationsVC to the mapView and center the view
        locationMap.addAnnotation(pin)
        let span = MKCoordinateSpanMake(0.5, 0.5)
        let region = MKCoordinateRegion(center: pin.coordinate, span: span)
        locationMap.setRegion(region, animated: true)

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Lay out the collection view so that cells take up 1/3 of the width,
        // with no space in between.
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let width = floor(self.photoCollection.frame.size.width/3)
        layout.itemSize = CGSize(width: width, height: width)
        photoCollection.collectionViewLayout = layout
    }
    
    // MARK: - 💥 Actions

    @IBAction func bottomButtonClicked(sender: AnyObject) {
        if selectedIndexes.isEmpty {
            deleteAllPictures()
            
            updateUI("Looking for new pictures...")
            
            // search Flickr
            Search.sharedInstance().searchForPicturesWithPin(pin, context: sharedContext)
            
        } else {
            deleteSelectedPictures()
            updateUI("You have deleted all pictures. Click \"New Collection\" to look for more.")
            
        }
        
        updateBottomButton()
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
    
    // MARK: - 📬 Notification handling

    func flickrSearchDidStart() {
        print("📬 flickrSearchDidStart")
        
        self.bottomButton.enabled = false

    }
    
    func flickrSearchDidEnd(notification: NSNotification) {
        print("📬 flickrSearchDidEnd")
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            // just in case the flickr search drops out
            if let info = notification.userInfo where info["numberOfPics"] as! Int > 0 {
                self.photoCollection.hidden = false
            } else {
                self.collectionLabel.text = "I didn't find any photos. Try again?"
            }
            
//             bring back the bottom button
            self.bottomButton.enabled = true
        })
        
    }
    
    // MARK: - 🗃 UICollectionViewDelegate, UICollectionViewDataSource
    
    func configureCell(cell: PictureCell, atIndexPath indexPath: NSIndexPath) {
        let pic = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Picture
        
        NSOperationQueue.mainQueue().addOperationWithBlock() {  
            cell.updateWithPicture(pic.pictureFile)
        }
        
        if let _ = selectedIndexes.indexOf(indexPath) {
            cell.pictureView.alpha = 0.5
        } else {
            cell.pictureView.alpha = 1.0
        }
        
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        let numberOfCells = sectionInfo.numberOfObjects

        return numberOfCells
    }
    
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PictureCell", forIndexPath: indexPath) as! PictureCell
        
        self.configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        // toggle the cell presences in the helper index
        if let index = selectedIndexes.indexOf(indexPath) {
            selectedIndexes.removeAtIndex(index)
        } else {
            selectedIndexes.append(indexPath)
        }
        
        // change the appearance of the cell if it is visible
        if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? PictureCell {
            configureCell(cell, atIndexPath: indexPath)
        }
        
        // change the bottom button text
        updateBottomButton()
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
    

    // MARK: - 🐕 Fetched Results Controller Delegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
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
    
    // MARK: 🐵 - Helpers
    
    func updateUI(message: String?) {
        if pin.pictures.count == 0 {
            collectionLabel.hidden = false
            self.photoCollection.hidden = true
            
            collectionLabel.text = message
        } else {
            collectionLabel.hidden = true
            self.photoCollection.hidden = false
        }
    }
    
    func updateBottomButton() {
        if selectedIndexes.count > 0 {
            bottomButton.title = "Remove Photos"
        } else {
            bottomButton.title = "New Collection"
        }
    }
    
}

   
    
