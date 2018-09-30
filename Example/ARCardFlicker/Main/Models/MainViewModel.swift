//
//  MainViewModel.swift
//  HelloAR
//
//  Created by 松尾 圭祐 on 2018/08/16.
//  Copyright © 2018年 playmotion. All rights reserved.
//

import Foundation
import ARKit
import RxSwift
import RxCocoa
import ARCardFlicker

class MainViewModel {

    // MARK: Properties
    let cards = BehaviorRelay<[CardFlickable]>(value: [])

    // MARK: Initialization

    // MARK: Public Methods
    func fetchCards() {

        _ = loadCards()
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] (result) in
                    guard let _self = self else { return }
                    let exists = _self.cards.value
                    _self.cards.accept(exists + result)
                },
                onError: { (error) in
                    print("###### error: \(error)")
            })
    }

    func loadCards() -> Observable<[CardFlickable]> {
        let cards = (1...20).map { Card(user: User(name: "user\($0)"), image: #imageLiteral(resourceName: "cat")) }
        return Observable.just(cards)
    }

}

struct Card: CardFlickable {
    var user: UserRepresentable
    var image: UIImage
}

struct User: UserRepresentable {
    var name: String
}
