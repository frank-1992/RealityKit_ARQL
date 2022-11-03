//
//  EntityPointPin.swift
//
//  Created by 吴熠 on 6/25/22.
//

import RealityKit
import UIKit
import Combine

@objc public protocol EntityPointPinDelegate: AnyObject {
    // Called when the center of the `targetEntity` has moved into the focus area
    @objc optional func pinIntoFocusArea()
    
    // Called when the center of the `targetEntity` has moved out of the focus area
    @objc optional func pinOutOfFocusArea()
}

public class EntityPointPin: UIView {
    // When the targetEntity is within a percentage of the center of the screen, hide the pin if true.
    // Set to false if you want to use your own hide/show functions.
    public var autoHideOnFocused = true
    
    // Percentage (0-1) of the screen which is considered `inFocus`
    // Tip: focusPercentage must be between 0 and 1
    public var focusPercentage: CGFloat = 0.0 {
        didSet {
            if !(0.0...1.0).contains(self.focusPercentage) {
                self.focusPercentage = max(min(self.focusPercentage, 1), 0)
            }
        }
    }
    
    /// Entity that we will be pointing at 🎯
    public var targetEntity: Entity? {
        didSet {
            self.inFocus = nil
            self.resetCancellable()
        }
    }
    
    private var setARView: ARView?
    
    // arView which contains the 'targetEntity'
    public var arView: ARView? {
        self.superview as? ARView
    }
    
    // the arrow distance off the screen
    public var edge: CGFloat = 0
    
    required public init(
        size: CGSize = CGSize(width: 32, height: 64),
        pinTexture: UIImage? = nil,
        color: UIColor? = nil
    ) {
        pinBody = UIImageView(frame: CGRect(origin: .init(x: -size.width/2, y: -size.height), size: size))
        super.init(frame: .zero)
        var pinTx: UIImage?
        if pinTexture != nil {
            pinTx = pinTexture
            if let color = color {
                pinTx = pinTexture?.tinted(color: color)
            }
        } else {
            pinTx = UIImage.pinImg(color: color ?? .systemBlue)
        }
        pinBody.image = pinTx
        pinBody.contentMode = .scaleAspectFill
        
        self.addSubview(pinBody)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func hidePin() {
        self.isHidden = true
    }
    public func showPin() {
        self.isHidden = false
    }
    
    public override func didMoveToSuperview() {
        self.resetCancellable()
    }
    
    private var viewWidth: CGFloat? {
        self.arView?.frame.width
    }
    private var viewHeight: CGFloat? {
        self.arView?.frame.height
    }
    
    private var cancellable: Cancellable?
    
    private var safeFrame: CGRect? {
        guard let arView = self.arView else {
            return nil
        }
        return CGRect(
            origin: CGPoint(x: arView.safeAreaInsets.left, y: arView.safeAreaInsets.top),
            size: CGSize(
                width: arView.frame.width - (arView.safeAreaInsets.right + arView.safeAreaInsets.left),
                height: arView.frame.height - (arView.safeAreaInsets.top + arView.safeAreaInsets.bottom)
            )
        )
    }
    
    private func resetCancellable() {
        self.cancellable?.cancel()
        if self.targetEntity == nil {
            return
        }
        if !Thread.isMainThread {
            print("EntityPointPin ERROR: targetEntity should set from main thread")
            return
        }
        guard let arView = self.arView else {
            return
        }
        self.cancellable = arView.scene.subscribe(
            to: SceneEvents.Update.self, { _ in
                self.updatePos()
            })
    }
    
    private var pinBody: UIImageView
    private var focusBounds: CGRect? {
        guard let safeView = self.safeFrame, self.focusPercentage != 0 else {
            return nil
        }
        return CGRect(
            x: safeView.origin.x + safeView.width * (1 - focusPercentage) / 2,
            y: safeView.origin.y + safeView.height * (1 - focusPercentage) / 2,
            width: safeView.width - safeView.width * (1 - focusPercentage),
            height: safeView.height - safeView.height * (1 - focusPercentage)
        )
    }
    
    private var inFocus: Bool? {
        didSet {
            if oldValue != self.inFocus {
                focusStateChanged(to: self.inFocus)
            }
        }
    }
    
    private func focusStateChanged(to focused: Bool?) {
        guard let focused = focused else {
            // setting to null/resetting value
            return
        }
        if let pinDelegate = self.arView as? EntityPointPinDelegate {
            if focused {
                pinDelegate.pinIntoFocusArea?()
            } else {
                pinDelegate.pinOutOfFocusArea?()
            }
        }
        if self.autoHideOnFocused {
            if focused {
                self.hidePin()
            } else {
                self.showPin()
            }
        }
    }
    
    private func updatePos() {
        if !Thread.isMainThread {
            print("EntityPointPin ERROR: Should be on main thread")
            return
        }
        guard let arView = self.arView else {
            print("EntityPointPin.arView not set")
            return
        }
        guard let ent = self.targetEntity,
              ent.scene != nil,
              let projPoint = arView.project(ent.position(relativeTo: nil)) else {
            if !self.pinBody.isHidden {
                // hide pin if it is showing
                self.pinBody.isHidden = true
            }
            return
        }
        if self.pinBody.isHidden {
            // show pin if it is hidden
            self.pinBody.isHidden = false
        }
        let matrixZAxis = arView.cameraTransform.matrix.columns.2
        let zFacing: SIMD3<Float> = [matrixZAxis.x, matrixZAxis.y, matrixZAxis.z]
        let toEntityDirection = ent.position(relativeTo: nil) - arView.cameraTransform.translation
        let zDots = dot(zFacing, toEntityDirection)
        if zDots > 0 {
            // looking in the opposite direction projects the point to the center of
            // the screen. This is a temporary fix by flipping the x and y,
            // there is probably a better fix for this to be investigated later
            self.setPos(to: CGPoint(x: -projPoint.x + 10, y: -projPoint.y + 10))
        } else {
            self.setPos(to: projPoint)
        }
    }
    
    private func setPos(to point: CGPoint) {
        guard let safeFrame = self.safeFrame,
              let viewWidth = self.viewWidth,
              let viewHeight = self.viewHeight
        else {
            return
        }
        
        var endPos = CGPoint(
            x: max(min(point.x, safeFrame.origin.x + safeFrame.width), safeFrame.origin.x),
            y: max(min(point.y, safeFrame.origin.y + safeFrame.height), safeFrame.origin.y)
        )
        
        if endPos.x == 0 {
            endPos.x = endPos.x + edge
        } else if endPos.x == safeFrame.width {
            endPos.x = endPos.x - edge
        }
        
        self.transform = CGAffineTransform(rotationAngle: atan2(
            point.y - viewHeight / 2, point.x - viewWidth / 2) - .pi / 2)
        self.frame = CGRect(origin: endPos, size: .zero)
        
        if let focusBounds = self.focusBounds {
            self.inFocus = focusBounds.contains(point)
        }
    }
}
