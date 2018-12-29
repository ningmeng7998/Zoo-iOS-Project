//
//  AnimalCell.swift
//  MonashCompanion
//
//  Created by ning li on 27/8/18.
//  Copyright © 2018 ning li. All rights reserved.
//

import UIKit

class AnimalCell: UITableViewCell {

    
    @IBOutlet weak var iconImage: UIImageView!
    
    @IBOutlet weak var animalNameLabel: UILabel!
    
    @IBOutlet weak var animalDescriptionLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        iconImage.image = nil
    }

}
