//
//  ARCardFlickView.swift
//  HelloAR
//
//  Created by 松尾 圭祐 on 2018/07/26.
//  Copyright © 2018年 playmotion. All rights reserved.
//

import UIKit
import ARKit

public protocol ARCardFlickViewDelegate: class {
    func flickView(_ flickView: ARCardFlickView, didTapCard: CardFlickable)
    func flickView(_ flickView: ARCardFlickView, didFlickToLike: CardFlickable)
    func flickView(_ flickView: ARCardFlickView, didFlickToSkip: CardFlickable)
}

public class ARCardFlickView: ARSCNView {

    // MARK: public Properties
    public weak var flickDelegate: ARCardFlickViewDelegate?

    public var cards: [ARCard] = []

    // MARK: private Properties

    // MARK: Initialization
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    func setup() {
        // Show statistics such as fps and timing information
//        self.showsStatistics = true
//        self.debugOptions = [.showPhysicsShapes]
    }

    // MARK: Public Methods
    func appendCard(_ card: ARCard) {
        cards.append(card)
    }

    func insertCard(_ card: ARCard, at index: Int) {
        cards.insert(card, at: index)
    }

    func removeCard(at index: Int) {
        cards.remove(at: index)
    }

    func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        self.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    // MARK: Private Methods
}
