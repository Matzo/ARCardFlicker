//
//  MainViewController.swift
//  HelloAR
//
//  Created by 松尾 圭祐 on 2018/08/16.
//  Copyright © 2018年 playmotion. All rights reserved.
//

import UIKit
import ARKit
import RxSwift
import RxCocoa
import ARCardFlicker

class MainViewController: UIViewController {

    // MARK: Properties
    let flickVC = ARCardFlickViewController.create()
    let viewModel = MainViewModel()
    let disposeBag = DisposeBag()

    // MARK: Outlets
    @IBOutlet weak var resultsLabel: UILabel! {
        didSet {
            resultsLabel.text = nil
        }
    }

    // MARK: Initialization
    // MARK: UIViewController Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        flickVC.delegate = self
        setupARFlick()
        setupViewModel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.view.bringSubview(toFront: self.resultsLabel)
    }

    // MARK: Private Methods
    func setupARFlick() {
        flickVC.willMove(toParentViewController: self)
        view.addSubview(flickVC.view)
        flickVC.didMove(toParentViewController: self)

        flickVC.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        flickVC.view.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        flickVC.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        flickVC.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
    }

    func setupViewModel() {
        viewModel.cards
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (cards) in
                cards.forEach({ (card) in
                    self?.flickVC.appendCard(card: card)
                })
            })
            .disposed(by: disposeBag)
    }

    func showLikeAnimation(user: UserRepresentable) {
        DispatchQueue.main.async {
            self.resultsLabel.text = nil
            self.resultsLabel.alpha = 0
            self.resultsLabel.text = "\(user.name)さんにいいね！しました"
            UIView.animate(withDuration: 0.5) {
                self.resultsLabel.alpha = 1
            }
        }
    }

    func showSkipAnimation() {
    }

    // MARK: Public Methods
    // MARK: Class Methods
}

extension MainViewController: ARCardFlickViewControllerDelegate {
    func flickViewController(_ viewController: ARCardFlickViewController, didTapStageNode: SCNNode) {
        viewModel.fetchCards()
    }
    func flickViewController(_ viewController: ARCardFlickViewController, didTap: CardFlickable) {
        print("カードタップ！！")
    }
    func flickViewController(_ viewController: ARCardFlickViewController, didLike: CardFlickable) {
        showLikeAnimation(user: didLike.user)
    }
    func flickViewController(_ viewController: ARCardFlickViewController, didSkip: CardFlickable) {
        print("カードフリック！！ skip")
    }
}
