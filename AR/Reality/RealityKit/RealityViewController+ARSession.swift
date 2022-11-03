//
//  RealityViewController+ARSession.swift
//  XYARKit
//
//  Created by 吴熠 on 5/27/22.
//  Copyright © 2022 XingIn. All rights reserved.
//

import ARKit
import RealityKit

// MARK: - ARSessionDelegate
@available(iOS 13.0, *)
extension RealityViewController: ARSessionDelegate {
    public func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .limited(.initializing):
            if !isDownloading && isPlacedOnPlane {
                planDetectionView.animationHidden = false
            }
        case .limited(.excessiveMotion):
            if !isDownloading && isPlacedOnPlane {
                planDetectionView.animationHidden = false
            }
        case .limited(.insufficientFeatures):
            if !isDownloading && isPlacedOnPlane {
                planDetectionView.animationHidden = false
            }
        case .limited(.relocalizing):
            if !isDownloading && isPlacedOnPlane {
                planDetectionView.animationHidden = false
            }
        case .limited(_):
            if !isDownloading && isPlacedOnPlane {
                planDetectionView.animationHidden = false
            }
        case .notAvailable:
            if !isDownloading && isPlacedOnPlane {
                planDetectionView.animationHidden = false
            }
        case .normal:
            print("arCamera: normal")
            if !planDetectionView.animationHidden && isPlacedOnPlane {
                planDetectionView.animationHidden = true
            }
        }
    }
    
    public func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        DispatchQueue.main.async {
            for anchor in anchors {
                let location = self.arView.center
                guard self.isPlacedOnPlane == false,
                      let planeAnchor = anchor as? ARPlaneAnchor,
                      let usdzEntity = self.usdzEntity else { return }
                guard let position = self.arView.unproject(location, ontoPlane: planeAnchor.transform) else { return }
                usdzEntity.position = position
                self.arView.scene.addAnchor(usdzEntity)
                usdzEntity.startAnimation()
                self.planDetectionView.animationHidden = true
                self.isPlacedOnPlane = true
                switch planeAnchor.alignment {
                case .vertical:
                    self.currentAlignment = .usdzVertical
                    self.previousVerticalPlane = planeAnchor
                case .horizontal:
                    self.currentAlignment = .usdzHorizontal
                    self.initHorizontalOrientation = planeAnchor.transform.orientation
                    self.previousHorizontalPlane = planeAnchor
                default:
                    break
                }
                self.previousPlane = planeAnchor
                self.addSoundShort()
            }
        }
    }
    
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let usdzEntity = usdzEntity else { return }
        let camera = frame.camera
        let transform = camera.transform
        if let rayCast = arView.scene.raycast(from: transform.translation, to: usdzEntity.transform.translation, query: .nearest, mask: .default, relativeTo: nil).first {
            usdzEntity.shadowDistance = rayCast.distance
        }
    }
    
    public func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
    
    func addSoundShort() {
        let soundShort = SystemSoundID(1519)
        AudioServicesPlaySystemSound(soundShort)
        planDetectionView.animationHidden = true
    }
}
