//
//  ViewController.swift
//  ExampleBarcodeScanner
//
//  Created by Napaphat on 5/8/2565 BE.
//

import UIKit
import CBarcodeReader
import AVFoundation

class ViewController: UIViewController {
    override var shouldAutorotate: Bool { false }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { .portrait }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    
    private lazy var imagePreview: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.alpha = 0
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowRadius = 15
        view.layer.shadowOpacity = 0.5
        view.layer.shadowOffset = CGSize(width: 3, height: 5)
        view.isUserInteractionEnabled = true
        return view
    }()
    
    private lazy var captureButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowRadius = 15
        button.layer.shadowOpacity = 0.5
        return button
    }()
    
    private let barcodeReader: CBarcodeReader = CBarcodeReader()
    private let captureOutput: AVCapturePhotoOutput = AVCapturePhotoOutput()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        barcodeReader.addPreviewLayer(to: view)
        barcodeReader.delegate = self
        barcodeReader.addCustomCaptureOutput(captureOutput)
        
        captureButton.addTarget(self, action: #selector(captureImage), for: .touchUpInside)
        
        imagePreview.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(swipeImagePreview(_:))))
        
        view.addSubview(captureButton)
        view.addSubview(imagePreview)
        view.bringSubviewToFront(imagePreview)
        
        NSLayoutConstraint.activate([
            imagePreview.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            imagePreview.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            imagePreview.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.3),
            imagePreview.widthAnchor.constraint(equalTo: imagePreview.heightAnchor, multiplier: 0.5),
            
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            captureButton.heightAnchor.constraint(equalToConstant: 75),
            captureButton.widthAnchor.constraint(equalToConstant: 75),
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        barcodeReader.setPreviewLayerFrame(view.bounds)
        captureButton.layer.cornerRadius = captureButton.bounds.width/2
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        barcodeReader.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        barcodeReader.stop()
    }
    
    @objc private func swipeImagePreview(_ gesture: UIPanGestureRecognizer) {
        
        let translation: CGPoint = gesture.translation(in: view)
        guard let view = gesture.view else { return }
        
        if translation.x > 0 {
            view.transform = CGAffineTransform(translationX: translation.x, y: 0)
        }
        
        if gesture.state == .ended {
            if translation.x > view.bounds.width/2 {
                UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseInOut) {
                    self.imagePreview.transform = CGAffineTransform(translationX: view.bounds.width, y: 0)
                    self.imagePreview.alpha = 0
                } completion: { _ in
                    self.imagePreview.isHidden = true
                    self.imagePreview.transform = .identity
                }
            } else {
                view.transform = .identity
            }
        }
        
    }
    
    @objc private func captureImage() {
        captureOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }
    
    // if you want to support orientation uncomment code below
    // and override 'shouldAutorotate', 'preferredInterfaceOrientationForPresentation', 'supportedInterfaceOrientations'
    // or you can make your customize UIViewController
    /*
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            var interfaceOrientaion: UIInterfaceOrientation = .portrait
            if #available(iOS 13, *) {
                if let windowScene = UIApplication.shared.connectedScenes
                    .filter({ $0.activationState == .foregroundActive })
                    .compactMap({ $0 as? UIWindowScene })
                    .first {
                    interfaceOrientaion = windowScene.interfaceOrientation
                }
            } else {
                interfaceOrientaion = UIApplication.shared.statusBarOrientation
            }
            
            let videoOrientation: AVCaptureVideoOrientation
            switch interfaceOrientaion {
            case .unknown, .portrait:
                videoOrientation = AVCaptureVideoOrientation.portrait
            case .portraitUpsideDown:
                videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
            case .landscapeLeft:
                videoOrientation = AVCaptureVideoOrientation.landscapeLeft
            case .landscapeRight:
                videoOrientation = AVCaptureVideoOrientation.landscapeRight
            @unknown default:
                videoOrientation = AVCaptureVideoOrientation.portrait
            }
            
            self.barcodeReader.setPreviewLayerOrientation(videoOrientation)
            self.barcodeReader.setPreviewLayerFrame(self.view.bounds)
        })
    }
    */
}

extension ViewController: CBarcodeReaderDelegate {
    func barcodeReader(_ reader: CBarcodeReader, videoPreviewLayer layer: AVCaptureVideoPreviewLayer, objects: [AVMetadataMachineReadableCodeObject]) {
        guard let object = objects.first,
              let barcode = object.stringValue
        else { return }
        
        reader.stop()
        let alertController: UIAlertController = UIAlertController(title: "Barcode",
                                                                   message: "Your barcode string : \(barcode)",
                                                                   preferredStyle: .alert)
        let alertAction: UIAlertAction = UIAlertAction(title: "Close", style: .default) { _ in
            reader.start()
        }
        
        alertController.addAction(alertAction)
        present(alertController, animated: true)
    }
}

extension ViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data)
        else { return }
        
        imagePreview.image = image
        imagePreview.isHidden = false
        imagePreview.alpha = 0
        imagePreview.transform = .identity
        UIView.animate(withDuration: 1, delay: 0, options: .curveEaseInOut) {
            self.imagePreview.alpha = 1
        }
    }
}
