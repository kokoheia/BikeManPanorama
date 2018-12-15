//
//  StageCell.swift
//  BikeManPanorama
//
//  Created by Kohei Arai on 2018/12/15.
//  Copyright © 2018年 Kohei Arai. All rights reserved.
//

import UIKit

class StageCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    var disabledHighlightedAnimation = false
    
    override func awakeFromNib() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = .init(width: 0, height: 4)
        layer.shadowRadius = 12
    }
}
