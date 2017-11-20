//
//  VideoClentMergeExt.swift
//  VideoClient
//
//  Created by knax on 11/19/17.
//  Copyright © 2017 StepwiseDesigns. All rights reserved.
//

//import Foundation
import UIKit
import AVFoundation
import AVKit
import MobileCoreServices
import AssetsLibrary
import Photos

import MediaPlayer
import CoreMedia


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
            completionHandlerForThumbnailGen(false, error.description)
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
            //MARK: - add asset to array
            
                
            
            let videoCompWithTagID = video(videoAsset: avAsset, tagID: tagID)
            
            if let foundIndex = videoArray.index(where: { $0.tagID == tagID }) {
                videoArray.remove(at: foundIndex)
                
            }
            videoArray.append(videoCompWithTagID)
            assetCheck()
            print("\n\n")
            print("array elements",videoArray.count)
            print("\n\n")
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
                    print("thumbnail gen did run with outcome => ",success)
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


