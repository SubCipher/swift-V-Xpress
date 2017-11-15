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
    var assetsLoaded = 0
    
    var playbackURL: URL?
    var assetsArray = [AVAsset]()
    
    
    let avPlayerViewController = AVPlayerViewController()
    var avPlayer: AVPlayer?
    
    var videoArray = [VideoClientDataModel.video]()
    var recordedVideo:  VideoClientDataModel.video?
    
    var thumbnailOutletImage: UIImage?
    var ibActionTagArray = [Int]()
    
    
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
        
        
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) == false {
            let alert = UIAlertController(title: "ERROR", message: "Source not found", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            present(alert,animated: true,completion: nil)
        }
        
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .savedPhotosAlbum
        imagePicker.mediaTypes = [kUTTypeMovie as String]
        imagePicker.allowsEditing = true
        imagePicker.delegate = delegate
        
        present(imagePicker, animated: true, completion: { })
        
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
    
    
    
    //MARK: - merge video
    func mergeVideo(_ mAssetsList:[AVAsset]){
        
        let mainComposition = AVMutableVideoComposition()
        let mixComposition = AVMutableComposition()
        
        let mainInstruction = AVMutableVideoCompositionInstruction()
        var allVideoInstruction = [AVMutableVideoCompositionLayerInstruction]()
        
        var startDuration:CMTime = kCMTimeZero
        //var assets = mAssetsList
        
        
        //var strCaption = ""
        for i in 0..<assetsArray.count {
            let currentAsset:AVAsset = assetsArray[i]
            
            guard let currentTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video,
                                                                    preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
                else { return  }
            
            do {
                try currentTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, currentAsset.duration),
                                                 of : currentAsset.tracks(withMediaType: AVMediaType.video)[0],
                                                 at: startDuration)
                
                let currentInstruction = videoCompositionInstructionForTrack(track: currentTrack, asset: currentAsset)
                
                currentInstruction.setOpacityRamp(fromStartOpacity: 0.0, toEndOpacity: 1.0,
                                                  timeRange: CMTimeRangeMake(startDuration, CMTimeMake(1, 1)))
                
                if i != assetsArray.count - 1 {
                    
                    currentInstruction.setOpacityRamp(fromStartOpacity: 1.0,
                                                      toEndOpacity: 0.0,
                                                      timeRange: CMTimeRangeMake(CMTimeSubtract(CMTimeAdd(currentAsset.duration, startDuration),
                                                                                                CMTimeMake(1, 1)),
                                                                                 CMTimeMake(2, 1)))
                }
                let transform = currentTrack.preferredTransform
                
                if orientationFromTransform(transform: transform).isPortrait {
                    let outputSize:CGSize = CGSize(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)
                    let horizontalRatio = CGFloat(outputSize.width) / currentTrack.naturalSize.width
                    
                    let verticalRatio = CGFloat(outputSize.height) / currentTrack.naturalSize.height
                    let scaleToFitRatio = max(horizontalRatio,verticalRatio)
                    let FirstAssetScaleFactor = CGAffineTransform(scaleX: scaleToFitRatio,y:scaleToFitRatio)
                    
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
        mainComposition.renderSize = CGSize(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)
        
        //MARK: - audio track
        if let loadedAudioAsset = audioAsset {
            
            let audioTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: 0)
            
            do {
                try audioTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, CMTimeAdd((assetsArray.first?.duration)!, (assetsArray.last?.duration)!)), of: loadedAudioAsset.tracks(withMediaType: AVMediaType.audio)[0], at: kCMTimeZero)
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
        
        
        guard let assetExporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else {  return  }
        
        assetExporter.outputURL = url as URL
        assetExporter.outputFileType = AVFileType.mov
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
            //var concat = CGAffineTransform.concatenating(scaleFactor)
            
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
        print("running exportDidFinish")
        if session.status == AVAssetExportSessionStatus.completed {
            
            guard let outputURL = session.outputURL else {
                print("could not set outputURL")
                return
            }
            playbackURL = outputURL
            print("playbackURL = ",outputURL)
            assetCheck()
            
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
    
    func resetAssets(){
        print("reset all assets and removeall from array")
        videoAsset = nil
        assetsLoaded = 0
        assetsArray.removeAll()
        audioAsset = nil
        resetOutletImages()
        
        
    }
    
    //MARK:- IBAction
    
    let thumbnailDispatch = DispatchQueue(label: "com.stepwisedesigns.thumbnailgen", qos: .default)
    let additionalTime: DispatchTimeInterval = .seconds(10)
    
    @IBAction func loadVideoAssetOne(_ sender: AnyObject) {
        
        if savedPhotosAvailable(){
            getVideo()
            tagID = sender.tag
            
            
        }
    }
    
    
    @IBAction func loadVideoAssetTwo(_ sender: AnyObject) {
        if savedPhotosAvailable(){
            getVideo()
            tagID = sender.tag
            
        }
    }
    
    
    
    @IBAction func loadVideoAssetThree(_ sender: AnyObject) {
        if savedPhotosAvailable(){
            getVideo()
            tagID = sender.tag
            
        }
    }
    
    
    @IBAction func loadVideoAssetFour(_ sender: AnyObject) {
        if savedPhotosAvailable(){
            getVideo()
            tagID = sender.tag
            
        }
    }
    
    
    @IBAction func loadAudioAsset(_ sender: AnyObject) {
        
        let mediaPickerController = MPMediaPickerController.self(mediaTypes: .music)
        mediaPickerController.allowsPickingMultipleItems = false
        mediaPickerController.delegate = self
        mediaPickerController.prompt = "select audio"
        present(mediaPickerController, animated:  true, completion: nil)
        
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
}
//MARK: - Extensions
extension AVAsset {
    var g_size: CGSize {
        return tracks(withMediaType: AVMediaType.video).first?.naturalSize ?? .zero
    }
    var g_orientation: UIInterfaceOrientation {
        guard let transform = tracks(withMediaType: AVMediaType.video).first?.preferredTransform else {
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
    
    
    // func generateThumbnailForVideoAtURL(filePathLocal: URL, completionForThumnailGen: @escaping (_ success: Bool, _ error: String)-> Void) -> UIImage? {
    
    func generateThumbnailForVideoAtURL(filePathLocal: URL, completionHandlerForThumbnailGen: @escaping (_ success: Bool,_ error: String)->Void) -> UIImage? {
        
        let asset = AVURLAsset(url: filePathLocal)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 122.0, height: 85.0)
        
        let timestamp = CMTime(seconds: 1, preferredTimescale: 60)
        
        do {
            let thumbnailGen = try generator.copyCGImage(at: timestamp, actualTime: nil)
            completionHandlerForThumbnailGen(true, "error")
            
            return UIImage(cgImage: thumbnailGen)
        }
        catch let error as NSError
        {
            print("Image generation failed with error \(error)")
            return nil
        }
        
    }
    func updateOutletImage(_ tagID:Int){
      
        
        switch tagID {
        case 1:
            NotificationCenter.default.post(name: VIDEO_THUMBNAIL1, object: self)
        case 2:
            NotificationCenter.default.post(name: VIDEO_THUMBNAIL2, object: self)
        case 3:
             NotificationCenter.default.post(name: VIDEO_THUMBNAIL3, object: self)
        case 4:
             NotificationCenter.default.post(name: VIDEO_THUMBNAIL4, object: self)
            
        default:
             NotificationCenter.default.post(name: VIDEO_THUMBNAIL1, object: self)
        }
        
        
        
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        
        picker.dismiss(animated: true, completion: nil)
        var message = "done"
        
        //send notification from here
        
        if mediaType == kUTTypeMovie {
            let avAsset = AVAsset(url:info[UIImagePickerControllerMediaURL] as! URL)
            
            message = "Video loaded"
            videoAsset = avAsset
            guard let videoAsset = videoAsset else {
                return
            }
            assetsArray.append(videoAsset)
            print("videoAsset \(videoAsset)\n")
            assetCheck()
            
            //set playback url for sigle file upload
            playbackURL = setPlayBackURL(videoAsset)
            guard let playbackURL = playbackURL else {
                return
            }
            
            //picker.dismiss(animated: true, completion: nil)
            
            let alert = UIAlertController(title: "Asset Loaded", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
            self.present(alert, animated: true, completion: {self.thumbnailOutletImage = self.generateThumbnailForVideoAtURL(filePathLocal: playbackURL, completionHandlerForThumbnailGen: { (success, error) in
                
                if (success == true) {
                    print("did run")
                    self.updateOutletImage(tagID)
                }
                
            })
                
        })
            
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

