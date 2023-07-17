//
//  ScanningNewItem.swift
//  kitchen sync
//
//  Created by Pelle Fredrikson on 2023-06-02.
//


import UIKit
import AVFoundation
import Firebase

class ScanningNewItem: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    weak var delegate: ScanningNewItemDelegate?
    var barcodeScanned = false

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            return
        }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr, .ean8, .ean13, .pdf417, .code128, .code39, .code93]
        
        } else {
            failed()
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        captureSession.startRunning()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if (captureSession.isRunning == false) {
            captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if (captureSession.isRunning == true) {
            captureSession.stopRunning()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if !barcodeScanned,
           let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let barcodeValue = metadataObject.stringValue {
            barcodeScanned = true
            let ref = Database.database(url:"https://kitchen-sync-1-5c7b4-default-rtdb.europe-west1.firebasedatabase.app").reference().child("products").child("\(barcodeValue)")
            ref.observeSingleEvent(of: .value) { snapshot in
                if snapshot.exists() {
                    // Show an error message to the user
                    let alert = UIAlertController(title: "Error", message: "Item already exist in database", preferredStyle: .alert)
                    self.present(alert, animated: true, completion: nil)
                      
                    // Add a completion handler for the alert controller's presentation
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        self.dismiss(animated: true, completion: nil)
                    })
                    
                    print("Product already exists")
                    self.captureSession.stopRunning()
                    
                } else {
                    print("\(barcodeValue)")
                    let newItemID = NewItemID(id: barcodeValue)
                    self.delegate?.didScanItem(newItemID)
                    self.captureSession.stopRunning()
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }

    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}
