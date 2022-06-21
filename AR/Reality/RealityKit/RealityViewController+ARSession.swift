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
    public func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            let location = arView.center
            guard isPlacedOnPlane == false,
                  let planeAnchor = anchor as? ARPlaneAnchor,
                  let usdzEntity = usdzEntity else { return }
            if let rayCast = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any).first, let plane = rayCast.anchor as? ARPlaneAnchor {
                usdzEntity.position = rayCast.worldTransform.translation
                arView.scene.addAnchor(usdzEntity)
                usdzEntity.startAnimation()
                isPlacedOnPlane = true
                switch planeAnchor.alignment {
                case .vertical:
                    currentAlignment = .usdzVertical
                    previousVerticalPlane = plane
                case .horizontal:
                    currentAlignment = .usdzHorizontal
                    initHorizontalOrientation = rayCast.worldTransform.orientation
                    previousHorizontalPlane = plane
                default:
                    break
                }
                previousPlane = plane
                addSoundShort()
            }
        }
    }
    
    public func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            let location = arView.center
            guard isPlacedOnPlane == false,
                  let planeAnchor = anchor as? ARPlaneAnchor,
                  let usdzEntity = usdzEntity else { return }
            if let rayCast = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any).first, let plane = rayCast.anchor as? ARPlaneAnchor {
                usdzEntity.position = rayCast.worldTransform.translation
                arView.scene.addAnchor(usdzEntity)
                usdzEntity.startAnimation()
                isPlacedOnPlane = true
                switch planeAnchor.alignment {
                case .vertical:
                    currentAlignment = .usdzVertical
                    previousVerticalPlane = plane
                case .horizontal:
                    currentAlignment = .usdzHorizontal
                    initHorizontalOrientation = rayCast.worldTransform.orientation
                    previousHorizontalPlane = plane
                default:
                    break
                }
                previousPlane = plane
                addSoundShort()
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
