//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Wojtek Materka on 11/02/2016.
//  Copyright © 2016 Wojtek Materka. All rights reserved.
//

import UIKit
import MapKit

class FlickrClient: NSObject {
    
    // MARK: - Properties
    var session = NSURLSession.sharedSession()
    
    // cache
    struct Caches {
        static let pictureCache = PictureCache()
    }
    
    // MARK: - Flickr API
    
    /// Searches Flickr for pictures around "bbox" area and returns an array of up to PICTURE_FETCH_LIMIT
    /// JSON-formatted photo objects. If Flickr had no photos in the area returns an errorString.
    func searchPhotosByCoords(coords: CLLocationCoordinate2D, completionHandler: (results: [[String : AnyObject]]?, errorString: String?) -> Void) {
        
        let methodArguments = [
            "method": Constants.METHOD_NAME,
            "api_key": Constants.API_KEY,
            "bbox": createBoundingBoxString(coords),
            "safe_search": Constants.SAFE_SEARCH,
            "extras": Constants.EXTRAS,
            "format": Constants.DATA_FORMAT,
            "nojsoncallback": Constants.NO_JSON_CALLBACK,
            "per_page": Constants.PHOTOS_PER_PAGE
        ]
        
        // Make first request to get a random page, then another to get a smaller array of images from the selected page
        taskForFlickrRequest(methodArguments) { JSONResult, error in
            
            if let stat = JSONResult["stat"] as? String where stat == "ok",
                let photosDictionary = JSONResult["photos"] as? NSDictionary,
                let totalPages = photosDictionary["pages"] as? Int {
                    
                    print("found \(totalPages) pages on Flickr")
                    
                    // handle the situation where no pictures found
                    if totalPages == 0 {
                        completionHandler(results: nil, errorString: "No pictures found")
                        return
                    }
                
                    // if there's just one page, pass some pictures from it
                    if totalPages == 1,
                        let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] {
                        
                            print("found \(photosArray.count) photos on the 1st page")
                        
                            // just get the first few pictures
                            let pictureLimit = min(photosArray.count, Constants.PICTURE_FETCH_LIMIT)
                            let firstPictures = Array(photosArray.prefix(pictureLimit))
                        
                            completionHandler(results: firstPictures, errorString: nil)
                            print("🖼 downloaded \(firstPictures.count) pictures")
                            return
                    }
                    
                    // if there's multiple pages pick a random page and add it to the request parameters
                    // don'f forget that Flickr only will only return 4000 photos so (100 per page * 40)
                    let pageLimit = min(totalPages, 40)
                    let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                    var withPageDictionary = methodArguments as [String : AnyObject]
                    withPageDictionary["page"] = randomPage
        
                    self.taskForFlickrRequest(withPageDictionary) { (JSONResult, error) -> Void in
                        print("Lookin for pictures from page: \(randomPage)")
                        
                        print("results \(JSONResult)")
                        
                        if let stat = JSONResult["stat"] as? String where stat == "ok",
                            let resultsDictionary = JSONResult["photos"] as? NSDictionary,
                            let totalPhotosVal = (resultsDictionary["total"] as? NSString)?.integerValue where totalPhotosVal > 0,
                            let photosArray = resultsDictionary["photo"] as? [[String: AnyObject]] {
        
                                print("found \(photosArray.count) photos after multiple pages search")

                                // just get the first few pictures
                                let pictureLimit = min(photosArray.count, Constants.PICTURE_FETCH_LIMIT)
                                let firstPictures = Array(photosArray.prefix(pictureLimit))
                                
                                completionHandler(results: firstPictures, errorString: nil)
                                print("🖼 downloaded \(firstPictures.count) pictures")
                        }
                    }
                    
                } else {
                    print("🆘 Error completing Flickr search")
                    completionHandler(results: nil, errorString: "Error completing Flickr search")
                }
            
        }
    }
        
    /// Runs a Flickr API request based on methodParameters, returns results and/or NSError through completion handler
    func taskForFlickrRequest(methodParameters: [String : AnyObject], completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        
        let urlString = Constants.BASE_URL + escapedParameters(methodParameters)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        print("☎️ Making a Flickr request...")
        print(" 🌂  method parameter page : \(methodParameters["page"])")
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("🆘 There was an error with your request: \(error)")
                completionHandler(result: nil, error: NSError(domain: "taskForFlickrRequest", code: 0,
                    userInfo: [NSLocalizedDescriptionKey : "There was an error while requesting data from Flickr"]))
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    print("🆘 Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    print("🆘 Your request returned an invalid response! Response: \(response)!")
                } else {
                    print("🆘 Your request returned an invalid response!")
                }
                completionHandler(result: nil, error: NSError(domain: "taskForFlickrRequest", code: 0,
                    userInfo: [NSLocalizedDescriptionKey : "There was an error while requesting data from Flickr"]))
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                print("🆘 No data was returned by the request!")
                completionHandler(result: nil, error: NSError(domain: "taskForFlickrRequest", code: 0,
                    userInfo: [NSLocalizedDescriptionKey : "There was an error while requesting data from Flickr"]))
                return
            }
            
            /* Parse the data! */
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
                completionHandler(result: parsedResult, error: nil)
            } catch {
                parsedResult = nil
                print("🆘 Could not parse the data as JSON: '\(data)'")
                completionHandler(result: nil, error: NSError(domain: "taskForFlickrRequest", code: 0,
                    userInfo: [NSLocalizedDescriptionKey : "There was an error while requesting data from Flickr"]))
            }
        }
        
        task.resume()
  
    }
    
    // MARK: Coordinate manipulation
    /// Used to create a bounding box for flickr geo query.
    /// Returns a String that can be used in "bbox" API argument.
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