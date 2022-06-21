//
//  CameraButtonView.swift
//  scrollview
//
//  Created by user on 4/28/22.
//

import UIKit

protocol CameraButtonViewDelegate: AnyObject {
    func startCaptureVideo()
    func stopCaptureVideo()
    func takePhoto()
}

public class CameraButtonView: UIView {
    
    private let shutterWidth: CGFloat = 80.0
    private let activeNormalProgressWidth: CGFloat = 40.0
    private let progressLineWidth: CGFloat = 4.0
    private let fillWhiteWidth: CGFloat = 68.0
    
    weak var delegate: CameraButtonViewDelegate?
    
    public lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.font = UIFont(name: "PingFangSC-Regular", size: 13)
        label.textAlignment = .center
        label.textColor = .white
        label.layer.shadowColor = UIColor.white.withAlphaComponent(0.5).cgColor
        label.layer.shadowOffset = .zero
        label.layer.shadowRadius = 1
        label.layer.shadowOpacity = 1
        label.text = "0.0"
        return label
    }()
    
    private lazy var redPoint: UIView = {
        let view = UIView()
        view.backgroundColor = .red
        view.layer.cornerRadius = 3
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var timeView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isHidden = true
        return view
    }()

    // capture button UI
    private lazy var progressLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = progressLineWidth
        layer.path = activeNormalProgressCirclePath().cgPath
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.white.cgColor
        layer.isHidden = true
        return layer
    }()
    
    private lazy var progressBackLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = progressLineWidth
        layer.path = activeNormalProgressCirclePath().cgPath
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.white.cgColor
        return layer
    }()
    
    private lazy var videoBackgroundView: UIView = {
        let effect = UIBlurEffect(style: .light)
        let view = UIVisualEffectView(effect: effect)
        view.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        view.layer.cornerRadius = 33.0
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var photoBackgroundView: UIView = {
        let effect = UIBlurEffect(style: .light)
        let view = UIVisualEffectView(effect: effect)
        view.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        view.layer.cornerRadius = activeNormalProgressWidth
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()
    
    private lazy var shadowView: UIView = {
        let view = UIView()
        view.layer.shadowColor = UIColor.black.withAlphaComponent(0.6).cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
        view.layer.shadowOpacity = 1.0
        view.layer.shadowRadius = 3
        view.layer.cornerRadius = 26.0
        view.isHidden = true
        return view
    }()
    
    private lazy var centerWhiteView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 34.0
        view.isHidden = true
        return view
    }()
    
    private lazy var pauseView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 4.0
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()
    
    // switch camera mode
    var currentCameraMode: CameraMode = .video {
        didSet {
            switch currentCameraMode {
            case .picture:
                animateFromVideoShutterToPhotoShutter()
            case .video:
                animateFromPhotoShutterToVideoShutter()
            }
        }
    }
    
    // recording status
    private(set) var isRecording: Bool = false
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapActions(_:)))
        self.addGestureRecognizer(tap)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func tapActions(_ tap: UITapGestureRecognizer) {
        switch currentCameraMode {
        case .picture:
            addCenterImageViewAnimation()
            guard let delegate = delegate else {
                return
            }
            delegate.takePhoto()
        case .video:
            guard let delegate = delegate else {
                return
            }
            if isRecording {
                stopCapture()
                delegate.stopCaptureVideo()
            } else {
                startCapture()
                delegate.startCaptureVideo()
            }
        }
    }
    
    private func setupUI() {
        backgroundColor = .clear
        
        addSubview(videoBackgroundView)
        videoBackgroundView.snp.makeConstraints { make in
            let margin = 7.0
            make.left.top.equalTo(margin)
            make.right.bottom.equalTo(-margin)
        }
        
        addSubview(photoBackgroundView)
        photoBackgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        layer.addSublayer(progressBackLayer)
        
        addSubview(pauseView)
        pauseView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(30)
        }
        
        addSubview(shadowView)
        shadowView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(69)
        }
        
        layer.addSublayer(progressLayer)
        
        addSubview(centerWhiteView)
        centerWhiteView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(fillWhiteWidth)
        }
        
        addSubview(timeView)
        timeView.snp.makeConstraints { make in
            make.centerX.equalTo(pauseView)
            make.bottom.equalTo(pauseView.snp.top).offset(-49)
            make.size.equalTo(CGSize(width: 35, height: 16))
        }
        
        timeView.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(timeView)
            make.right.equalTo(timeView)
        }
        
        timeView.addSubview(redPoint)
        redPoint.snp.makeConstraints { make in
            make.centerY.equalTo(timeView)
            make.left.equalTo(timeView)
            make.size.equalTo(CGSize(width: 6, height: 6))
        }
    }
    
    private func addCenterImageViewAnimation() {
        progressBackLayer.removeAllAnimations()
        progressBackLayer.anchorPoint = CGPoint(x: 1, y: 0.5)
        let animation = CAKeyframeAnimation(keyPath: "transform.scale")
        animation.duration = 0.2
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        animation.values = [1.0, 0.95, 0.9, 1.0]
        centerWhiteView.layer.add(animation, forKey: "scale-animation")
    }
    
    private func removeAnimations() {
        progressLayer.removeAllAnimations()
        progressBackLayer.removeAllAnimations()
        centerWhiteView.layer.removeAllAnimations()
    }
    
    private func startCapture() {
        isRecording = true
        timeView.isHidden = false
        shadowView.isHidden = false
        pauseView.alpha = 0
        pauseView.isHidden = false
        pauseView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        
        self.videoBackgroundView.isHidden = true
        
        UIView.animate(withDuration: 0.2) {
            self.progressBackLayer.strokeColor = UIColor.white.withAlphaComponent(0.4).cgColor
            self.pauseView.alpha = 1.0
            self.pauseView.transform = .identity
            self.timeView.isHidden = false
            self.pauseView.backgroundColor = UIColor.red
        }
    }
    
    func stopCapture() {
        isRecording = false
        timeView.isHidden = true
        videoBackgroundView.isHidden = false
        progressLayer.isHidden = true
        pauseView.isHidden = true
        progressLayer.removeAllAnimations()
        
        pauseView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        
        UIView.animate(withDuration: 0.2) {
            self.pauseView.alpha = 1.0
            self.pauseView.transform = .identity
            self.progressBackLayer.strokeColor = UIColor.white.cgColor
        }
    }
    
    private func cancelShootWithAnimation(animation: Bool) {
        timeView.isHidden = true
        videoBackgroundView.isHidden = false
        progressLayer.isHidden = true
        pauseView.isHidden = true
        progressLayer.removeAllAnimations()
        
        pauseView.alpha = 1.0
        pauseView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        if animation {
            UIView.animate(withDuration: 0.2) {
                self.pauseView.alpha = 1.0
                self.pauseView.transform = .identity
                self.progressBackLayer.strokeColor = UIColor.white.cgColor
            }
        } else {
            pauseView.alpha = 1.0
            pauseView.transform = .identity
            progressBackLayer.strokeColor = UIColor.white.cgColor
        }
        timeLabel.text = "0.0"
    }

    private func videoToPhotoPath() -> UIBezierPath {
        let path = UIBezierPath(roundedRect: CGRect(x: (shutterWidth - fillWhiteWidth) / 2.0, y: (shutterWidth - fillWhiteWidth) / 2.0, width: fillWhiteWidth, height: fillWhiteWidth), cornerRadius: fillWhiteWidth / 2.0)
        return path
    }
    
    private func whiteLayerAnimation(from: CGPath, to: CGPath) -> CABasicAnimation {
        let pathAppear = CABasicAnimation(keyPath: "path")
        pathAppear.duration = 0.3
        pathAppear.fromValue = from
        pathAppear.toValue = to
        pathAppear.delegate = self
        pathAppear.isRemovedOnCompletion = false
        return pathAppear
    }
    
    private func animateFromPhotoShutterToVideoShutter() {
        photoBackgroundView.isHidden = true
        guard let path = progressBackLayer.path else { return }
        progressBackLayer.add(whiteLayerAnimation(from: path, to: activeNormalProgressCirclePath().cgPath), forKey: "animateToVideoShutter")
    }
    
    private func animateFromVideoShutterToPhotoShutter() {
        photoBackgroundView.isHidden = false
        guard let path = progressBackLayer.path else { return }
        progressBackLayer.add(whiteLayerAnimation(from: path, to: whiteProgressCirclePath().cgPath), forKey: "animateToPhotoShutter")
    }

    private func activeNormalProgressCirclePath() -> UIBezierPath {
        let path = UIBezierPath(arcCenter: CGPoint(x: shutterWidth / 2.0, y: shutterWidth / 2.0),
                                radius: shutterWidth / 2.0,
                                startAngle: -.pi / 2.0,
                                endAngle: 3 * .pi / 2,
                                clockwise: true)
        return path
    }
    
    private func whiteProgressCirclePath() -> UIBezierPath {
        let path = UIBezierPath(arcCenter: CGPoint(x: shutterWidth / 2.0, y: shutterWidth / 2.0),
                                radius: (fillWhiteWidth - progressLineWidth) / 2.0,
                                startAngle: -.pi / 2,
                                endAngle: 3 * .pi / 2,
                                clockwise: true)
        return path
    }
}

// MARK: - CAAnimationDelegate
extension CameraButtonView: CAAnimationDelegate {
    public func animationDidStart(_ anim: CAAnimation) {
        if anim == progressBackLayer.animation(forKey: "animateToPhotoShutter") {
            progressBackLayer.isHidden = false
            progressBackLayer.fillColor = UIColor.white.cgColor
            progressBackLayer.path = whiteProgressCirclePath().cgPath
            centerWhiteView.isHidden = true
        }
        
        if anim == progressBackLayer.animation(forKey: "animateToVideoShutter") {
            progressBackLayer.isHidden = false
            progressBackLayer.fillColor = UIColor.clear.cgColor
            progressBackLayer.path = activeNormalProgressCirclePath().cgPath
            centerWhiteView.isHidden = true
        }
    }
    
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        CATransaction.begin()
                
        if anim == progressBackLayer.animation(forKey: "animateToPhotoShutter") {
            progressBackLayer.isHidden = true
            centerWhiteView.isHidden = false
        }
        
        if anim == progressBackLayer.animation(forKey: "animateToVideoShutter") {
            progressBackLayer.isHidden = false
            centerWhiteView.isHidden = true
        }
        
        CATransaction.commit()
    }
}
