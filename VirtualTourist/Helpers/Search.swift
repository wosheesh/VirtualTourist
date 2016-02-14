//
//  Search.swift
//  VirtualTourist
//
//  Created by Wojtek Materka on 13/02/2016.
//  Copyright © 2016 Wojtek Materka. All rights reserved.
//

import CoreData
import Foundation

let notificationForSearchStart = "com.wojtekmaterka.virtualtourist.searchstart"
let notificationForSearchEnd = "com.wojtekmaterka.virtualtourist.searchend"

class Search {
    
    /// Helper function to control the Flickr search function. Runs in UTILITY queue.
    func Flickr(pin: Pin, context: NSManagedObjectContext) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), { () -> Void in
            
            NSNotificationCenter.defaultCenter().postNotificationName(notificationForSearchStart, object: nil)
            
            FlickrClient.sharedInstance().searchPhotosByCoords(pin.coordinate) { results, errorString in
                if let errorString = errorString {
                    print("❔ ☎️ possible error @Flickr or no pictures: \(errorString)")
                } else {
                    
                    // instantiating new Picture objects in CoreData
                    let picturesFound = Picture.picturesFromFlickrResults(pin, results: results!, context: context)
                    
                    NSNotificationCenter.defaultCenter().postNotificationName(notificationForSearchEnd, object: nil)
                    
                    print("💾 created \(picturesFound.count) Picture objects")
                    
                    CoreDataStackManager.sharedInstance().saveContext()
                }
            }
        })
    }
}