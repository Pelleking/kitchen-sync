//
//  ScanningViewController.swift
//  kitchen sync
//
//  Created by Pelle Fredrikson on 2023-05-30.
//
import UIKit
import AVFoundation
import Firebase
import Foundation
protocol ScanningViewControllerDelegate: AnyObject {
    func didScanItem(_ item: ScannedItem)
}

extension ScanningViewControllerDelegate where Self: UIViewController {
    var delegate: ScanningViewControllerDelegate? {
        get { return self as? ScanningViewControllerDelegate }
        set { fatalError("Setting delegate is not supported") }
    }
}

class ScanningViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {


    weak var delegate: ScanningViewControllerDelegate?
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var scannedItem: ScannedItem?
    var barcodeScanned = false
    var scanningEnabled = true
    let scanDelay: TimeInterval = 2.0 // Add this line and adjust the delay time as needed


    
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
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
            let barcodeValue = metadataObject.stringValue {
            if !barcodeScanned {
                barcodeScanned = true

            let ref = Database.database(url:"https://kitchen-sync-1-5c7b4-default-rtdb.europe-west1.firebasedatabase.app").reference().child("products").child("\(barcodeValue)")
            ref.observeSingleEvent(of: .value) { snapshot in
                guard let value = snapshot.value as? [String: Any],
                      let name = value["name"] as? String,
                      let category = value["category"] as? String,
                      let bestbefore = value["best-before"] as? String else {
                    
                    print("Product not found")
                 
                   
                    let alert = UIAlertController(title: "Error", message: "Item don't exist in database - please add it", preferredStyle: .alert)
                    self.present(alert, animated: true, completion: nil)
                      
                    // Add a completion handler for the alert controller's presentation
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        self.dismiss(animated: true, completion: nil)
                    })
                    
                    print("Product already exists")
                    self.captureSession.stopRunning()
                    
                    return
                }
                
                print("Product name - \(name) - bestbefore \(bestbefore) - category \(category)")

                let scannedItem = ScannedItem(id: barcodeValue, name: name, category: category, bestbefore: bestbefore)
                self.delegate?.didScanItem(scannedItem)

                // Set scanningEnabled to false to prevent rapid scanning
                //self.scanningEnabled = false
                self.captureSession.stopRunning() // Stop the camera feed
          //  Use the DispatchQueue asyncAfter method to enable scanning after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                   self.scanningEnabled = true
                }

                
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
