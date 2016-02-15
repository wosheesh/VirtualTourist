//
//  PictureCache.swift
//  VirtualTourist
//
//  Created by Wojtek Materka on 15/02/2016.
//  Copyright © 2016 Wojtek Materka. All rights reserved.
//

import UIKit

class PictureCache {
    
    // MARK: - Properties
    
    // MARK: - Retreiving pictures
    func pictureWithIdentifier(identifier: String?) -> UIImage? {
        if identifier == nil || identifier! == "" {
            return nil
        }
        
        let path = pathForIdentifier(identifier!)
        
        if let data = NSData(contentsOfFile: path) {
            print("📂 retriving picture from file")
            return UIImage(data: data)
        }
        
        return nil
    }
    
    // MARK: - Saving pictures
    func storePicture(picture: UIImage?, withIdentifier identifier: String) {
        print("📂 storing picture on disk")
        
        let path = pathForIdentifier(identifier)
        let data = UIImageJPEGRepresentation(picture!, 1.0)!
        data.writeToFile(path, atomically: true)
    }
    
    // MARK: - Helpers
    func pathForIdentifier(identifier: String) -> String {
        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(identifier)
        
        return fullURL.path!
    }
}
