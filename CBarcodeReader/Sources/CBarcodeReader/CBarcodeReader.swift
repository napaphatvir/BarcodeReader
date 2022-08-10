//
//  CBarcodeReader.swift
//  
//
//  Created by Napaphat on 5/8/2565 BE.
//

import AVFoundation
import UIKit

public protocol CBarcodeReaderDelegate: AnyObject {
    func barcodeReader(_ reader: CBarcodeReader, videoPreviewLayer layer: AVCaptureVideoPreviewLayer, objects: [AVMetadataMachineReadableCodeObject])
}


public final class CBarcodeReader: NSObject {
    private let session: AVCaptureSession = AVCaptureSession()
    private let previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
    private let output: AVCaptureMetadataOutput = AVCaptureMetadataOutput()
    private var input: AVCaptureDeviceInput?
    private var interestArea: CGRect = .zero {
        didSet {
            if session.outputs.contains(output) && session.isRunning {
                output.rectOfInterest = previewLayer.metadataOutputRectConverted(fromLayerRect: interestArea)
            }
        }
    }
    private var objectTypes: [AVMetadataObject.ObjectType] = [] {
        didSet {
            if session.outputs.contains(output) {
                output.metadataObjectTypes = objectTypes
            }
        }
    }
    private var orientation: AVCaptureVideoOrientation = .portrait {
        didSet {
            guard let connection = previewLayer.connection,
                  connection.isVideoOrientationSupported
            else { return }
            connection.videoOrientation = orientation
        }
    }
    
    public weak var delegate: CBarcodeReaderDelegate?
    
    override public init() {
        super.init()
        configureCamera()
    }
    
    func configureCamera() {
        DispatchQueue.global(qos: .userInitiated).async {
            let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                                    mediaType: .video,
                                                                    position: .back)
            
            guard let device = discoverySession.devices.first else { return }
            
            do {
                self.previewLayer.session = self.session
                self.previewLayer.videoGravity = .resizeAspectFill
                
                // Configure focus mode
                try device.lockForConfiguration()
                
                if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                }
                
                if device.isAutoFocusRangeRestrictionSupported {
                    device.autoFocusRangeRestriction = .near
                }
                
                if device.isExposurePointOfInterestSupported {
                    device.exposureMode = .continuousAutoExposure
                }
                
                device.unlockForConfiguration()
                
                // Add input and output
                self.input = try AVCaptureDeviceInput(device: device)
                
                guard let input = self.input else { return }

                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                } else {
                    self.session.inputs.forEach {
                        self.session.removeInput($0)
                    }
                    self.session.addInput(input)
                }
                
                if self.session.canAddOutput(self.output) {
                    self.session.addOutput(self.output)
                } else {
                    self.session.outputs.forEach {
                        self.session.removeOutput($0)
                    }
                    self.session.addOutput(self.output)
                }
                
                // Set object types
                if self.objectTypes.isEmpty {
                    self.objectTypes = self.output.availableMetadataObjectTypes
                }
                
                self.output.metadataObjectTypes = self.objectTypes
                self.output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                
                // Set orientation
                if let connection = self.previewLayer.connection,
                   connection.isVideoOrientationSupported {
                    connection.videoOrientation = self.orientation
                }
                
                // Start session
                self.session.startRunning()
                
                // Set rect of interest
                if !self.interestArea.isEmpty {
                    self.previewLayer.layoutIfNeeded()
                    self.output.rectOfInterest = self.previewLayer.metadataOutputRectConverted(fromLayerRect: self.interestArea)
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

//MARK: - Public Method
extension CBarcodeReader {
    public func start() {
        if !session.isRunning {
            session.startRunning()
        }
    }
    
    public func stop() {
        if session.isRunning {
            session.stopRunning()
        }
    }
    
    public func setPreviewLayerFrame(_ frame: CGRect) {
        previewLayer.frame = frame
        previewLayer.layoutIfNeeded()
    }
    
    public func addPreviewLayer(to view: UIView) {
        previewLayer.removeFromSuperlayer()
        view.layer.insertSublayer(previewLayer, at: 0)
        
    }
    
    public func setPreviewLayerOrientation(_ orientation: AVCaptureVideoOrientation) {
        self.orientation = orientation
    }
    
    public func setBarcodeTypes(_ types: [AVMetadataObject.ObjectType]) {
        if types.isEmpty { return }
        objectTypes = types
    }

    public func setInterestArea(in rect: CGRect) {
        if rect.isEmpty { return }
        
        if rect.height < 20 {
            let adjustY: CGFloat = (20 - rect.height) / 2
            interestArea = CGRect(x: rect.origin.x,
                           y: rect.origin.y - adjustY,
                           width: rect.width,
                           height: 20)
            return
        }
        
        interestArea = rect
    }
    
    public func addCustomCaptureOutput<T: AVCaptureOutput>(_ output: T) {
        if session.canAddOutput(output) {
            session.addOutput(output)
        } else {
            session.outputs.forEach {
                if $0 is T {
                    session.removeOutput($0)
                }
            }
            session.addOutput(output)
        }
    }
}

//MARK: - AVCaptureMetadataOutputObjectsDelegate
extension CBarcodeReader: AVCaptureMetadataOutputObjectsDelegate {
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        let readableObjects: [AVMetadataMachineReadableCodeObject] = metadataObjects.compactMap {
            $0 as? AVMetadataMachineReadableCodeObject
        }
        
        if !readableObjects.isEmpty {
            delegate?.barcodeReader(self,
                                     videoPreviewLayer: previewLayer,
                                     objects: readableObjects)
        }
    }
}

