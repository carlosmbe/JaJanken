//
//  CameraViewController.swift
//  JaJanken
//
//  Created by Carlos Mbendera on 2023-04-14.
//


import AVFoundation
import UIKit
import Vision

enum errors: Error{
    //TODO: Write actual error cases
    case TooLazyToWrite
}

final class CameraViewController : UIViewController{
    
    private var cameraFeedSession: AVCaptureSession?
    
    override func loadView() {
        view = CameraPreview()
    }
    
    private var cameraView: CameraPreview{ view as! CameraPreview}
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        do{
            
            if cameraFeedSession == nil{
                try setupAVSession()
                
                cameraView.previewLayer.session = cameraFeedSession
                //MARK: Commented out cause it cropped
             //   cameraView.previewLayer.videoGravity = .resizeAspectFill
            }
            
            //MARK: Surronded the code into a DispatchQueue Cause we were having crashes
            DispatchQueue.global(qos: .userInteractive).async {
                self.cameraFeedSession?.startRunning()
               }
            
        }catch{
            print(error.localizedDescription)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        cameraFeedSession?.stopRunning()
        super.viewDidDisappear(animated)
    }
    
    private let videoDataOutputQueue =
        DispatchQueue(label: "CameraFeedOutput", qos: .userInteractive)
    
    
    func setupAVSession() throws {
        //Start of setup
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            throw errors.TooLazyToWrite
        }
        
        guard let deviceInput = try? AVCaptureDeviceInput(device: videoDevice) else{
            throw errors.TooLazyToWrite
        }
        
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSession.Preset.high
        
        guard session.canAddInput(deviceInput) else{
            throw errors.TooLazyToWrite
        }
        
        session.addInput(deviceInput)
        
        let dataOutput = AVCaptureVideoDataOutput()
        if session.canAddOutput(dataOutput){
            session.addOutput(dataOutput)
            dataOutput.alwaysDiscardsLateVideoFrames = true
            dataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        }else{
            throw errors.TooLazyToWrite
        }
        
        session.commitConfiguration()
        cameraFeedSession = session
    }
    
    
    //MARK: Vision Functions and Init Below
    
    private let handPoseRequest : VNDetectHumanHandPoseRequest = {
            let request = VNDetectHumanHandPoseRequest()
            request.maximumHandCount = 1
            return request
        }()
        
     
        var pointsProcessorHandler: (([CGPoint]) -> Void)?

        func processPoints(_ fingerTips: [CGPoint]) {
          
          let convertedPoints = fingerTips.map {
            cameraView.previewLayer.layerPointConverted(fromCaptureDevicePoint: $0)
          }

          pointsProcessorHandler?(convertedPoints)
        }
        
    }


    extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate{
        //Handler and Observation
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            
            var fingerTips: [CGPoint] = []
            defer {
              DispatchQueue.main.sync {
                self.processPoints(fingerTips)
              }
            }

            
            let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer,   orientation: .up,   options: [:])
            
            do{
                try handler.perform([handPoseRequest])
                
                guard let results = handPoseRequest.results?.prefix(2),     !results.isEmpty  else{
                    return
                }
                
                var recognizedPoints: [VNRecognizedPoint] = []
                
                try results.forEach { observation in
                    
                    let fingers = try observation.recognizedPoints(.all)
                    
                    
                    if fingers[.thumbTip]?.confidence ?? 0.0 > 0.7{
                        recognizedPoints.append(fingers[.thumbTip]!)
                    }
                    
                    
                    if fingers[.indexTip]?.confidence ?? 0.0 > 0.7  {
                            recognizedPoints.append(fingers[.indexTip]!)
                        }
                    
                    
                    if fingers[.middleTip]?.confidence ?? 0.0 > 0.7 {
                        recognizedPoints.append(fingers[.middleTip]!)
                    }
                    
                    
                    if fingers[.ringTip]?.confidence ?? 0.0 > 0.7 {
                        recognizedPoints.append(fingers[.ringTip]!)
                    }
                    
                    if fingers[.littleTip]?.confidence ?? 0.0 > 0.7 {
                        recognizedPoints.append(fingers[.littleTip]!)
                    }
                    
                }
                
                fingerTips = recognizedPoints.filter {
                  $0.confidence > 0.9
                }
                .map {
                  CGPoint(x: $0.location.x, y: 1 - $0.location.y)
                }
                
                
            }catch{
                cameraFeedSession?.stopRunning()
            }
            
        }
        
    }
