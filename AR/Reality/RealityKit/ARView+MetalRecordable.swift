//
//  ARView+SceneRecordableView.swift
//  SCNRecorder
//

import Foundation
import RealityKit

private var sceneRecorderKey: UInt8 = 0
private var cancellableKey: UInt8 = 0

@available(iOS 13.0, *)
extension ARView: MetalRecordable {

  #if !targetEnvironment(simulator)
  public var recordableLayer: RecordableLayer? { layer.sublayers?.first as? RecordableLayer }
  #else
  public var recordableLayer: RecordableLayer? { layer as? RecordableLayer }
  #endif
}
