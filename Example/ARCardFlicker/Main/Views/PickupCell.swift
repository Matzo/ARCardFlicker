//
//  PickupCell.swift
//  Hello
//
//  Created by 松尾 圭祐 on 2016/07/26.
//  Copyright © 2016年 playmotion. All rights reserved.
//

import UIKit

class PickupCardView: UIView {

//    enum Event {
//        case tapUserImage(userId: Int64, index: Int)
//    }

    // MARK: Properties

    // MARK: Outlets
    @IBOutlet weak var userImageView: UIImageView! {
        didSet {
//            userImageView.mode = .full
        }
    }
    @IBOutlet weak var nameLabel: UILabel! {
        didSet {
            nameLabel.numberOfLines = 1
            nameLabel.lineBreakMode = .byTruncatingTail
        }
    }
    @IBOutlet weak var likeCountLabel: UILabel! {
        didSet {
            likeCountLabel.numberOfLines = 1
            likeCountLabel.lineBreakMode = .byTruncatingTail
        }
    }

    @IBOutlet weak var crosspathCountLabel: UILabel! {
        didSet {
            crosspathCountLabel.textColor = UIColor.white
            crosspathCountLabel.textAlignment = .center
        }
    }

    @IBOutlet weak var crosspathLocationLabel: UILabel! {
        didSet {
            crosspathLocationLabel.textColor = UIColor.white
            crosspathLocationLabel.textAlignment = .center
        }
    }

    @IBOutlet weak var imageAspectSquare: NSLayoutConstraint! {
        didSet {
            imageAspectSquare.priority = Device.isSize(.phone5_8) ? UILayoutPriority.defaultLow : UILayoutPriority.defaultHigh
        }
    }
    @IBOutlet weak var imageAspectTall: NSLayoutConstraint! {
        didSet {
            imageAspectTall.priority = Device.isSize(.phone5_8) ? UILayoutPriority.defaultHigh : UILayoutPriority.defaultLow
        }
    }

    // MARK: Initialization
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    // MARK: Private Methods

    // MARK: Public Methods
    func configure(_ card: CardFlickable) {
//        if let p = self.card, p == card {
//            return
//        }
//        self.card = card

        userImageView.image = card.user.image
//        userImageView.setupUser(card.user, animated: true)
        nameLabel.text = card.user.name
    }
    // MARK: Class Methods
}


extension User: UserRepresentable {
    public func downloadImage() -> Observable<UIImage> {
        return profileImage.rx_downloadImage()
    }

    public var image: UIImage? {
        return profileImage.image
    }
}

