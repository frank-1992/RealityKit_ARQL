//
//  ARUtilities.swift
//  XYARKit
//
//  Created by user on 4/6/22.
//

import UIKit
import ARKit

// MARK: - CGPoint extensions
extension CGPoint {
    init(_ vector: SCNVector3) {
        self.init(x: CGFloat(vector.x), y: CGFloat(vector.y))
    }
    
    var length: CGFloat {
        return sqrt(x * x + y * y)
    }
}

// MARK: - SCNNode extensions
extension SCNNode {
    var extents: SIMD3<Float> {
        let (min, max) = boundingBox
        return SIMD3(max) - SIMD3(min)
    }
}

// MARK: - float4x4 extensions
extension float4x4 {
    var translation: SIMD3<Float> {
        get {
            let translation = columns.3
            return [translation.x, translation.y, translation.z]
        }
        set(newValue) {
            columns.3 = [newValue.x, newValue.y, newValue.z, columns.3.w]
        }
    }

    var orientation: simd_quatf {
        return simd_quaternion(self)
    }

    init(uniformScale scale: Float) {
        self = matrix_identity_float4x4
        columns.0.x = scale
        columns.1.y = scale
        columns.2.z = scale
    }
}

// MARK: - UIGestureRecognizer extensions
extension UIGestureRecognizer {
    func center(in view: UIView) -> CGPoint? {
        guard numberOfTouches > 0 else { return nil }
        
        let first = CGRect(origin: location(ofTouch: 0, in: view), size: .zero)

        let touchBounds = (1..<numberOfTouches).reduce(first) { touchBounds, index in
            return touchBounds.union(CGRect(origin: location(ofTouch: index, in: view), size: .zero))
        }

        return CGPoint(x: touchBounds.midX, y: touchBounds.midY)
    }
}

// MARK: - SCNVector3 extensions
extension SCNVector3 {
    // from Apples demo APP
    static func positionFromTransform(_ transform: matrix_float4x4) -> SCNVector3 {
        return SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }
}

//enum ARUtil {
//    static var bundle: Bundle {
//        guard let path = Bundle.main.path(forResource: "XYARKit", ofType: "bundle") else {
//            fatalError("资源错误")
//        }
//        guard let bundle = Bundle(path: path) else {
//            fatalError("资源错误")
//        }
//        return bundle
//    }
//}



