//
//  CoachingOverlayView.swift
//  XYARKit
//
//  Created by user on 5/5/22.
//

import UIKit
import Lottie

public class PlanDetectionView: UIView {
    
    private var timer: Timer?
    private var time: TimeInterval = 0
    private var limitedTime: TimeInterval = 30
    
    var animationHidden: Bool = false {
        didSet {
            if !animationHidden {
                isHidden = false
                playAnimation()
                backgroundColor = UIColor(white: 0, alpha: 0.2)
                if timer == nil {
                    timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(planDetectionViewLimitedTime), userInfo: nil, repeats: true)
                    timer?.fire()
                }
            } else {
                pauseAnimation()
                timer?.invalidate()
                time = 0
                timer = nil
                UIView.animate(withDuration: 0.25) {
                    self.backgroundColor = UIColor(white: 0, alpha: 0)
                } completion: { _ in
                    self.isHidden = true
                }
            }
            animationView.isHidden = animationHidden
        }
    }
    
    deinit {
        timer?.invalidate()
        time = 0
        timer = nil
    }

    private lazy var animationView: AnimationView = {
        let animationView = AnimationView(name: "find_plane")
        animationView.loopMode = .autoReverse
        return animationView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = false
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        backgroundColor = UIColor(white: 0, alpha: 0.2)
        addSubview(animationView)
        animationView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            let scale = 2.19
            let width = 360.0
            let height = width / scale
            make.size.equalTo(CGSize(width: width, height: height))
        }
    }
    
    private func playAnimation() {
        animationView.play()
    }
    
    private func pauseAnimation() {
        animationView.stop()
    }
    
    @objc
    private func planDetectionViewLimitedTime() {
        time += 1
        if time >= limitedTime {
            pauseAnimation()
            self.isHidden = true
        }
    }
}
