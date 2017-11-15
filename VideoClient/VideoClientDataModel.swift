//
//  VideoClientDataModel.swift
//  VideoClient
//
//  Created by Krishna Picart on 10/10/17.
//  Copyright © 2017 StepwiseDesigns. All rights reserved.
//


import Foundation
import UIKit
import AVFoundation


var tagID = 0
let VIDEO_THUMBNAIL1 = Notification.Name("VideoThumbnail1")
let VIDEO_THUMBNAIL2 = Notification.Name("VideoThumbnail2")
let VIDEO_THUMBNAIL3 = Notification.Name("VideoThumbnail3")
let VIDEO_THUMBNAIL4 = Notification.Name("VideoThumbnail4")

class VideoClientDataModel: NSObject {
    
    struct video {
        
        
        var videoThumbnail: UIImage
        var videoAsset: AVAsset
        
        init(videoThumbnail: UIImage, videoAsset:AVAsset ) {
           
            self.videoThumbnail = videoThumbnail
            self.videoAsset = videoAsset
        }
    }
    
    enum httpMethod {
        case POST
        case GET
    }
    
    struct urlRequestMethodWithType {
        var httpMethodType: httpMethod
        var urlMethodAsString: String
        var typeSwitch = 0
        
        init(_ urlMethodAsString: String,_ httpMethodType: httpMethod ){
            
            self.httpMethodType = httpMethodType
            self.urlMethodAsString = urlMethodAsString
        }
    }
}
