//
//  Picture.swift
//  VirtualTourist
//
//  Created by Wojtek Materka on 10/02/2016.
//  Copyright © 2016 Wojtek Materka. All rights reserved.
//

import CoreData
import UIKit
import Foundation

class Picture: NSManagedObject {
    
    // MARK: - Properties
    
    @NSManaged var picturePath: String?
    @NSManaged var flickrPath: String
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    // MARK: - Init
    
    init(path: String, context: NSManagedObjectContext) {
        
        // CoreData
        let entity = NSEntityDescription.entityForName("Picture", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // store the path to the picture of Flickr
        flickrPath = path
         
    }
    
    var pictureFile: UIImage? {
        get {
            return FlickrClient.Caches.pictureCache.pictureWithIdentifier(picturePath)
        }
        
        set {
            return FlickrClient.Caches.pictureCache.storePicture(newValue, withIdentifier: picturePath!)
        }
    }
    
    // MARK: - Convenience
    
    /// Make a picture object out of an array of Flickr JSON objects. Returns an array of Pictures.
    static func picturesFromFlickrResults(pin: Pin, results: [[String: AnyObject]], context: NSManagedObjectContext) -> [Picture] {
        var pictures = [Picture]()
        
        for result in results {
            let pathInResult = result[FlickrClient.JSONReturnKeys.URLKey] as! String
            let newPicture = Picture(path: pathInResult, context: context)

            // set the db relationship
            newPicture.pin = pin
            
            pictures.append(newPicture)
        }
        
        return pictures
    }
    
    /// Delete all files if picture is being deleted
    override func prepareForDeletion() {
        //Delete associated image files from imagePath automatically
        if let fileName = picturePath {
            
            let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
            let pathArray = [dirPath, fileName]
            let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
            do {
                try NSFileManager.defaultManager().removeItemAtURL(fileURL)
            } catch {
                print("🆘 📂 Couldn't delete a picture file")
            }

        } else {
            print("🆘 📂 Couldn't find a picture file for deletion" )
        }
    }
    
    
}
