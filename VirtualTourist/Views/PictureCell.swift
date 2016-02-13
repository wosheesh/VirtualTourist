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
    @IBOutlet weak var picPlaceholderLabel: UILabel!
    
    var imagePathString: String {
        set {
            self.picPlaceholderLabel.text = newValue
        }
        
        get {
            return self.picPlaceholderLabel.text ?? "Loading"
        }
    }
}

//@IBOutlet weak var colorPanel: UIView!
//
//var color: UIColor {
//set {
//    self.colorPanel.backgroundColor = newValue
//}
//
//get {
//    return self.colorPanel.backgroundColor ?? UIColor.whiteColor()
//}
//}
//}
