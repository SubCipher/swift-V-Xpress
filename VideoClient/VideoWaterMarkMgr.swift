
//
//  ViewController.swift
//  WaterMarkDemo
//
//  Created by knax on 10/21/17.
//  Copyright © 2017 StepwiseDesigns. All rights reserved.
//
import UIKit
import AssetsLibrary
import AVFoundation
import Photos
import CoreGraphics

enum watermarkPosition {
    case TopLeft
    case TopRight
    case BottomLeft
    case BottomRight
    case Default
}

class VideoWaterMarkMgr: NSObject {
    
    func watermark(video videoAsset:AVAsset, watermarkText text : String, saveToLibrary flag : Bool, watermarkPosition position : watermarkPosition, completion : ((_ status : AVAssetExportSessionStatus?, _ session: AVAssetExportSession?, _ outputURL : URL?) -> ())?) {
        
        
        self.watermark(video: videoAsset, watermarkText: text, imageName: nil, saveToLibrary: flag, watermarkPosition: position) {
            (status, session, outputURL) -> () in
            completion!(status, session, outputURL)
        }
    }
    
    
    func watermark(video videoAsset:AVAsset, imageName name : String, saveToLibrary flag : Bool, watermarkPosition position : watermarkPosition, completion : ((_ status : AVAssetExportSessionStatus?, _ session: AVAssetExportSession?, _ outputURL : URL?) -> ())?) {
        
        self.watermark(video: videoAsset, watermarkText: nil, imageName: name, saveToLibrary: flag, watermarkPosition: position) {
            
            (status, session, outputURL) -> () in
            completion!(status, session, outputURL)
        }
    }
    
    
    
    private func watermark(video videoAsset:AVAsset, watermarkText text : String!, imageName name : String!, saveToLibrary flag : Bool, watermarkPosition position : watermarkPosition, completion : ((_ status : AVAssetExportSessionStatus?, _ session: AVAssetExportSession?, _ outputURL : URL?) -> ())?) {
        
        DispatchQueue.global().async(execute: { () -> Void in
            // 1 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
            let mixComposition = AVMutableComposition()
            
            // 2 - Create video tracks
            let compositionVideoTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            let clipVideoTrack = videoAsset.tracks(withMediaType: AVMediaType.video)[0]
            
            
            do {
                try compositionVideoTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, videoAsset.duration), of: clipVideoTrack, at: kCMTimeZero)
                
            }  catch { }
            
            _ = clipVideoTrack.preferredTransform
            
            // Video size
            let videoSize = clipVideoTrack.naturalSize
            
            // sorts the layer in proper order and add title layer
            let parentLayer = CALayer()
            let videoLayer = CALayer()
            //redFrame (len,width,videoSize.width, videoSize.height) the waterMark frame
            parentLayer.frame = self.CGRectMake(500,-400, videoSize.width, videoSize.height)
            
            //video (horizontal,vertical, videoSize.width, videoSize.height)
            videoLayer.frame = self.CGRectMake(300,150, videoSize.width, videoSize.height)
            parentLayer.addSublayer(videoLayer)
            
            if text != nil {
                // Adding watermark text
                let titleLayer = CATextLayer()
                titleLayer.backgroundColor = UIColor.red.cgColor
                titleLayer.string = text
                titleLayer.font = "Helvetica" as CFTypeRef
                titleLayer.fontSize = 24
                titleLayer.alignmentMode = kCAAlignmentCenter
                //video frame
                titleLayer.bounds = self.CGRectMake(-450,0, videoSize.width, videoSize.height)
                parentLayer.addSublayer(titleLayer)
                
                print("\(videoSize.width)")
                print("\(videoSize.height)")
            } else if name != nil {
                // Adding image
                let watermarkImage = UIImage(named: name)
                let imageLayer = CALayer()
                imageLayer.contents = watermarkImage?.cgImage
                
                var xPosition : CGFloat = 0.0
                var yPosition : CGFloat = 0.0
                let imageSize : CGFloat = 1.0
                
                switch (position) {
                case .TopLeft:
                    xPosition = 0
                    yPosition = 0
                    break
                case .TopRight:
                    xPosition = videoSize.width - imageSize
                    yPosition = 0
                    break
                case .BottomLeft:
                    xPosition = 0
                    yPosition = videoSize.height - imageSize
                    break
                case .BottomRight, .Default:
                    xPosition = videoSize.width - imageSize
                    yPosition = videoSize.height - imageSize
                    break
              
                }
                
                print("xPosition\(xPosition)")
                print("yPosition\(yPosition)")
                
                imageLayer.frame = self.self.CGRectMake(xPosition, yPosition, imageSize, imageSize)
                imageLayer.opacity = 0.95
                parentLayer.addSublayer(imageLayer)
            }
            
            let videoComp = AVMutableVideoComposition()
            videoComp.renderSize = videoSize
            videoComp.frameDuration = CMTimeMake(1, 30)
            videoComp.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
            
            /// instruction
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRangeMake(kCMTimeZero, mixComposition.duration)
            _ = mixComposition.tracks(withMediaType: AVMediaType.video)[0] as AVAssetTrack
            
            let layerInstruction = self.videoCompositionInstructionForTrack(track: compositionVideoTrack!, asset: videoAsset)
            
           // let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
            
            instruction.layerInstructions = [layerInstruction]
            videoComp.instructions = [instruction]
            
            // 4 - Get path
            let documentDirectory = NSTemporaryDirectory() as NSString
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .short
            let date = dateFormatter.string(from: Date() )
            let savePath = documentDirectory.appendingPathComponent(NSUUID().uuidString + "watermark.mp4")
            print("savePath",savePath)
            
            
            let url = NSURL(fileURLWithPath: savePath)
            
            // 5 - Create Exporter
            let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)
            exporter?.outputURL = url as URL
            print(" exporter?.outputURL", exporter?.outputURL)
            //exporter?.outputFileType = AVFileTypeQuickTimeMovie
            exporter?.outputFileType = AVFileType.mp4
            exporter?.shouldOptimizeForNetworkUse = true
            exporter?.videoComposition = videoComp
            
            print("videoComp",videoComp)
            
            // 6 - Perform the Export
            exporter?.exportAsynchronously() {
                 print("performExport")
                DispatchQueue.main.async(execute: { () -> Void in
                     print("dispatchQueue")
                    if exporter?.status == AVAssetExportSessionStatus.completed {
                        print("exporter?.status",exporter?.status)

                        let outputURL = exporter?.outputURL
                        print("flag value",flag)
                        if flag {
                            // Save to library
                            PHPhotoLibrary.shared().performChanges({
                                let options = PHAssetResourceCreationOptions()
                                options.shouldMoveFile = false
                                
                                //MARK:- Create video file
                                
                                let creationRequest = PHAssetCreationRequest.forAsset()
                                creationRequest.addResource(with: .video, fileURL:  outputURL!, options: options)
                                print("save to PhotoLib")
                            }, completionHandler: { (success, error) in
                                if !success {
                                    print("Could not save video to photo library: ",error?.localizedDescription ?? "error code not found: SaveToPhotoLibrary")
                                    return
                                }
                                  print("Ⓜ️save waterMarked Video")
                                 completion!(AVAssetExportSessionStatus.completed, exporter, outputURL!)
                            }
                                
                                
                            )} else {
                            // Dont save to library
                            completion!(AVAssetExportSessionStatus.completed, exporter, outputURL!)
                        }
                        
                    } else {
                        // Error
                        completion!(exporter?.status, exporter, nil)
                    }
                }
                    
                )}
        }
      )}
    
    private func orientationFromTransform(transform: CGAffineTransform) -> (orientation: UIImageOrientation, isPortrait: Bool) {
        var assetOrientation = UIImageOrientation.up
        var isPortrait = false
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .right
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .left
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .down
        }
        return (assetOrientation, isPortrait)
    }
    
    private func videoCompositionInstructionForTrack(track: AVCompositionTrack, asset: AVAsset) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let assetTrack = asset.tracks(withMediaType: AVMediaType.video)[0]
        
        let transform = assetTrack.preferredTransform
        let assetInfo = orientationFromTransform(transform: transform)
        
        var scaleToFitRatio = UIScreen.main.bounds.width / assetTrack.naturalSize.width
        if assetInfo.isPortrait {
            scaleToFitRatio = UIScreen.main.bounds.width / assetTrack.naturalSize.height
            let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)
            instruction.setTransform(assetTrack.preferredTransform.concatenating(scaleFactor),
                                     at: kCMTimeZero)
        } else {
            let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)
            var concat = assetTrack.preferredTransform.concatenating(scaleFactor).concatenating(CGAffineTransform(translationX: 0, y: UIScreen.main.bounds.width / 2))
            if assetInfo.orientation == .down {
                let fixUpsideDown = CGAffineTransform(rotationAngle: .pi)
                let windowBounds = UIScreen.main.bounds
                let yFix = assetTrack.naturalSize.height + windowBounds.height
                let centerFix = CGAffineTransform(translationX: assetTrack.naturalSize.width, y: yFix)
                concat = fixUpsideDown.concatenating(centerFix).concatenating(scaleFactor)
            }
            instruction.setTransform(concat, at: kCMTimeZero)
        }
        
        return instruction
    }
}


extension VideoWaterMarkMgr{
    
    func CGRectMake(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    
    
}
