//
//  USDZEntity.swift
//  AR-RealityKit
//
//  Created by 吴熠 on 5/28/22.
//

import RealityKit
import Combine
import GameKit

@available(iOS 13.0, *)
public class USDZEntity: Entity, HasAnchoring, HasCollision {
    private var cancels: Set<AnyCancellable> = .init()

    var entity: Entity?
    
    var currentBoundingBoxMin: SIMD3<Float> = .zero
    var currentBoundingBoxMax: SIMD3<Float> = .zero
    
    var initPosition: SIMD3<Float> = .zero
    var initOrientation: simd_quatf?
    
    var shadowDistance: Float? {
        didSet {
            guard let shadowDistance = shadowDistance else {
                return
            }
            if shadowDistance > 1 {
                horizontalShadowLight.shadow?.maximumDistance = shadowDistance
            } else {
                horizontalShadowLight.shadow?.maximumDistance = 0.6
            }
        }
    }
    
    private lazy var horizontalShadowLight: DirectionalLight = {
        // add shadow light
        let directionalLight = DirectionalLight()
        directionalLight.light.color = .white
        directionalLight.light.intensity = 1000
        directionalLight.light.isRealWorldProxy = true
        directionalLight.shadow = DirectionalLightComponent.Shadow()
        directionalLight.shadow?.maximumDistance = 0.2
        directionalLight.orientation = simd_quatf(angle: -.pi / 2.0, axis: [1, 0, 0])
        directionalLight.position = .zero
        return directionalLight
    }()
    
    var horizontalPlaneEntity: ModelEntity?
    
    var alignment: USDZAlignment? {
        didSet {
            switch alignment {
            case .usdzHorizontal:
                // show horizontal plane and hide vertical plane
                // switch which light
                horizontalPlaneEntity?.isEnabled = true
                horizontalShadowLight.isEnabled = true
                                
                entity?.position = initPosition
            case .usdzVertical:
                // show vertical plane and hide horizontal plane
                // switch which light
                horizontalPlaneEntity?.isEnabled = false
                horizontalShadowLight.isEnabled = false
                
                // set entity's position
                let depth = currentBoundingBoxMax.z - currentBoundingBoxMin.z
                entity?.position = SIMD3(x: initPosition.x, y: initPosition.y, z: depth / 2.0)
            default:
                break
            }
        }
    }
    
    required init(entity: Entity) {
        super.init()
        self.name = "usdzModel"
        let boundingBox = entity.visualBounds(relativeTo: entity)
        
        let originHeight = boundingBox.max.y - boundingBox.min.y
        let standardHeight: Float = 1.5
        let scaleFactor = standardHeight / originHeight
        let newMin = SIMD3(x: (boundingBox.min.x * scaleFactor), y: (boundingBox.min.y * scaleFactor), z: (boundingBox.min.z * scaleFactor))
        let newMax = SIMD3(x: (boundingBox.max.x * scaleFactor), y: (boundingBox.max.y * scaleFactor), z: (boundingBox.max.z * scaleFactor))
        
        let width = newMax.x - newMin.x
        let depth = newMax.z - newMin.z
        
        let x = newMin.x + width / 2.0
        let y = newMin.y
        let z = newMin.z + depth / 2.0
                
        currentBoundingBoxMin = newMin
        currentBoundingBoxMax = newMax
        
        entity.scale = SIMD3(x: scaleFactor, y: scaleFactor, z: scaleFactor)
        entity.position = SIMD3(x: -x, y: -y, z: -z)
         
        initPosition = entity.position
        initOrientation = entity.orientation
                
        self.entity = entity
        addChild(entity)
        
        // shadow settings
        addHorizontalPlane()
        addLight()
        self.generateCollisionShapes(recursive: true)
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
    
    func startAnimation() {
        for animation in self.availableAnimations {
            self.playAnimation(animation.repeat(), transitionDuration: 0.75, startsPaused: false)
        }
    }
    
    private func addHorizontalPlane() {
        let boundingBox = self.visualBounds(relativeTo: self)
        let width = boundingBox.max.x - boundingBox.min.x
        let depth = boundingBox.max.z - boundingBox.min.z
        let edge = sqrt(width * width + depth * depth)
        
        // add shadow plane to usdzEntity
        let plane = MeshResource.generatePlane(width: edge, depth: edge, cornerRadius: edge / 2.0)
        let material = OcclusionMaterial(receivesDynamicLighting: true)
        let planeEntity = ModelEntity(mesh: plane, materials: [material])
        planeEntity.position = SIMD3(x: 0, y: 0, z: 0)
        addChild(planeEntity)
        planeEntity.isEnabled = false
        horizontalPlaneEntity = planeEntity
    }
    
    private func addLight() {
        addChild(horizontalShadowLight)
        
        horizontalShadowLight.isEnabled = false
    }
    
    // when previous alignment is vertical and current alignment is horizontal ,
    //we should reset entity's Orientation
    func resetEntityOirentation() {
        guard let entity = entity,
              let orientation = initOrientation else {
            return
        }
        entity.orientation = orientation
    }
    
    func setVerticalRotation(with rotation: Float) {
        guard let entity = entity else {
            return
        }
        
        let orientation = entity.orientation
        var glQuaternion = GLKQuaternionMake(orientation.vector.x, orientation.vector.y, orientation.vector.z, orientation.vector.w)
        let multiplier = GLKQuaternionMakeWithAngleAndAxis(rotation, 0, 0, 1)
        glQuaternion = GLKQuaternionMultiply(glQuaternion, multiplier)

        let currentOrientation = simd_quatf(ix: glQuaternion.x, iy: glQuaternion.y, iz: glQuaternion.z, r: glQuaternion.w)
        entity.setOrientation(currentOrientation, relativeTo: self)
    }
}
