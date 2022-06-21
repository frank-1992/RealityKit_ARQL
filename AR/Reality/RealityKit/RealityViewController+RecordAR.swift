//
//  ARSceneController+RecordAR.swift
//  XYARKit
//
//  Created by user on 4/8/22.
//

import UIKit
import ARKit
import SceneKit
import Photos
import SCNRecorder

@available(iOS 13.0, *)
public extension RealityViewController {
    func setupCameraUI() {
        view.addSubview(videoButton)
        videoButton.snp.makeConstraints { make in
            make.centerX.equalTo(view)
            make.bottom.equalTo(view).offset(-163)
            make.size.equalTo(CGSize(width: 48, height: 48))
        }

        view.addSubview(pictureButton)
        pictureButton.snp.makeConstraints { make in
            make.centerY.equalTo(videoButton)
            make.left.equalTo(videoButton.snp.right).offset(32)
            make.size.equalTo(CGSize(width: 32, height: 48))
        }

        let bottomPadding = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0

        view.addSubview(cameraTabView)
        cameraTabView.snp.makeConstraints { make in
            make.centerX.equalTo(view)
            make.bottom.equalTo(view).offset(-34 - bottomPadding)
            make.size.equalTo(CGSize(width: 80, height: 80))
        }
    }

    func setupARRecord() {
        arView.prepareForRecording()
    }

    @objc
    func switchPictureMode() {
        UIView.animate(withDuration: 0.25) {
            self.pictureButton.transform = CGAffineTransform(translationX: -72, y: 0)
            self.videoButton.transform = CGAffineTransform(translationX: -72, y: 0)
            self.cameraTabView.currentCameraMode = .picture
        } completion: { _ in
            self.pictureButton.isSelected = true
            self.videoButton.isSelected = false
        }
    }

    @objc
    func switchVideoMode() {
        UIView.animate(withDuration: 0.25) {
            self.pictureButton.transform = CGAffineTransform.identity
            self.videoButton.transform = CGAffineTransform.identity
            self.cameraTabView.currentCameraMode = .video
        } completion: { _ in
            self.pictureButton.isSelected = false
            self.videoButton.isSelected = true
        }
    }
}

@available(iOS 13.0, *)
extension RealityViewController: CameraButtonViewDelegate {
    func startCaptureVideo() {
        videoButton.isHidden = true
        pictureButton.isHidden = true
        DispatchQueue.global().async {
            do {
                let videoRecording = try self.arView.startVideoRecording()
                videoRecording.$duration.observe(on: .main) { [weak self] duration in
                    if duration < Capture.limitedTime {
                        DispatchQueue.main.async {
                            self?.cameraTabView.timeLabel.text = String(format: "%.1f", duration)
                        }
                    } else {
                        DispatchQueue.main.async {
                            self?.stopCaptureVideo()
                            self?.cameraTabView.stopCapture()
                            self?.cameraTabView.timeLabel.text = "0.0"
                        }
                    }
                }
            } catch {
            }
        }
    }

    func stopCaptureVideo() {
        videoButton.isHidden = false
        pictureButton.isHidden = false
        cameraTabView.timeLabel.text = "0.0"
        DispatchQueue.global().async {
            self.arView.finishVideoRecording { [weak self] videoRecording in
                DispatchQueue.main.async {
                    self?.previewResult(with: .video(videoRecording.url))
                }
            }
        }
    }

    func takePhoto() {
        DispatchQueue.global().async {
            self.arView.takePhotoResult { [weak self] (result: Result<UIImage, Swift.Error>) in
                switch result {
                case .success(let image):
                    DispatchQueue.main.async {
                        self?.previewResult(with: .image(image))
                    }
                case .failure(let error):
                    print(error)
                }
            }
        }
    }

    private func previewResult(with resource: ARResultMediaType) {
        let controller = ARResultController(mediaType: resource)
//        controller.model = self.model
        controller.modalPresentationStyle = .fullScreen
        self.present(controller, animated: true)
    }
}
