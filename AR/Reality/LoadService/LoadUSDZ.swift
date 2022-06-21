//
//  VirtualObject.swift
//  ARView
//
//  Created by user on 5/17/22.
//

import UIKit
import RealityKit
import Combine

@available(iOS 13.0, *)
class LoadUSDZ: NSObject {
    
    static let shared = LoadUSDZ()
    
    private override init() {}
    
    // download model from local url
    public func loadObjectFromFilePath(_ url: URL, completion: @escaping (_ usdzEntity: USDZEntity) -> Void) {
        var cancellable: AnyCancellable? = nil
        
        cancellable = Entity.loadAsync(contentsOf: url)
            .sink(receiveCompletion: { error in
                print("Unexpected error: \(error)")
                cancellable?.cancel()
            }, receiveValue: { entity in
                let usdzEntity = USDZEntity(entity: entity)
                usdzEntity.generateCollisionShapes(recursive: true)
                cancellable?.cancel()
                completion(usdzEntity)
                usdzEntity.startAnimation()
            })
    }
}
