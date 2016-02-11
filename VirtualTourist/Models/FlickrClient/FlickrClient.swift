//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Wojtek Materka on 11/02/2016.
//  Copyright © 2016 Wojtek Materka. All rights reserved.
//

import Foundation
import MapKit

class FlickrClient: NSObject {
    
    // MARK: - Properties
    
    // MARK: - Flickr API
    
    func searchPhotosByCoords(coords: CLLocationCoordinate2D) {
        
        let methodArguments = [
            "method": Constants.METHOD_NAME,
            "api_key": Constants.API_KEY,
            "bbox": createBoundingBoxString(coords),
            "safe_search": Constants.SAFE_SEARCH,
            "extras": Constants.EXTRAS,
            "format": Constants.DATA_FORMAT,
            "nojsoncallback": Constants.NO_JSON_CALLBACK,
            "page": 1
        ]
        
        
        let session = NSURLSession.sharedSession()
        let urlString = Constants.BASE_URL + escapedParameters(methodArguments as! [String:AnyObject])
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        print(url)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)!")
                } else {
                    print("Your request returned an invalid response!")
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                print("No data was returned by the request!")
                return
            }
            
            /* Parse the data! */
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                parsedResult = nil
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                print("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "photos" key in our result? */
            guard let photosDictionary = parsedResult["photos"] as? NSDictionary else {
                print("Cannot find key 'photos' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "total" key in photosDictionary? */
            guard let totalPhotosVal = (photosDictionary["total"] as? NSString)?.integerValue else {
                print("Cannot find key 'total' in \(photosDictionary)")
                return
            }
            
            if totalPhotosVal > 0 {
                
                print(" totalPhotosVal: \(totalPhotosVal)")
                print(photosDictionary)
                /* GUARD: Is the "photo" key in photosDictionary? */
                guard let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                    print("Cannot find key 'photo' in \(photosDictionary)")
                    return
                }
                
                let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                print(randomPhotoIndex)
                let photoDictionary = photosArray[randomPhotoIndex] as [String: AnyObject]
                let photoTitle = photoDictionary["title"] as? String /* non-fatal */
                
                /* GUARD: Does our photo have a key for 'url_m'? */
                guard let imageUrlString = photoDictionary["url_m"] as? String else {
                    print("Cannot find key 'url_m' in \(photoDictionary)")
                    return
                }
                
                let imageURL = NSURL(string: imageUrlString)
                if let imageData = NSData(contentsOfURL: imageURL!) {
                    print("got an image")
                } else {
                    print("Image does not exist at \(imageURL)")
                }
            } else {
                print("not found anything")
            }
        }
        
        task.resume()
        
    }
    
    // MARK: Coordinate manipulation
    func createBoundingBoxString(coords: CLLocationCoordinate2D) -> String {
        
        let latitude = coords.latitude
        let longitude = coords.longitude
        
        // Create a bounded box
        let bottom_left_lon = longitude - Constants.BOUNDING_BOX_HALF_WIDTH
        let bottom_left_lat = latitude - Constants.BOUNDING_BOX_HALF_HEIGHT
        let top_right_lon = longitude + Constants.BOUNDING_BOX_HALF_HEIGHT
        let top_right_lat = latitude + Constants.BOUNDING_BOX_HALF_HEIGHT
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    
    // MARK: Escape HTML Parameters
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    // MARK: - sharedInstance Singleton
    
    class func sharedInstance() -> FlickrClient {
        struct Static {
            static let instance = FlickrClient()
        }
        
        return Static.instance
    }
    
}