//
//  ARCardFlickViewModel.swift
//  HelloAR
//
//  Created by 松尾 圭祐 on 2018/07/12.
//  Copyright © 2018年 playmotion. All rights reserved.
//

import Foundation
import ARKit
import SceneKit
import RxSwift
import RxCocoa

public class ARCardFlickViewModel {

    public enum State {
        case initializing
        case floorAdjusting
        case floorAdded
        case cardAdding
        case flicking
        case finished
    }

    public enum Event {
        case none
        case likeAnimation(card: ARCard, point: SCNVector3)
        case skipAnimation(card: ARCard, point: SCNVector3)
        case appendCardAnimation(cards: [ARCard])
    }

    // MARK: Properties
    let state = BehaviorRelay<State>(value: .initializing)
    var field: FlickField?
    var cards = [ARCard]()
    let isUserStandbyOk = BehaviorRelay<Bool>(value: false)
    var disposeBag = DisposeBag()

    public var execCards: [ARCard] = []
    public var flickingCard: ARCard?
    public var likeTarget: CardRecievable?
    public var skipTarget: CardRecievable?
    public var stageNode: SCNNode?
    public var floor: FlickField?
    public let event = BehaviorRelay<Event>(value: .none)

    // MARK: Outlets
    // MARK: Initialization
    init() {
        setupObservable()
    }

    // MARK: Private Methods
    func setupObservable() {
        state.subscribe(onNext: { [weak self] (state) in
            self?.updateStatus()
        }).disposed(by: disposeBag)

        isUserStandbyOk.subscribe(onNext: { [weak self] (isOk) in
            self?.updateStatus()
        }).disposed(by: disposeBag)
    }

    func updateStatus() {
        if isUserStandbyOk.value && state.value == .floorAdded {
            state.accept(.cardAdding)
        }
    }

    // MARK: Public Methods
    public func ready() {
        isUserStandbyOk.accept(true)
    }

    public func didFinishedFloorAdjusting() {
        guard state.value == .floorAdjusting else { return }
        state.accept(.floorAdded)
    }

    public func finishedInitializing() {
        guard state.value == .initializing else { return }
        state.accept(.floorAdjusting)
    }

    public func finishedCardAdding() {
        guard state.value == .cardAdding else { return }
        state.accept(.flicking)
    }

    public func dispose() {
        self.disposeBag = DisposeBag()
    }

    // MARK: Class Methods
    public func appendCard(card: CardFlickable) {
        var newCards = Array(cards)
        newCards.append(ARCard(value: card))
        self.cards = newCards
    }

    // MARK: Private Methods
    func card(for node: SCNNode) -> ARCard? {
        return execCards.filter({ $0.node === node}).first
    }

    func target(for node: SCNNode) -> CardRecievable? {
        if let likeTarget = likeTarget, likeTarget.node == node {
            return likeTarget
        }
        if let skipTarget = skipTarget, skipTarget.node == node {
            return skipTarget
        }
        return nil
    }

    func nextCards(_ cards: [ARCard]) {
        self.execCards.append(contentsOf: cards)
    }

    func hit(card: ARCard, target: CardRecievable, point: SCNVector3) {
        if target.node == likeTarget?.node {
            doLike(card, point: point)
        }

        if target.node == skipTarget?.node {
            doSkip(card, point: point)
        }

        // 処理したカードは除外
        self.execCards = self.execCards.filter({ $0.node != card.node })
    }

    // MARK: Public Methods
    func doLike(_ card: ARCard, point: SCNVector3) {
        self.event.accept(.likeAnimation(card: card, point: point))
    }

    func doSkip(_ card: ARCard, point: SCNVector3) {
        self.event.accept(.skipAnimation(card: card, point: point))
    }
}

public protocol UserRepresentable {
    var name: String { get }
}

public protocol CardFlickable {
    var image: UIImage { get }
    var user: UserRepresentable { get }
}

public protocol CardRecievable {
    var node: SCNNode { get }
}
