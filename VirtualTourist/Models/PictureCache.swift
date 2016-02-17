//
//  PictureCache.swift
//  VirtualTourist
//
//  Created by Wojtek Materka on 15/02/2016.
//  Copyright © 2016 Wojtek Materka. All rights reserved.
//

import UIKit

// At this stage PictureCache uses disk only. No NSCache().

class PictureCache {
    
    // MARK: - 📂 Retreiving pictures
    
    /// Returns an UIImage given a String identifier.
    func pictureWithIdentifier(identifier: String?) -> UIImage? {
        if identifier == nil || identifier! == "" {
            return nil
        }
        
        let path = pathForIdentifier(identifier!)
        
        if let data = NSData(contentsOfFile: path) {
            return UIImage(data: data)
        }
        
        return nil
    }
    
    // MARK: - 💁 Convenience
    
    /// Saves a picture on disk with a an identifier as file name.
    func storePicture(picture: UIImage?, withIdentifier identifier: String) {
        
        let path = pathForIdentifier(identifier)
        let data = UIImageJPEGRepresentation(picture!, 1.0)!
        data.writeToFile(path, atomically: true)
    }
    
    // MARK: - 🐵 Helpers
    
    /// Returns a file path as String given an identifier.
    func pathForIdentifier(identifier: String) -> String {
        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(identifier)
        
        return fullURL.path!
    }
}
