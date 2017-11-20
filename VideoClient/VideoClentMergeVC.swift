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
    
    
    //MARK: - Properties
    var videoAsset: AVAsset?
    
    var audioAsset: AVAsset?
    var loadingVideoAsset = 0
    var assetDidLoad = false
    //var assetsLoaded = 0
    
    var playbackURL: URL?
    //var assetsArray = [AVAsset]()
    
    var audioTrackDidLoad = false
    let avPlayerViewController = AVPlayerViewController()
    var avPlayer: AVPlayer?
    
    
    
    struct video {
        
        var videoAsset: AVAsset
        var tagID: Int
        
        init(videoAsset:AVAsset, tagID: Int ) {
            
            self.videoAsset = videoAsset
            self.tagID = tagID
        }
    }
    
    var videoArray = [video]()
    var thumbnailOutletImage: UIImage?
    
    var VIDEO_WIDTH = 375.0
    var VIDEO_HEIGHT = 667.0
    
   
    //MARK: - IBOutlets
    @IBOutlet var activityMonitor: UIActivityIndicatorView!
    
    @IBOutlet weak var videoPlaybackOutlet: UIButton!
    
    @IBOutlet weak var mergeAssetsOutlet: UIButton!
    
    @IBOutlet weak var videoPostOutlet: UIButton!
    
    @IBOutlet weak var addVideoOutlet1: UIButton!
    
    @IBOutlet weak var addVideoOutlet2: UIButton!
    
    @IBOutlet weak var addVideoOutlet3: UIButton!
    @IBOutlet weak var addVideoOutlet4: UIButton!
    
    //MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        videoPlaybackOutlet.isEnabled = false
        videoPostOutlet.isEnabled = false
        mergeAssetsOutlet.isEnabled = false
        addNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        assetCheck()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if segue.identifier == "postVideoURL" {
            let videoClientAPIViewController = segue.destination as! VideoClientAPIViewController
            videoClientAPIViewController.postVideoURL = playbackURL
        }
    }
    
    //Mark: - Add notifications to listen for thumbnail image gen
    func addNotifications(){
        
        NotificationCenter.default.addObserver(forName: VIDEO_THUMBNAIL1, object: nil, queue: nil) { notification in
            DispatchQueue.main.async {
                
                self.addVideoOutlet1.setBackgroundImage(#imageLiteral(resourceName: "vc_videoButtonFrame"), for: .normal)
                self.addVideoOutlet1.setImage(self.thumbnailOutletImage, for: .normal)
            }
        }
        
        NotificationCenter.default.addObserver(forName: VIDEO_THUMBNAIL2, object: nil, queue: nil) { notification in
            DispatchQueue.main.async {
                
                self.addVideoOutlet2.setBackgroundImage(#imageLiteral(resourceName: "vc_videoButtonFrame"), for: .normal)
                self.addVideoOutlet2.setImage(self.thumbnailOutletImage, for: .normal)
            }
        }
        
        NotificationCenter.default.addObserver(forName: VIDEO_THUMBNAIL3, object: nil, queue: nil) { notification in
            DispatchQueue.main.async {
                
                self.addVideoOutlet3.setBackgroundImage(#imageLiteral(resourceName: "vc_videoButtonFrame"), for: .normal)
                self.addVideoOutlet3.setImage(self.thumbnailOutletImage, for: .normal)
            }
        }
        
        
        NotificationCenter.default.addObserver(forName: VIDEO_THUMBNAIL4, object: nil, queue: nil) { notification in
            DispatchQueue.main.async {
                
                self.addVideoOutlet4.setBackgroundImage(#imageLiteral(resourceName: "vc_videoButtonFrame"), for: .normal)
                self.addVideoOutlet4.setImage(self.thumbnailOutletImage, for: .normal)
            }
        }
        
    }
    
    func resetOutletImages(){
        self.addVideoOutlet1.setBackgroundImage(#imageLiteral(resourceName: "vc_addVideoButton1"), for: .normal)
        self.addVideoOutlet1.setImage(nil, for: .normal)
        
        self.addVideoOutlet2.setBackgroundImage(#imageLiteral(resourceName: "vc_addVideoButton2"), for: .normal)
        self.addVideoOutlet2.setImage(nil, for: .normal)
        
        self.addVideoOutlet3.setBackgroundImage(#imageLiteral(resourceName: "vc_addVideoButton3"), for: .normal)
        self.addVideoOutlet3.setImage(nil, for: .normal)
        
        self.addVideoOutlet4.setBackgroundImage(#imageLiteral(resourceName: "vc_addVideoButton4"), for: .normal)
        self.addVideoOutlet4.setImage(nil, for: .normal)
    }
    
    
    func getVideo() {
        
        PHPhotoLibrary.requestAuthorization({(status: PHAuthorizationStatus)->Void in
            if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.authorized {
                
                self.imagePickerFromVC(self, usingDelegate: self)
                
            } else {
                let alert = UIAlertController(title:"Unauthorized", message:"user authorized required for action", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                self.present(alert,animated: true,completion: nil)
            }
            }
        )}
    
    func imagePickerFromVC(_ viewController: UIViewController, usingDelegate delegate : UINavigationControllerDelegate & UIImagePickerControllerDelegate) {
        
        if savedPhotosAvailable() {
            
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .savedPhotosAlbum
        imagePicker.mediaTypes = [kUTTypeMovie as String]
        imagePicker.allowsEditing = true
        imagePicker.delegate = delegate
        
        present(imagePicker, animated: true, completion: { })
        }
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
    
    //MARK: - merge video clips
    func mergeVideo(_ videoList:[video]){
        activityMonitor.startAnimating()
        
        let mainComposition = AVMutableVideoComposition()
        let mixComposition = AVMutableComposition()
        
        let mainInstruction = AVMutableVideoCompositionInstruction()
        var allVideoInstruction = [AVMutableVideoCompositionLayerInstruction]()
        
        var startDuration = kCMTimeZero
       
        var videoSize: CGSize = CGSize(width: 0.0, height: 0.0)
       
        var totalTime: CMTime = CMTimeMake(0, 0)
        var time = 0.0
        
        //Mark: - Create tracks from array
         for videoAsset in videoList {
            
            guard let videoTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video,
                                                                    preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
                else {  return }
           
            do {

                try videoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, videoAsset.videoAsset.duration),
                                               of: videoAsset.videoAsset.tracks(withMediaType: AVMediaType.video)[0],
                                               at: startDuration)
                videoSize = videoTrack.naturalSize
                    
                let currentInstruction = videoCompositionInstructionForTrack(track: videoTrack, asset: videoAsset.videoAsset)
                
               
                    currentInstruction.setOpacityRamp(fromStartOpacity: 1.0, toEndOpacity: 0.0,
                                                      timeRange: CMTimeRangeMake(CMTimeSubtract(CMTimeAdd(videoAsset.videoAsset.duration, startDuration),
                                                                                                CMTimeMake(1, 1)), CMTimeMake(2, 1)))
                
                let transform = videoTrack.preferredTransform
               
                if orientationFromTransform(transform: transform).isPortrait {
                    let outputSize:CGSize = CGSize(width: videoSize.width, height: videoSize.height)
                    let horizontalRatio = CGFloat(outputSize.width) / videoTrack.naturalSize.width
                    
                    let verticalRatio = CGFloat(outputSize.height) / videoTrack.naturalSize.height
                    let scaleToFitRatio = max(horizontalRatio,verticalRatio)
                    let FirstAssetScaleFactor = CGAffineTransform(scaleX: scaleToFitRatio,y:scaleToFitRatio)
                    
                    if videoAsset.videoAsset.g_orientation == .landscapeLeft {
                        let rotation = CGAffineTransform(rotationAngle: .pi)
                        
                        let translateToCenter = CGAffineTransform(translationX: CGFloat(VIDEO_WIDTH),y: CGFloat(VIDEO_HEIGHT))
                        let mixedTransform = rotation.concatenating(translateToCenter)
                    currentInstruction.setTransform(videoTrack.preferredTransform.concatenating(FirstAssetScaleFactor).concatenating(mixedTransform), at: kCMTimeZero)
                        
                    } else {
                        currentInstruction.setTransform(videoTrack.preferredTransform.concatenating(FirstAssetScaleFactor), at: kCMTimeZero)
                    }
                }
               
                startDuration = CMTimeAdd(startDuration,videoAsset.videoAsset.duration)
                time += videoAsset.videoAsset.duration.seconds
                totalTime = CMTime(seconds: time, preferredTimescale: 1)
                
                 allVideoInstruction.append(currentInstruction)
                print("totalTime",totalTime)
                
            } catch {  print("ERROR_LOADING_VIDEO")  }
            
        }
        mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, startDuration)
        mainInstruction.layerInstructions = allVideoInstruction
        
        mainComposition.instructions = [mainInstruction]
        mainComposition.frameDuration = CMTimeMake(1, 30)
        mainComposition.renderSize = CGSize(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)
        
        //MARK: - audio track
        guard let loadedAudioAsset = audioAsset else  {
            
            self.activityMonitor.stopAnimating()
            print("no audio track selected")
            let alert =  UIAlertController(title: "No Audio", message: "Please Select Audio Track Then Merge", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil ))
            
            present(alert, animated: true, completion: nil)
            return
            
        }
            
            let audioTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: 0)
            //need to extend audio
            do {
               
                if videoArray.count < 2 || videoArray.count == 2 {
                    print("print array count < 2",videoArray.count)
                    try audioTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, CMTimeAdd((videoArray.first?.videoAsset.duration)!, (videoArray.last?.videoAsset.duration)!)), of: loadedAudioAsset.tracks(withMediaType: AVMediaType.audio)[0], at: kCMTimeZero)
                }
                if videoArray.count == 3 {
                    
                    try audioTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, CMTimeAdd((CMTimeAdd((videoArray.first?.videoAsset.duration)!, (videoArray[1].videoAsset.duration))), (videoArray.last?.videoAsset.duration)!)), of: loadedAudioAsset.tracks(withMediaType: AVMediaType.audio)[0], at: kCMTimeZero)
                }
                
                if videoArray.count  == 4 {
                   
                    try audioTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, CMTimeAdd((CMTimeAdd((videoArray.first?.videoAsset.duration)!, (videoArray[1].videoAsset.duration))), (CMTimeAdd(( videoArray[2]).videoAsset.duration, (videoArray[3].videoAsset.duration))))), of: loadedAudioAsset.tracks(withMediaType: AVMediaType.audio)[0], at: kCMTimeZero)
                }
            }
            catch {
                
                activityMonitor.stopAnimating()
                let alert = UIAlertController.init(title: "Audio", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                
                self.present(alert, animated: true,completion: nil)
        }

        
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        let date = dateFormatter.string(from: Date())
        let savePath = (documentDirectory as NSString).appendingPathComponent("mergeVideo-\(date).mp4")
        
        let url  = NSURL(fileURLWithPath: savePath)
        // deleteFileAtPath(savePath)
        
        
        guard let assetExporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else {  return  }
        
        assetExporter.outputURL = url as URL
        assetExporter.outputFileType = AVFileType.mov
        assetExporter.shouldOptimizeForNetworkUse = true
        assetExporter.videoComposition = mainComposition
        
        //MARK:- perform export
        assetExporter.exportAsynchronously(){
            DispatchQueue.main.async() {
                print("run dispatchQueue")
                self.exportDidFinish(session: assetExporter)
            }
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
        let assetTrack = asset.tracks(withMediaType: AVMediaType.video)[0]
        
        let transform = assetTrack.preferredTransform
        let assetInfo = orientationFromTransform(transform: transform)
        
        var scaleToFitRatio = UIScreen.main.bounds.width / assetTrack.naturalSize.width
        
        if assetInfo.isPortrait {
            
            scaleToFitRatio = UIScreen.main.bounds.width / assetTrack.naturalSize.height
            let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)
            instruction.setTransform(assetTrack.preferredTransform.concatenating(scaleFactor),at: kCMTimeZero)
            
        } else {
            
            let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)
            var concat = assetTrack.preferredTransform.concatenating(scaleFactor).concatenating(CGAffineTransform(translationX: 0, y: UIScreen.main.bounds.width / 2))
            
            if assetInfo.orientation == .down {
                
                let fixUpsideDown = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
                
                let windowsBounds = UIScreen.main.bounds
                let yFix = assetTrack.naturalSize.height + windowsBounds.height
                let centerFix = CGAffineTransform(translationX: assetTrack.naturalSize.width, y: yFix)
                concat = fixUpsideDown.concatenating(centerFix).concatenating(scaleFactor)
                
            }
            instruction.setTransform(concat, at: kCMTimeZero)
        }
        return instruction
    }
    
    func exportDidFinish(session: AVAssetExportSession) {
      
        if session.status == AVAssetExportSessionStatus.completed {
            guard let outputURL = session.outputURL else {
                return
            }
            playbackURL = outputURL
            assetCheck()
            
            PHPhotoLibrary.shared().performChanges({
                let options = PHAssetResourceCreationOptions()
                options.shouldMoveFile = false
                
                //MARK:- Add video to Photos lib
                
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .video, fileURL:  outputURL, options: options)
            }, completionHandler: { (success, error) in
                if !success {
                    
                    let alert = UIAlertController(title: "PhotoLib Fail", message: error?.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)

                    return
                }
                DispatchQueue.main.async {
                     self.videoPlaybackOutlet.isEnabled = true
                }
                let alert = UIAlertController(title: "Merge", message: "video merge complete", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            )}
        
        activityMonitor.stopAnimating()
        resetAssets()
    }
    
    
    func setPlayBackURL(_ videoAsset:AVAsset?)-> URL{
        
        let playbackItem = videoAsset?.value(forKey: "URL")
        return playbackItem as! URL
    }
    
    //check requirements before enabling IBActions
    func assetCheck(){
        
         if videoArray.count > 0 {
            videoPostOutlet.isEnabled = true
            
         } else {
            videoPostOutlet.isEnabled = false
        }
        
        if videoArray.count >= 2 && audioTrackDidLoad == true {
            mergeAssetsOutlet.isEnabled = true
        } else {
            mergeAssetsOutlet.isEnabled = false
        }
    }
    
    func resetAssets(){
        
        print("reset all assets and removeall from array")
        videoAsset = nil
        videoArray.removeAll()
        mergeAssetsOutlet.isEnabled = false
        audioAsset = nil
        audioTrackDidLoad = false
        resetOutletImages()
    }
    
    //MARK:- IBAction
    
    let thumbnailDispatch = DispatchQueue(label: "com.stepwisedesigns.thumbnailgen", qos: .default)
    let additionalTime: DispatchTimeInterval = .seconds(10)
    
    @IBAction func loadVideoAssetOne(_ sender: AnyObject) {
        
            getVideo()
            tagID = sender.tag
    }
    
    
    @IBAction func loadVideoAssetTwo(_ sender: AnyObject) {
        
        getVideo()
        tagID = sender.tag
    }
    
    @IBAction func loadVideoAssetThree(_ sender: AnyObject) {
        
        getVideo()
        tagID = sender.tag
    }
    
    @IBAction func loadVideoAssetFour(_ sender: AnyObject) {
        
        getVideo()
        tagID = sender.tag
    }
    
    
    @IBAction func loadAudioAssetButton(_ sender: AnyObject) {
        
       loadAudioAsset()
    }
    
  
    func loadAudioAsset(){
        
        let mediaPickerController = MPMediaPickerController.self(mediaTypes: .music)
        mediaPickerController.allowsPickingMultipleItems = false
        mediaPickerController.delegate = self
        mediaPickerController.prompt = "select audio"
        present(mediaPickerController, animated:  true, completion: nil)
        audioTrackDidLoad = true
    }
    
    
    @IBAction func mergeAssets(_ sender: AnyObject) {
       
        mergeVideo(videoArray)
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
