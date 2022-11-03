//
//  RealityViewController.swift
//  XYARKit
//
//  Created by 吴熠 on 5/27/22.
//  Copyright © 2022 XingIn. All rights reserved.
//

import UIKit
import AVKit
import Photos
import ARKit
import RealityKit


public enum USDZAlignment {
    case usdzHorizontal
    case usdzVertical
    case usdzFloating
}


public enum CameraMode: CaseIterable {
    case picture
    case video
    
    var title: String {
        switch self {
        case .picture:
            return "Photo"
        case .video:
            return "Video"
        }
    }
}

public enum Capture {
    static let limitedTime: Double = 60.00
}

@available(iOS 13.0, *)
public final class RealityViewController: UIViewController {
    
    public lazy var arView: ARView = {
        let arView = ARView(frame: view.bounds)
        arView.session.delegate = self
        arView.renderOptions = [
            .disableGroundingShadows,
            .disableMotionBlur,
            .disableDepthOfField,
            .disableHDR,
            .disableCameraGrain]
        arView.environment.lighting.intensityExponent = 1.5
        return arView
    }()
        
    public var usdzEntity: USDZEntity?
    
    private var lastPanTouchPosition: CGPoint?
    
    public var initHorizontalOrientation: simd_quatf?
    
    public var currentAlignment: USDZAlignment? {
        didSet {
            guard let usdzEntity = usdzEntity else {
                return
            }
            usdzEntity.alignment = currentAlignment
        }
    }
    
    public let coachingOverlay = ARCoachingOverlayView()
    
    private var previousAlignment: USDZAlignment = .usdzHorizontal
    
    // usdz file loader
    private let loader = LoadUSDZ.shared
    
    // flag: usdz file is downloading
    public var isDownloading: Bool = false
    
    // flag: the usdz model has been placed on the plane
    public var isPlacedOnPlane: Bool = false
    
    // the vertical plane has been created
    private var verticalPlaneEntity: AnchorEntity?
    
    public var previousPlane: ARPlaneAnchor?
    public var previousHorizontalPlane: ARPlaneAnchor?
    public var previousVerticalPlane: ARPlaneAnchor?
    
    private var recentUSDZEntityPositions: [SIMD3<Float>] = []
    
    private var canMove: Bool = false
    
    private lazy var loadingView: ARLoadingView = {
        let view = ARLoadingView(frame: view.bounds)
        view.animationHidden = false
        return view
    }()
    
    public lazy var planDetectionView: PlanDetectionView = {
        let view = PlanDetectionView(frame: view.bounds)
        view.animationHidden = true
        return view
    }()
    
    public lazy var rotateTipView: RotateTipView = {
        let view = RotateTipView(frame: view.bounds)
        return view
    }()
    
    // camera buttons UI
    private var currentCameraMode: CameraMode = .video
    
    lazy var videoButton: UIButton = {
        let button = UIButton()
        button.setTitle(CameraMode.video.title, for: .normal)
        button.setTitleColor(.white.withAlphaComponent(0.5), for: .normal)
        button.setTitleColor(.white, for: .selected)
        button.titleLabel?.font = UIFont(name: "PingFang-SC-Medium", size: 16)
        button.isSelected = true
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowRadius = 1
        button.layer.shadowOpacity = 0.5
        button.layer.shadowOffset = CGSize(width: 0, height: 0)
        button.layer.masksToBounds = false
        button.addTarget(self, action: #selector(switchVideoMode), for: .touchUpInside)
        return button
    }()
    
    lazy var pictureButton: UIButton = {
        let button = UIButton()
        button.setTitle(CameraMode.picture.title, for: .normal)
        button.setTitleColor(.white.withAlphaComponent(0.5), for: .normal)
        button.setTitleColor(.white, for: .selected)
        button.titleLabel?.font = UIFont(name: "PingFang-SC-Medium", size: 16)
        button.isSelected = false
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowRadius = 1
        button.layer.shadowOpacity = 0.5
        button.layer.shadowOffset = CGSize(width: 0, height: 0)
        button.layer.masksToBounds = false
        button.addTarget(self, action: #selector(switchPictureMode), for: .touchUpInside)
        return button
    }()
    
    lazy var cameraTabView: CameraButtonView = {
        let view = CameraButtonView(frame: .zero)
        view.delegate = self
        return view
    }()
    
    private lazy var backButton: UIButton = {
        let backButton = UIButton()
        backButton.setImage(UIImage(named: "back"), for: .normal)
        backButton.layer.zPosition = 1000
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backButtonClicked), for: .touchUpInside)
        return backButton
    }()
    
    @objc
    func backButtonClicked() {
        dismiss(animated: false, completion: nil)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupARView()
        guard let modelURL = Bundle.main.url(forResource: "hd6_2k", withExtension: "usdz", subdirectory: "Models.scnassets") else {
            fatalError("can't find virtual object")
        }
        loadUSDZFile(with: modelURL)
    }
    
    private func loadUSDZFile(with url: URL) {
        LoadUSDZ.shared.loadObjectFromFilePath(url) { [weak self] usdzEntity in
            guard let self = self else { return }
            self.loadingView.animationHidden = true
            self.isDownloading = false
            if !self.isPlacedOnPlane {
                self.planDetectionView.animationHidden = false
            }
            // add system scale gesture
            self.usdzEntity = usdzEntity
            
            let rkPin = EntityPointPin(size: CGSize(width: 36, height: 36), pinTexture: UIImage(named: "guidance"))
            self.arView.addSubview(rkPin)
            rkPin.focusPercentage = 1
            rkPin.edge = 10
            rkPin.targetEntity = usdzEntity
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        resetTracking()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        planDetectionView.animationHidden = true
        arView.session.pause()
    }
    
    private func resetTracking() {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.isLightEstimationEnabled = true
        config.environmentTexturing = .automatic
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            switch config.frameSemantics {
            case [.personSegmentationWithDepth]:
                config.frameSemantics.remove(.personSegmentationWithDepth)
            default:
                config.frameSemantics.insert(.personSegmentationWithDepth)
            }
        }
        arView.session.run(config)
    }
    
    // MARK: - setup ARSceneView
    private func setupARView() {
        let statusHeight = UIApplication.shared.keyWindow?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        
        // add ar display view
        view.addSubview(arView)
        // guide view
        arView.addSubview(loadingView)
        arView.addSubview(planDetectionView)
                
        view.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.leading.equalTo(10)
            make.top.equalTo(view.snp.top).offset(statusHeight + 10)
        }
        
        // about video record
        setupARRecord()
        setupCameraUI()
        // add rotate gesture
        addGestures()
    }
    
    private func addGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
        arView.addGestureRecognizer(panGesture)
        
        let scaleGesture = UIPinchGestureRecognizer(target: self, action: #selector(didScale(_:)))
        arView.addGestureRecognizer(scaleGesture)
        
        let rotate = UIRotationGestureRecognizer(target: self, action: #selector(didRotate(_:)))
        arView.addGestureRecognizer(rotate)
    }
    
    @objc
    func didScale(_ sender: UIPinchGestureRecognizer) {
        guard let usdzEntity = usdzEntity, sender.numberOfTouches > 1 else {
            return
        }
        switch sender.state {
        case .changed:
            let originScale = usdzEntity.scale.x
            let currentScale = originScale * Float(sender.scale)
            let scale = SIMD3(x: currentScale, y: currentScale, z: currentScale)
            usdzEntity.scale = scale
            sender.scale = 1
        default:
            break
        }
    }
    
    @objc
    func didRotate(_ sender: UIRotationGestureRecognizer) {
        guard let usdzEntity = usdzEntity, sender.numberOfTouches > 1 else {
            return
        }
        switch sender.state {
        case .changed:
            let rotation = sender.rotation
            if currentAlignment == .usdzVertical {
                usdzEntity.setVerticalRotation(with: -Float(rotation))
            } else if currentAlignment == .usdzHorizontal {
                usdzEntity.setOrientation(simd_quatf(angle: -Float(rotation), axis: SIMD3(x: 0, y: 1, z: 0)), relativeTo: usdzEntity)
                initHorizontalOrientation = usdzEntity.orientation
            }
            sender.rotation = 0
        default:
            break
        }
    }
    
    
    // move model to every plane
    @objc
    func didPan(_ gesture: UIPanGestureRecognizer) {
        guard let usdzEntity = usdzEntity, gesture.numberOfTouches == 1 else {
            lastPanTouchPosition = nil
            return
        }
        switch gesture.state {
        case .began:
            let location = gesture.location(in: arView)
            if let touchEntite = arView.entity(at: location) {
                if touchEntite.name == "usdzPlane" {
                    canMove = false
                } else {
                    canMove = true
                }
            } else {
                canMove = false
            }
        case .changed:
            guard isPlacedOnPlane, canMove else { return }
            let translation = gesture.translation(in: arView)
            let previousPosition = lastPanTouchPosition ?? arView.project(usdzEntity.position)
            guard let previousPositionX = previousPosition?.x,
                  let previousPositionY = previousPosition?.y else { return }
            let currentPosition = CGPoint(x: previousPositionX + translation.x, y: previousPositionY + translation.y)
            if let hitTest = arView.hitTest(currentPosition, types: [.existingPlaneUsingGeometry]).first,
               let planeAnchor = hitTest.anchor as? ARPlaneAnchor {
                if previousPlane?.identifier != planeAnchor.identifier {
                    addSoundShort()
                }
                previousPlane = planeAnchor
                switch planeAnchor.alignment {
                case .horizontal:
                    previousHorizontalPlane = planeAnchor
                    currentAlignment = .usdzHorizontal
                    // remove vertical plane
                    verticalPlaneEntity?.removeFromParent()
                    verticalPlaneEntity = nil
                    // when previous alignment is vertical, reset orientation
                    if previousAlignment == .usdzVertical {
                        usdzEntity.resetEntityOirentation()
                    }
                    recentUSDZEntityPositions.append(hitTest.worldTransform.translation)
                    updatePosition()
                    previousAlignment = .usdzHorizontal
                case .vertical:
                    previousVerticalPlane = planeAnchor
                    currentAlignment = .usdzVertical
                    let translation = hitTest.worldTransform.translation
                    recentUSDZEntityPositions.append(translation)
                    updatePosition()
                    usdzEntity.orientation = hitTest.worldTransform.orientation
                    usdzEntity.setOrientation(simd_quatf(angle: -.pi / 2, axis: SIMD3(x: 1, y: 0, z: 0)), relativeTo: usdzEntity)
                    previousAlignment = .usdzVertical
                default:
                    break
                }
            } else {
                if let planeAnchor = previousHorizontalPlane,
                   let position = arView.unproject(currentPosition, ontoPlane: planeAnchor.transform) {
                    verticalPlaneEntity?.removeFromParent()
                    verticalPlaneEntity = nil
                    
                    recentUSDZEntityPositions.append(position)
                    updatePosition()
                    currentAlignment = .usdzHorizontal
                }
            }
            lastPanTouchPosition = currentPosition
            gesture.setTranslation(.zero, in: arView)
        case .ended:
            lastPanTouchPosition = nil
        default:
            break
        }
    }
    
    func updatePosition() {
        guard let usdzEntity = usdzEntity else {
            return
        }
        
        // Average using several most recent positions.
        recentUSDZEntityPositions = Array(recentUSDZEntityPositions.suffix(3))
        
        // Move to average of recent positions to avoid jitter.
        let average = recentUSDZEntityPositions.reduce(
            SIMD3<Float>.zero, { $0 + $1 }
        ) / Float(recentUSDZEntityPositions.count)
        
        guard let camera = arView.session.currentFrame?.camera else { return }
        let cameraPosition = camera.transform.translation
        let distance = simd_distance(cameraPosition, average)
        let scale = usdzEntity.scale.x
        let factor = distance / scale
        if factor < 20 {
            usdzEntity.position = average
        }
    }
}
