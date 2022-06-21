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
        button.setTitle("R-Space", for: .normal)
        button.setTitleColor(.red, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.layer.cornerRadius = 6
        button.layer.borderColor = UIColor.green.cgColor
        button.layer.borderWidth = 1
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

