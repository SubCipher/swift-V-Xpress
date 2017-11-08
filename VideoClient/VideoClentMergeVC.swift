//
//  VideoClentMergeVC.swift
//  VideoClient
//
//  Created by knax on 10/18/17.
//  Copyright © 2017 StepwiseDesigns. All rights reserved.
//


import UIKit
import AVFoundation
import AVKit
import MobileCoreServices
import AssetsLibrary
import Photos

import MediaPlayer
import CoreMedia

class VideoClientMergeVC: UIViewController {
    

    var firstVideoAsset: AVAsset?
    var secondVideoAsset: AVAsset?
    var thirdVideoAsset: AVAsset?
    var fourthVideoAsset: AVAsset?
    var audioAsset: AVAsset?
    var loadingVideoAsset = 0
    var assetDidLoad = false
    var assetsLoaded = 0
    var playbackURL: URL?
    var assetsArray = [AVAsset]()
    
    
    let avPlayerViewController = AVPlayerViewController()
    var avPlayer: AVPlayer?
    
    
    var VIDEO_WIDTH = 640.0
    var VIDEO_HEIGHT = 480.0
    
    enum assetSeqNumber: Int {
    case one = 1,two,three,four
    
    }
    
    
    @IBOutlet var activityMonitor: UIActivityIndicatorView!
    
    
    @IBOutlet weak var videoPlaybackOutlet: UIButton!
    
    @IBOutlet weak var mergeAssetsOutlet: UIButton!
    
    @IBOutlet weak var videoPostOutlet: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        videoPlaybackOutlet.isEnabled = false
        videoPostOutlet.isEnabled = false
        mergeAssetsOutlet.isEnabled = false
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        assetCheck()
    }

    func savedPhotosAvailable() -> Bool {
        
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) == false {
            let alert = UIAlertController(title: "Not Available", message: "No Saved Album found", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            return false
        }
        return true
    }
    
    func startMediaBrowserFromViewController(_ viewController: UIViewController!, usingDelegate delegate : (UINavigationControllerDelegate & UIImagePickerControllerDelegate)!) -> Bool {
        
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) == false {
            return false
        }
        
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .savedPhotosAlbum
        imagePicker.mediaTypes = [kUTTypeMovie as NSString as String]
        imagePicker.allowsEditing = true
        imagePicker.delegate = delegate
        present(imagePicker, animated: true, completion: nil)
        return true
    }
    
    @IBAction func loadVideoAssetOne(_ sender: AnyObject) {
        if savedPhotosAvailable() {
            
             loadingVideoAsset = assetSeqNumber.one.rawValue
            
            _ = startMediaBrowserFromViewController(self, usingDelegate: self)
        }
    }
    
    
    @IBAction func loadVideoAssetTwo(_ sender: AnyObject) {
        
        if savedPhotosAvailable() {
           
            loadingVideoAsset = assetSeqNumber.two.rawValue
            
            _ = startMediaBrowserFromViewController(self, usingDelegate: self)
        }
    }
    
    
    @IBAction func loadVideoAssetThree(_ sender: Any) {
        if savedPhotosAvailable(){
            
            loadingVideoAsset = assetSeqNumber.three.rawValue
          
            _ = startMediaBrowserFromViewController(self,usingDelegate: self)
        }
    }
    
   
    
    @IBAction func loadVideoAssetFour(_ sender: Any) {
        if savedPhotosAvailable(){
            
            loadingVideoAsset = assetSeqNumber.four.rawValue
            
            _ = startMediaBrowserFromViewController(self, usingDelegate: self)
        }
        
    }
    
    
    @IBAction func loadAudioAsset(_ sender: AnyObject) {
        
        let mediaPickerController = MPMediaPickerController.self(mediaTypes: .music)
        mediaPickerController.allowsPickingMultipleItems = false
        mediaPickerController.delegate = self
        mediaPickerController.prompt = "select audio"
        present(mediaPickerController, animated:  true, completion: nil)
        
    }
    //MARK: merge video
    func mergeVideo(_ mAssetsList:[AVAsset]){
        
        let mainComposition = AVMutableVideoComposition()
        let mixComposition = AVMutableComposition()
        
        let mainInstruction = AVMutableVideoCompositionInstruction()
        var allVideoInstruction = [AVMutableVideoCompositionLayerInstruction]()
        
        var startDuration:CMTime = kCMTimeZero
        var assets = mAssetsList
       
        
        //var strCaption = ""
        for i in 0..<assets.count {
            let currentAsset:AVAsset = assets[i]
            
            let currentTrack = mixComposition.addMutableTrack(withMediaType: AVMediaTypeVideo,
                                                              preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            
            do {
                try currentTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, currentAsset.duration),
                                                 of : currentAsset.tracks(withMediaType: AVMediaTypeVideo)[0],
                                                 at: startDuration)
                
                let currentInstruction:AVMutableVideoCompositionLayerInstruction = videoCompositionInstructionForTrack(track: currentTrack, asset: currentAsset)
                
                currentInstruction.setOpacityRamp(fromStartOpacity: 0.0, toEndOpacity: 1.0,
                                                  timeRange: CMTimeRangeMake(startDuration, CMTimeMake(1, 1)))
                
                if i != assets.count - 1 {
                    
                    currentInstruction.setOpacityRamp(fromStartOpacity: 1.0,
                                                     toEndOpacity: 0.0,
                                                     timeRange: CMTimeRangeMake(CMTimeSubtract(CMTimeAdd(currentAsset.duration, startDuration),
                                                         CMTimeMake(1, 1)),
                                                        CMTimeMake(2, 1)))
                }
                let transform:CGAffineTransform = currentTrack.preferredTransform
                
                if orientationFromTransform(transform: transform).isPortrait {
                    let outputSize:CGSize = CGSize(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)
                    let horizontalRatio = CGFloat(outputSize.width) / currentTrack.naturalSize.width
                    
                    let verticalRatio = CGFloat(outputSize.height) / currentTrack.naturalSize.height
                    let scaleToFitRatio = max(horizontalRatio,verticalRatio)
                    let FirstAssetScaleFactor = CGAffineTransform(scaleX:scaleToFitRatio,y:scaleToFitRatio)
                    
                    if currentAsset.g_orientation == .landscapeLeft {
                        let rotation = CGAffineTransform(rotationAngle: .pi)
                        let translateToCenter = CGAffineTransform(translationX: CGFloat(VIDEO_WIDTH),y: CGFloat(VIDEO_HEIGHT))
                        let mixedTransform = rotation.concatenating(translateToCenter)
                        
                        currentInstruction.setTransform(currentTrack.preferredTransform.concatenating(FirstAssetScaleFactor).concatenating(mixedTransform), at: kCMTimeZero)
                    } else {
                        currentInstruction.setTransform(currentTrack.preferredTransform.concatenating(FirstAssetScaleFactor), at: kCMTimeZero)
                    }
                    }
                     allVideoInstruction.append(currentInstruction)
                
                startDuration = CMTimeAdd(startDuration,currentAsset.duration)
            
            } catch {  print("ERROR_LOADING_VIDEO")  }
            
        }
        mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, startDuration)
        mainInstruction.layerInstructions = allVideoInstruction
        
        mainComposition.instructions = [mainInstruction]
        mainComposition.frameDuration = CMTimeMake(1, 30)
        mainComposition.renderSize = CGSize(width: 640, height: 480)
        
        //MARK: - audio track
        if let loadedAudioAsset = audioAsset {

            let audioTrack = mixComposition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: 0)

            do {
                try audioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, CMTimeAdd((assets.first?.duration)!, (assets.last?.duration)!)), of: loadedAudioAsset.tracks(withMediaType: AVMediaTypeAudio)[0], at: kCMTimeZero)
            } catch {  print("failed to load audio") }
        }

        
        
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        let date = dateFormatter.string(from: Date())
        
        let savePath = (documentDirectory as NSString).appendingPathComponent("mergeVideo-\(date).mp4")
        
        let url  = NSURL(fileURLWithPath: savePath)
        // deleteFileAtPath(savePath)
        
        
        guard let assetExporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else {   return  }
        
        assetExporter.outputURL = url as URL
        assetExporter.outputFileType = AVFileTypeQuickTimeMovie
        assetExporter.shouldOptimizeForNetworkUse = true
        assetExporter.videoComposition = mainComposition
        
        //MARK: perform export
        assetExporter.exportAsynchronously(){
            DispatchQueue.main.async() {
                print("run dispatchQueue")
                self.exportDidFinish(session: assetExporter)
                
            }
        }
        
    }
    
    
    
    @IBAction func mergeAssets(_ sender: AnyObject) {
        print("🔴 merge pressed")
        
        mergeVideo(assetsArray)
    }
    
    
    @IBAction func postVideoURLAction(_ sender: UIButton) {
        performSegue(withIdentifier: "postVideoURL", sender: playbackURL)
        
    }
    
    
    @IBAction func playbackAction(_ sender: Any) {
        guard let playbackURL = playbackURL else {
            return
        }
        avPlayer = AVPlayer(url: playbackURL)
        avPlayerViewController.player = self.avPlayer
        
        present(avPlayerViewController, animated:  true) { ()-> Void in
            self.avPlayerViewController.player?.play()
            }
        }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if segue.identifier == "postVideoURL" {
            let videoClientAPIViewController = segue.destination as! VideoClientAPIViewController
            videoClientAPIViewController.postVideoURL = playbackURL
            
        }
        
    }
    
    func orientationFromTransform(transform: CGAffineTransform) -> (orientation: UIImageOrientation, isPortrait: Bool){
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
    
    
    func videoCompositionInstructionForTrack(track: AVCompositionTrack,asset: AVAsset) -> AVMutableVideoCompositionLayerInstruction {
        
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        
        return instruction
        
    }
    
    
    
    func exportDidFinish(session: AVAssetExportSession) {
        print("running exportDidFinish")
        if session.status == AVAssetExportSessionStatus.completed {
            guard let outputURL = session.outputURL else {
                print("could not set outputURL")
                return
            }
            playbackURL = outputURL
            print("playbackURL = ",outputURL)
            assetCheck()
           
           
            
            //MARK: let library = ALAssetsLibrary()
            PHPhotoLibrary.shared().performChanges({
                let options = PHAssetResourceCreationOptions()
                options.shouldMoveFile = false
                
                //MARK: Create video file
                
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .video, fileURL:  outputURL, options: options)
                print("save to PhotoLib")
            }, completionHandler: { (success, error) in
                if !success {
                    print("Could not save video to photo library: ",error?.localizedDescription ?? "error code not found: SaveToPhotoLibrary")
                    return
                }
                print("Ⓜ️save video to PhotosAlbum")
                
            }
            )}
        
        activityMonitor.stopAnimating()
        resetAssets()

    }
    
    func resetAssets(){
        print("reset all assets and removeall from array")
        firstVideoAsset = nil
        secondVideoAsset = nil
        thirdVideoAsset = nil
        fourthVideoAsset = nil
        assetsLoaded = 0
        assetsArray.removeAll()
        
        audioAsset = nil
    }
    func setPlayBackURL(_ videoAsset:AVAsset?)-> URL{
        
        let playbackItem = videoAsset?.value(forKey: "URL")
        
        return playbackItem as! URL
        
    }
    
    func assetCheck(){
        
        if assetsArray.count > 0 {
         
            videoPlaybackOutlet.isEnabled = true
            videoPostOutlet.isEnabled = true
        } else {
            videoPlaybackOutlet.isEnabled = false
            videoPostOutlet.isEnabled = false
        }
        
        if assetsArray.count >= 2 {
            mergeAssetsOutlet.isEnabled = true
        } else {
            mergeAssetsOutlet.isEnabled = false
                
            }
        }
}

extension AVAsset {
    var g_size: CGSize {
    return tracks(withMediaType: AVMediaTypeVideo).first?.naturalSize ?? .zero
    }
    var g_orientation: UIInterfaceOrientation {
        guard let transform = tracks(withMediaType: AVMediaTypeVideo).first?.preferredTransform else {
            return .portrait
            }
        switch (transform.tx,transform.ty) {
        case (0,0):
            return .landscapeRight
        case (g_size.width, g_size.height):
            return .landscapeLeft
        case (0, g_size.width):
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
}

extension VideoClientMergeVC: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        picker.dismiss(animated: true, completion: nil)
        
        if mediaType == kUTTypeMovie {
           let avAsset = AVAsset(url:info[UIImagePickerControllerMediaURL] as! URL)
            
//
//           playbackURL = URL(fileURLWithPath: [UIImagePickerControllerMediaURL][0])
//        print("playback",playbackURL!)
            
            var message = "done"
            
            switch loadingVideoAsset {
            case 1:
                message = "Video one loaded"
                firstVideoAsset = avAsset
                guard let firstVideoAsset = firstVideoAsset else {
                    return
                }
                assetsArray.append(firstVideoAsset)
                print("firstVideoAsset \(firstVideoAsset)\n")
                assetCheck()
                //set playback url for sigle file upload
                playbackURL = setPlayBackURL(firstVideoAsset)
            case 2:
                message = "Video two loaded"
                secondVideoAsset = avAsset
                guard let secondVideoAsset = secondVideoAsset else {
                    return
                }
                assetsArray.append(secondVideoAsset)
                 print("secondVideoAsset \(secondVideoAsset)\n")
                assetCheck()
                //set playback url for sigle file upload
                playbackURL = setPlayBackURL(secondVideoAsset)
            case 3:
                message = "Video three loaded"
                thirdVideoAsset = avAsset
                guard let thirdVideoAsset = thirdVideoAsset else {
                    return
                }
                assetsArray.append(thirdVideoAsset)
                 print("thirdVideoAsset \(thirdVideoAsset)\n")
                assetCheck()
                //set playback url for sigle file upload
                playbackURL = setPlayBackURL(thirdVideoAsset)
            case 4:
                message = "Video four loaded"
                fourthVideoAsset = avAsset
                guard let fourthVideoAsset = fourthVideoAsset else {
                    return
                }
                assetsArray.append(fourthVideoAsset)
                 print("fourthVideoAsset \(fourthVideoAsset)/n")
                assetCheck()
                //set playback url for sigle file upload
                playbackURL = setPlayBackURL(fourthVideoAsset)

            default:
                message = "error"

            }
            picker.dismiss(animated: true, completion: nil)
            
            let alert = UIAlertController(title: "Asset Loaded", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
}

extension VideoClientMergeVC: UINavigationControllerDelegate {
    
}

extension VideoClientMergeVC: MPMediaPickerControllerDelegate {
    
    @objc(mediaPicker:didPickMediaItems:) func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection){
        let selectedSongs = mediaItemCollection.items
        
        if selectedSongs.count > 0 {
            let song = selectedSongs[0]
            
            if let url = song.value(forProperty: MPMediaItemPropertyAssetURL) as? URL{
                audioAsset = (AVAsset(url: url ))
                dismiss(animated: true, completion: nil)
                let alert = UIAlertController(title: "Asset loaded", message: "audio loaded", preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
            }
            else {
                dismiss(animated: true, completion: nil)
                let alert = UIAlertController(title: "Asset not available", message: "Audio not loaded", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "ok", style: .cancel, handler: nil))
                present(alert, animated: true,completion:  nil)
            }
            
            
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        dismiss(animated: true, completion: nil)
    }
    
}

