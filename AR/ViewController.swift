//
//  ViewController.swift
//  AR
//
//  Created by user on 6/2/22.
//

import UIKit

@available(iOS 13.0, *)
class ViewController: UIViewController {
    
    private lazy var enterButton: UIButton = {
        let button = UIButton()
        button.setTitle("RealityKit", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.backgroundColor = UIColor.systemRed
        button.addTarget(self, action: #selector(showARController), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        view.backgroundColor = .white
        
        view.addSubview(enterButton)
        
        enterButton.snp.makeConstraints { make in
            make.center.equalTo(view)
            make.size.equalTo(CGSize(width: 150, height: 60))
        }
    }
    
    @objc
    private func showARController() {
        let arSceneVC = RealityViewController()
        arSceneVC.modalPresentationStyle = .fullScreen
        self.present(arSceneVC, animated: true)
    }


}

