//
//  CoachingOverlay.swift
//  XYARKit
//
//  Created by user on 4/7/22.
//

import UIKit
import ARKit
import RealityKit

@available(iOS 13.0, *)
extension RealityViewController: ARCoachingOverlayViewDelegate {

    public func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        DispatchQueue.main.async {
            if !self.isDownloading {
                self.planDetectionView.animationHidden = false
            }
        }
    }

    public func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        DispatchQueue.main.async {
            if self.isPlacedOnPlane {
                self.planDetectionView.animationHidden = true
            }
        }
    }

    // StartOver
    public func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {
        // restartExperience()
    }

    func setupCoachingOverlay() {
        coachingOverlay.session = arView.session
        coachingOverlay.delegate = self

        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        arView.addSubview(coachingOverlay)
        coachingOverlay.alpha = 0

        coachingOverlay.activatesAutomatically = true
        coachingOverlay.goal = .horizontalPlane
    }
}
