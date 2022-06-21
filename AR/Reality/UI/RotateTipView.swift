//
//  RotateTipView.swift
//  XYARKit
//
//  Created by user on 5/6/22.
//

import UIKit
import Lottie

public class RotateTipView: UIView {

    private lazy var animationView: AnimationView = {
        let animationView = AnimationView(name: "rotate")
        animationView.loopMode = .loop
        return animationView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(animationView)
        animationView.frame = self.bounds
        animationView.play()
    }
}
