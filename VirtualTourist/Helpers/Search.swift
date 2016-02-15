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
    func searchForPicturesWithPin(pin: Pin, context: NSManagedObjectContext) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), { () -> Void in
        
            NSNotificationCenter.defaultCenter().postNotificationName(notificationForSearchStart, object: nil)
            
            FlickrClient.sharedInstance().searchPhotosByCoords(pin.coordinate) { results, errorString in
                
                if let errorString = errorString {
                    print("❔ ☎️ possible error @Flickr or no pictures: \(errorString)")
                } else {
                    

                    if pin.managedObjectContext == nil {
                        print("💔 💾 trying to create a relationship to a deleted pin")
                        return
                    } else {
                        // wrap core data update in main queue!
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            print("💾 instantiating new Picture objects in CoreData")
                            
                            // instantiating new Picture objects in CoreData
                            let picturesFound = Picture.picturesFromFlickrResults(pin, results: results!, context: context)
                            
                            NSNotificationCenter.defaultCenter().postNotificationName(notificationForSearchEnd, object: nil)
                    
                            print("💾 created \(picturesFound.count) Picture objects")
                            
                            for picture in picturesFound {
                                
                                self.downloadPicture(picture)
                            }
                    
                            CoreDataStackManager.sharedInstance().saveContext()
                        })
                        

                        
                    }

                }
            }
        }) // utility queue
    }
    
    func downloadPicture(picture : Picture) {
        let url = NSURL(string: picture.flickrPath)!
        print("trying to download \(url)")
        
        let request = NSURLRequest(URL: url)
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            if let error = error {
                print("🆘 ☎️ Couldn't download pictures: \(error)")
            }
            
            if let data = data {
                let image = UIImage(data: data)
                
                // se the filename as the local identifier
                picture.picturePath = NSURL(string: picture.flickrPath)!.lastPathComponent!
                
                picture.pictureFile = image
                
                
                
                print("🌈 Downloaded \(picture.picturePath)")
            }
            
        }
        
        task.resume()
        
    }
    
}