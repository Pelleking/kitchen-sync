//
//  CustomCollectionViewCell.swift
//  kitchen sync
//
//  Created by Pelle Fredrikson on 2023-07-19.
//

import Foundation
import UIKit

class CustomCollectionViewCell: UICollectionViewCell {
    var textLabel: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)

        textLabel = UILabel(frame: .zero)
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textLabel)

        NSLayoutConstraint.activate([
            textLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
        contentView.backgroundColor = UIColor.lightGray
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
