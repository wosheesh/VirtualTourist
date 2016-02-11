//
//  PhotoAlbumVC.swift
//  VirtualTourist
//
//  Created by Wojtek Materka on 10/02/2016.
//  Copyright © 2016 Wojtek Materka. All rights reserved.
//

import UIKit
import MapKit



class PhotoAlbumVC: UIViewController, MKMapViewDelegate {
    
    // MARK: - Properties
    
    @IBOutlet weak var locationMap: MKMapView!
    @IBOutlet weak var photoCollection: UICollectionView!
    @IBOutlet weak var bottomButton: UIButton!
    
    var pin: MKAnnotation?
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        
        // load the pin passed from TravelLocationsVC to the mapView and center the view
        locationMap.addAnnotation(pin!)
        let span = MKCoordinateSpanMake(0.5, 0.5)
        let region = MKCoordinateRegion(center: (pin?.coordinate)!, span: span)
        locationMap.setRegion(region, animated: true)
        
        
    }
    
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource

// TODO: Add UICollectionViewDataSource delegate in storyboard

extension PhotoAlbumVC: UICollectionViewDelegate {
    
}