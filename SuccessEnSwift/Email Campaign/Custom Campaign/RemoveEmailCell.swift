//
//  RemoveEmailCell.swift
//  SuccessEnSwift
//
//  Created by Milind Kudale on 11/10/18.
//  Copyright © 2018 milind.kudale. All rights reserved.
//

import UIKit

class RemoveEmailCell: UITableViewCell {

    @IBOutlet var imgView : UIImageView!
    @IBOutlet var lblMemberName : UILabel!
    @IBOutlet var lblMemberEmail : UILabel!
    @IBOutlet var lblAssignedDate : UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
