//
//  FlickrConstants.swift
//  VirtualTourist
//
//  Created by Wojtek Materka on 11/02/2016.
//  Copyright © 2016 Wojtek Materka. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    // set of constants for the Flickr Client
    struct Constants {
        static let BASE_URL = "https://api.flickr.com/services/rest/"
        static let METHOD_NAME = "flickr.photos.search"
        static let API_KEY = "158ec8315e07a0e93044f2e16e9c8e76"
        static let EXTRAS = "url_m"
        static let SAFE_SEARCH = "1"
        static let DATA_FORMAT = "json"
        static let NO_JSON_CALLBACK = "1"
        static let BOUNDING_BOX_HALF_WIDTH = 0.1
        static let BOUNDING_BOX_HALF_HEIGHT = 0.1
        static let PICTURE_FETCH_LIMIT = 18
        static let PHOTOS_PER_PAGE = "100"
    }
    
    struct JSONReturnKeys {
        static let URLKey = "url_m"
    }
    
    struct Errors {
        static let NoPictureError = "No Picture Found"
    }
    
}