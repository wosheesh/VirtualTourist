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
    
    // MARK: - Helpers
    
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
    
    // TODO: image function to return or delete UIImage from Documents / Cache
    
    

    
}
