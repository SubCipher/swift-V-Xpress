//
//  VideoClientRecordViewController.swift
//  VideoClient
//
//  Created by Krishna Picart on 10/18/17.
//  Copyright © 2017 StepwiseDesigns. All rights reserved.
//

import UIKit
import AVFoundation
import Foundation
import MobileCoreServices


/* Documentation and implementation references:
 
 https://developer.apple.com/library/content/samplecode/AVCam/Introduction/Intro.html#//apple_ref/doc/uid/DTS40010112-Intro-DontLinkElementID_2
 
 https://developer.apple.com/library/content/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/00_Introduction.html#//apple_ref/doc/uid/TP40010188-CH1-SW3
 
 Reference Docs and links:
 https://developer.apple.com/library/content/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/03_Editing.html
 https://www.raywenderlich.com/94404/play-record-merge-videos-ios-swift
 */

class VideoClientRecordViewController: UIViewController  {
    
    
    @IBOutlet weak var recordButtonOutlet: UIButton!
    
    //MARK:- RecordButton Action
    @IBAction func recordButtonAction(_ sender: UIButton) {
        
        _ = startCameraFromViewController(viewController: self, withDelegate: self)

    }
    
    @objc func video(videoPath: NSString, didFinishSavingWithError error: NSError?, contextInfo info: AnyObject) {
        var title = "Success"
        var message = "Video was saved"
        if let _ = error {
            title = "Error"
            message = "Video failed to save"
        }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    
    var movieOutput00 = AVCaptureMovieFileOutput()
    func startCameraFromViewController(viewController: UIViewController, withDelegate delegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate) ->Bool {
        if UIImagePickerController.isSourceTypeAvailable(.camera) == false {
            return false
        }
        
        let cameraController = UIImagePickerController()
        cameraController.sourceType = .camera
        cameraController.mediaTypes = [kUTTypeMovie as NSString as String]
        cameraController.allowsEditing = false
        cameraController.delegate = delegate
        
        present(cameraController, animated: true,completion:  nil)
        
        return true
    }
    
    var path = ""
}

extension VideoClientRecordViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let mediaType =  info[UIImagePickerControllerMediaType] as! NSString
        dismiss(animated: true, completion: nil)
        
        if mediaType == kUTTypeMovie {
            guard let path = (info[UIImagePickerControllerMediaURL] as! NSURL).path else { return }
            
            if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path) {
                
                UISaveVideoAtPathToSavedPhotosAlbum(path, self, #selector(VideoClientRecordViewController.video(videoPath:didFinishSavingWithError:contextInfo:)), nil)
            }
        }
    }
}


extension VideoClientRecordViewController: UINavigationControllerDelegate {
    
}
