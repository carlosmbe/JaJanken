//
//  CameraPreview.swift
//  JaJanken
//
//  Created by Carlos Mbendera on 2023-04-14.
//

import UIKit
import AVFoundation

final class CameraPreview: UIView{
    
    var previewLayer : AVCaptureVideoPreviewLayer{
        layer as! AVCaptureVideoPreviewLayer
    }
    
    override class var layerClass: AnyClass{
        AVCaptureVideoPreviewLayer.self
    }
}
