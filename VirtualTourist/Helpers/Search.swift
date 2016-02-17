//
//  Search.swift
//  VirtualTourist
//
//  Created by Wojtek Materka on 13/02/2016.
//  Copyright © 2016 Wojtek Materka. All rights reserved.
//

import CoreData
import UIKit

let notificationForSearchStart = "com.wojtekmaterka.virtualtourist.searchstart"
let notificationForSearchEnd = "com.wojtekmaterka.virtualtourist.searchend"

class Search {
    
    /// Helper function to control the Flickr search function.
    /// Coordinates the picture download and creation of core data entities.
    func searchForPicturesWithPin(pin: Pin, context: NSManagedObjectContext) {
        
        NSNotificationCenter.defaultCenter().postNotificationName(notificationForSearchStart, object: nil)
        
        FlickrClient.sharedInstance().searchPhotosByCoords(pin.coordinate) { results, errorString in
            
            if let errorString = errorString {
                print("❔ ☎️ possible error @Flickr or no pictures: \(errorString)")
                NSNotificationCenter.defaultCenter().postNotificationName(notificationForSearchEnd, object: nil, userInfo: ["numberOfPics" : 0])
            } else if pin.managedObjectContext == nil {
                print("💔 💾 trying to create a relationship to a deleted pin")
            } else {
                print("💾 instantiating new Picture objects in CoreData")
                
                // instantiating new Picture objects in CoreData
                let picturesFound = Picture.picturesFromFlickrResults(pin, results: results!, context: context)
                
                NSNotificationCenter.defaultCenter().postNotificationName(notificationForSearchEnd, object: nil, userInfo: ["numberOfPics" : picturesFound.count])
        
                print("💾 created \(picturesFound.count) Picture objects")
                
                for picture in picturesFound {
                    
                    self.downloadPicture(picture)
                }
                
                CoreDataStackManager.sharedInstance().saveContext()
            }
        }
        
    }

    func downloadPicture(picture : Picture) {
        
        let url = NSURL(string: picture.flickrPath)!
        
        let request = NSURLRequest(URL: url)
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            if let error = error {
                print("🆘 ☎️ Couldn't download pictures: \(error)")
            }
            
            if let data = data {
                // set the filename as the local identifier
                picture.picturePath = NSURL(string: picture.flickrPath)!.lastPathComponent!
                
                // save the file
                let image = UIImage(data: data)
                picture.pictureFile = image
   
                print("🌈 Downloaded and saved \(picture.picturePath!)")
                
                CoreDataStackManager.sharedInstance().saveContext()
            }
            
        }
        
        task.resume()
        
    }
    
    // MARK: - Singleton
    
    class func sharedInstance() -> Search {
        struct Static {
            static let instance = Search()
        }
        
        return Static.instance
    }
    
}