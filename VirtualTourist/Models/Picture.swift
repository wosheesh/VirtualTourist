//
//  Picture.swift
//  VirtualTourist
//
//  Created by Wojtek Materka on 10/02/2016.
//  Copyright © 2016 Wojtek Materka. All rights reserved.
//

import CoreData

class Picture: NSManagedObject {
    
    @NSManaged var picturePath: String
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(path: String, context: NSManagedObjectContext) {
        
        // CoreData
        let entity = NSEntityDescription.entityForName("Picture", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Init Properties
        picturePath = path
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
    
    
    
    // TODO: image function to return or delete UIImage from Documents / Cache
    override func prepareForDeletion() {
        //Delete associated image files from imagePath automatically
//        if let fileName = imageFilePath?.lastPathComponent {
//            
//            let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
//            let pathArray = [dirPath, fileName]
//            let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
//            
//            NSFileManager.defaultManager().removeItemAtURL(fileURL, error: nil)
//        }
    }
    
    
    
    
    
    
}
