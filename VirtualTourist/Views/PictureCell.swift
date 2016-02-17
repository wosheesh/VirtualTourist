//
//  PictureCell.swift
//  VirtualTourist
//
//  Created by Wojtek Materka on 13/02/2016.
//  Copyright © 2016 Wojtek Materka. All rights reserved.
//

import UIKit

class PictureCell: UICollectionViewCell {
    
    @IBOutlet weak var pictureView: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        updateWithPicture(nil)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        updateWithPicture(nil)
    }
    
    /// Manages the activity indicator of the cell
    func updateWithPicture(image: UIImage?) {
        if let pictureToDisplay = image {
            spinner.stopAnimating()
            pictureView.image = pictureToDisplay
        } else {
            spinner.startAnimating()
            pictureView.image = nil
        }
    }
    
    
    
}


