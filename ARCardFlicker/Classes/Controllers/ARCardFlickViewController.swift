//
//  ARPickupViewController.swift
//  Hello
//
//  Created by 松尾 圭祐 on 2018/06/21.
//  Copyright © 2018年 playmotion. All rights reserved.
//

import UIKit
import ARKit
import RxSwift
import RxCocoa

public protocol ARCardFlickViewControllerDelegate: class {
    func flickViewController(_ viewController: ARCardFlickViewController, didTapStageNode: SCNNode)
    func flickViewController(_ viewController: ARCardFlickViewController, didTap: CardFlickable)
    func flickViewController(_ viewController: ARCardFlickViewController, didLike: CardFlickable)
    func flickViewController(_ viewController: ARCardFlickViewController, didSkip: CardFlickable)
}

public class ARCardFlickViewController: UIViewController {

    // MARK: Properties
    private let viewModel = ARCardFlickViewModel()
    private let bag = DisposeBag()
    var lastTranslation: float3?
    var lastNode: SCNNode?
    var isFirst: Bool = false
    var likeParticleFileName = "LikeParticle.scnp"
    var skipParticleFileName = "LikeParticle.scnp"
    public weak var delegate: ARCardFlickViewControllerDelegate?

    // MARK: Outlets
    @IBOutlet weak var arView: ARCardFlickView! {
        didSet {
            arView.delegate = self
            arView.session.delegate = self
        }
    }

    @IBOutlet weak var sessionInfoLabel: UILabel! {
        didSet {
            sessionInfoLabel.numberOfLines = 0
        }
    }

    deinit {
        viewModel.dispose()
    }

    // MARK: UIViewController Lifecycle
    override public func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupViews()
        setupViewModel()
        addGestureToSceneView()
        configureLighting()
        setupEvent()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupARSession()
    }

    // MARK: Private Methods

    // MARK: - Setup UI
    private func setupViews() {
        UIApplication.shared.isIdleTimerDisabled = true
    }

    func addGestureToSceneView() {
        let tapGesture = UITapGestureRecognizer()
        tapGesture.rx.event
            .subscribe(onNext: { [weak self] (tapGesture) in
                self?.viewModel.ready()
            })
            .disposed(by: bag)
        arView.addGestureRecognizer(tapGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(ARCardFlickViewController.panCard(withGestureRecognizer:)))
        arView.addGestureRecognizer(panGesture)
    }

    // MARK: - Setup AR
    func configureLighting() {
        arView.autoenablesDefaultLighting = true
        arView.automaticallyUpdatesLighting = true
    }

    private func setupARSession() {
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("""
                ARKit is not available on this device. For apps that require ARKit
                for core functionality, use the `arkit` key in the key in the
                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                the app from installing. (If the app can't be installed, this error
                can't be triggered in a production scenario.)
                In apps where AR is an additive feature, use `isSupported` to
                determine whether to show UI for launching AR experiences.
            """) // For details, see https://developer.apple.com/documentation/arkit
        }

        // Set the view's delegate
        arView.resetTracking()
    }

    private func createLight() -> SCNNode {
        let light = SCNLight()
        light.type = .omni
        light.intensity = 800
        let lightNode = SCNNode()
        lightNode.light = light
        return lightNode
    }

    private func createAmbientLight() -> SCNNode {
        let light = SCNLight()
        light.type = .ambient
        light.intensity = 400
        let lightNode = SCNNode()
        lightNode.light = light
        return lightNode
    }

    // MARK: - 3D functions
    private func createPlane(on anchor: ARPlaneAnchor) -> SCNNode {
        let width = CGFloat(anchor.extent.x)
        let height = CGFloat(anchor.extent.z)
        let plane = SCNPlane(width: width, height: height)

        plane.materials.first?.diffuse.contents = UIColor.white.withAlphaComponent(0.1)

        let planeNode = SCNNode(geometry: plane)

        let x = CGFloat(anchor.center.x)
        let z = CGFloat(anchor.center.z)
        planeNode.position = SCNVector3(x, 0, z)
        planeNode.eulerAngles.x = -.pi / 2
        planeNode.physicsBody = SCNPhysicsBody.static()

        return planeNode
    }

    private func createPlaneBox(on anchor: ARPlaneAnchor) -> SCNNode {
        let width = CGFloat(anchor.extent.x)
        let height = CGFloat(anchor.extent.z)
        let plane = SCNBox(width: width, height: 0.1, length: height, chamferRadius: 0)

        plane.materials.first?.diffuse.contents = UIColor.white.withAlphaComponent(0.01)

        let planeNode = SCNNode(geometry: plane)

        let x = CGFloat(anchor.center.x)
        let z = CGFloat(anchor.center.z)
        planeNode.position = SCNVector3(x, -0.05, z)
        planeNode.physicsBody = SCNPhysicsBody.static()

        return planeNode
    }

    private func createFlickTarget(name: String, position: SCNVector3) -> SCNNode {
        let box = SCNBox(width: 1, height: 2, length: 1, chamferRadius: 0)

        //        box.materials.first?.diffuse.contents = UIColor.red.withAlphaComponent(0.3)
        box.materials.first?.diffuse.contents = UIColor.clear

        let boxNode = SCNNode(geometry: box)
        boxNode.opacity = 0.3

        boxNode.position = position
        boxNode.physicsBody = SCNPhysicsBody.kinematic()
        boxNode.name = name
        boxNode.physicsBody?.contactTestBitMask = 1
        boxNode.physicsBody?.collisionBitMask = 0

        return boxNode
    }

    private func createSkipTarget(name: String, position: SCNVector3) -> SCNNode {
        let floor = SCNFloor()
        floor.reflectivity = 0

        floor.materials.first?.diffuse.contents = UIColor.clear

        let node = SCNNode(geometry: floor)
        node.opacity = 0.3

        node.position = position
        node.physicsBody = SCNPhysicsBody.kinematic()
        node.name = name
        node.physicsBody?.contactTestBitMask = 1
        node.physicsBody?.collisionBitMask = 0

        return node
    }

    private func createBox(position: SCNVector3) -> SCNNode {
        let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.01)
        let boxNode = SCNNode(geometry: box)
        boxNode.position = position
        boxNode.position.y += Float(box.height * 0.5)
        boxNode.physicsBody = SCNPhysicsBody.dynamic()
        return boxNode
    }

    private func createCard(position: SCNVector3, image: UIImage) -> SCNNode {
        let box = SCNBox(width: 0.16, height: 0.0015, length: 0.23, chamferRadius: 0.05)
        let boxNode = SCNNode(geometry: box)
        boxNode.name = "card"
        boxNode.position = position
        boxNode.position.y += Float(box.height) + 0.1
        boxNode.physicsBody = SCNPhysicsBody.dynamic()
        boxNode.physicsBody?.contactTestBitMask = 1
        boxNode.physicsBody?.collisionBitMask = 1

        box.firstMaterial?.diffuse.contents = image.cgImage
        return boxNode
    }

    func addParticle(name: String, position: SCNVector3, toNode node: SCNNode) {
        guard let particle = SCNParticleSystem(named: name, inDirectory: "Particles") else { return }
        let particleNode = SCNNode()
        particleNode.addParticleSystem(particle)
        particleNode.position = position
        node.addChildNode(particleNode)
    }

    func addShapeToSceneView(card: ARCard) {
        let hitTestResults = arView.hitTest(self.arView.center, types: .existingPlaneUsingExtent)
        guard let hitTestResult = hitTestResults.first else { return }

        let image = card.value.image
        let translation = hitTestResult.worldTransform.translation
        let x = translation.x
        let y = translation.y
        let z = translation.z

        let boxNode = createCard(position: SCNVector3(x, y, z), image: image)
        card.node = boxNode
        viewModel.nextCards([card])
        updatePhysicsBody(node: boxNode, type: .dynamic)
        arView.scene.rootNode.addChildNode(boxNode)
    }

    // MARK: - Setup ViewModel
    func setupViewModel() {

        viewModel.state
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (state) in
                guard let _self = self else { return }
                switch state {

                case .cardAdding:
                    guard let stageNode = _self.viewModel.stageNode else { return }
                    self?.delegate?.flickViewController(_self, didTapStageNode: stageNode)
                default: break
                }
            })
            .disposed(by: bag)

        Observable<Int>.interval(0.05, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let _self = self else { return }
                guard _self.viewModel.cards.count > 0 else { return }
                guard let card = _self.viewModel.cards.first(where: { !$0.displayed }) else {
                    return
                }
                _self.arView.appendCard(card)
                _self.addShapeToSceneView(card: card)
                card.displayed = true

                _self.viewModel.finishedCardAdding()
            })
            .disposed(by: bag)
    }

    func setupTargets(rootNode: SCNNode, anchor: ARAnchor) {
        guard [ARCardFlickViewModel.State.initializing, ARCardFlickViewModel.State.floorAdjusting].contains(viewModel.state.value) else { return }
        guard let anchor = anchor as? ARPlaneAnchor else { return }
        let position = SCNVector3(anchor.center.x, anchor.center.y, anchor.center.z)
        let light = createLight()
        light.position = SCNVector3(position.x - 5, position.y + 10, position.x - 5)
        rootNode.addChildNode(light)
        rootNode.addChildNode(createAmbientLight())
        let planeNode = createPlaneBox(on: anchor)
        self.viewModel.field = FlickField(node: planeNode)

        guard let camera = arView.pointOfView else { return }
        let targtDirection = SCNVector3(position.x - camera.position.x,
                                        position.y - camera.position.y,
                                        position.z - camera.position.z)
        //        let translation = SCNMatrix4MakeTranslation(targtDirection.x * 10, targtDirection.y, targtDirection.z * 10)
        let translation = SCNMatrix4MakeTranslation(targtDirection.x, targtDirection.y, targtDirection.z)
        let direction = SCNVector3(-translation.m31, -translation.m32, -translation.m33)
        let likePosition = SCNVector3(camera.position.x + direction.x * 2.0,
                                      camera.position.y + direction.y * 2.0,
                                      camera.position.z + direction.z * 2.0)

        let likeTargetNode = createFlickTarget(name: "like", position: likePosition)
        let skipTargetNode = createSkipTarget(name: "skip", position: SCNVector3(position.x, position.y - 0.5, position.z))

        likeTargetNode.eulerAngles.y = direction.y

        self.viewModel.stageNode = planeNode
        self.viewModel.likeTarget = FlickGoal(type: .like, node: likeTargetNode)
        self.viewModel.skipTarget = FlickGoal(type: .skip, node: skipTargetNode)

        rootNode.addChildNode(planeNode)
        rootNode.addChildNode(likeTargetNode)
        rootNode.addChildNode(skipTargetNode)
    }

    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String

        switch trackingState {
        case .normal where frame.anchors.isEmpty:
            // No planes detected; provide instructions for this app's AR interactions.
            message = "Move the device around to detect horizontal surfaces."

        case .notAvailable:
            message = "Tracking unavailable."

        case .limited(.excessiveMotion):
            message = "Tracking limited - Move the device more slowly."

        case .limited(.insufficientFeatures):
            message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."

        case .limited(.initializing):
            message = "Initializing AR session."

        default:
            // No feedback needed when tracking is normal and planes are visible.
            // (Nor when in unreachable limited-tracking states.)
            message = ""

            viewModel.finishedInitializing()

        }

        sessionInfoLabel.text = message
    }

    func setupEvent() {
        viewModel.event
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (event) in
                guard let _self = self else { return }
                switch event {
                case .none:
                    break
                case .likeAnimation(let card, let point):
                    _self.addParticle(name: _self.likeParticleFileName, position: point, toNode: _self.arView.scene.rootNode)
                    _self.delegate?.flickViewController(_self, didLike: card.value)

                case .skipAnimation(let card, let point):
                    _self.addParticle(name: _self.likeParticleFileName, position: point, toNode: _self.arView.scene.rootNode)
                    _self.delegate?.flickViewController(_self, didSkip: card.value)

                case .appendCardAnimation(_):
                    break
                }
            })
            .disposed(by: bag)
    }

    @objc func panCard(withGestureRecognizer recognizer: UIGestureRecognizer) {
        let location = recognizer.location(in: arView)
        let hitTestResults = arView.hitTest(location, options: [SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue])
        let node = hitTestResults.first(where: { $0.node.name == "card" })?.node
        switch recognizer.state {
        case .possible:
            break
        case .began:
            lastTranslation = nil
            guard let node = node else { return }
            lastNode = node
            isFirst = true
        case .changed:
            break
        case .ended:
            lastTranslation = nil
            lastNode = nil
            isFirst = false
            return
        case .cancelled:
            lastTranslation = nil
            lastNode = nil
            isFirst = false
            return
        case .failed:
            lastTranslation = nil
            lastNode = nil
            isFirst = false
            return
        }

        let panResults = arView.hitTest(location, types: .existingPlaneUsingExtent)
        guard let panResult = panResults.first else { return }

        let translation = panResult.worldTransform.translation
        if let lastTranslation = lastTranslation, let lastNode = lastNode {
            let delta = float3(translation.x - lastTranslation.x, translation.y - lastTranslation.y, translation.z - lastTranslation.z)
            let forceY: Float = isFirst ? 1 : 0
            lastNode.physicsBody?.applyForce(SCNVector3(delta.x * 50, delta.y * 50 + forceY, delta.z * 50), asImpulse: true)

            isFirst = false
        }

        self.lastTranslation = translation
    }

    // MARK: Public Methods
    public func ready() {
        viewModel.ready()
    }

    public func appendCard(card: CardFlickable) {
        viewModel.appendCard(card: card)
    }

    // MARK: Class Methods
    public static func create() -> ARCardFlickViewController {
        let bundle = Bundle(for: ARCardFlickViewController.self)
        let vc = UIStoryboard(name: String(describing: ARCardFlickViewController.self), bundle: bundle)
            .instantiateInitialViewController() as! ARCardFlickViewController
        return vc
    }
}

// MARK: - ARSessionDelegate
extension ARCardFlickViewController: ARSessionDelegate {
    public func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }

    public func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }

    public func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }
}

// MARK: - ARSCNViewDelegate
extension ARCardFlickViewController: ARSCNViewDelegate {

    /// - Tag: PlaceARContent
    public func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Place content only for anchors found by plane detection.
        guard let anchor = anchor as? ARPlaneAnchor else { return }
        setupTargets(rootNode: node, anchor: anchor)

        arView.scene.physicsWorld.contactDelegate = self
    }

    public func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // Update content only for plane anchors and nodes matching the setup created in `renderer(_:didAdd:for:)`.
        guard viewModel.state.value == .floorAdjusting else { return }
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = self.viewModel.field?.node,
            let plane = planeNode.geometry as? SCNBox
            else { return }

        // Plane estimation may shift the center of a plane relative to its anchor's transform.
        planeNode.simdPosition = float3(planeAnchor.center.x, planeNode.simdPosition.y, planeAnchor.center.z)

        // Plane estimation may also extend planes, or remove one plane to merge its extent into another.
        plane.width = CGFloat(planeAnchor.extent.x)
        plane.length = CGFloat(planeAnchor.extent.z)

        updatePhysicsBody(node: planeNode, type: .static)

        arView.scene.physicsWorld.updateCollisionPairs()

        viewModel.didFinishedFloorAdjusting()
    }

    public func updatePhysicsBody(node: SCNNode, type: SCNPhysicsBodyType) {
        guard let geometry = node.geometry else { return }
        let shape = SCNPhysicsShape(geometry: geometry, options: nil)
        node.physicsBody = SCNPhysicsBody(type: type, shape: shape)

        viewModel.likeTarget?.node.physicsBody?.resetTransform()
    }

    // MARK: - ARSessionObserver
    public func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay.
        sessionInfoLabel.text = "Session was interrupted"
    }

    public func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required.
        sessionInfoLabel.text = "Session interruption ended"
        arView.resetTracking()
    }

    public func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user.
        sessionInfoLabel.text = "Session failed: \(error.localizedDescription)"
        arView.resetTracking()
    }
}

extension ARCardFlickViewController: SCNPhysicsContactDelegate {

    public func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let firstNode = contact.nodeA
        let secondNode = contact.nodeB

        if let card = viewModel.card(for: firstNode), let target = viewModel.target(for: secondNode) {
            viewModel.hit(card: card, target: target, point: contact.contactPoint)
        } else if let card = viewModel.card(for: secondNode), let target = viewModel.target(for: firstNode) {
            viewModel.hit(card: card, target: target, point: contact.contactPoint)
        }
    }
}

public extension float4x4 {
    public var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

public class FlickGoal: CardRecievable {
    public enum GoalType {
        case like
        case skip
    }
    public let type: GoalType
    public let node: SCNNode
    public init(type: GoalType, node: SCNNode) {
        self.type = type
        self.node = node
    }
}

public class FlickField {
    public let node: SCNNode
    public init(node: SCNNode) {
        self.node = node
    }
}

public class ARCard {

    public var node: SCNNode = SCNNode()
    public let value: CardFlickable
    public var executed: Bool = false
    public var displayed: Bool = false

    public init(value: CardFlickable) {
        self.value = value
    }
}

extension ARCard: Equatable {
    public static func == (lhs: ARCard, rhs: ARCard) -> Bool {
        guard lhs.node == rhs.node else { return false }
        guard lhs.value.user.name == rhs.value.user.name else { return false }
        guard lhs.executed == rhs.executed else { return false }
        return true
    }
}
