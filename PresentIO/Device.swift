//
//  Device.swift
//  PresentIO
//
//  Created by Gonçalo Borrêga on 29/01/16.
//  Copyright © 2016 Borrega. All rights reserved.
//

import Foundation
import AVKit
import AVFoundation

class Device: NSObject, NSCoding {
    
    var name: String
    var uid: String
    var portraitRect: NSRect
    var landscapeRect: NSRect
    
    struct PropertyKey {
        static let nameKey = "name"
        static let uidKey = "uid"
        static let portraitRectKey = "p_rect"
        static let landscapeRectKey = "l_rect"
    }
    
    static let ArchivePath = NSHomeDirectory().appendingFormat("/devices")

    convenience init?(fromDevice device: AVCaptureDevice) {
        self.init(name: device.localizedName, uid: device.uniqueID, portraitRect:NSRect(), landscapeRect:NSRect())
    }
    init(name: String, uid: String, portraitRect:NSRect, landscapeRect:NSRect) {
        self.name = name
        self.uid = uid
        self.portraitRect = portraitRect
        self.landscapeRect = landscapeRect
        
        super.init()
    }
    
    func hasPreviousLocation(forOrientation: DeviceOrientation) -> Bool {
        if forOrientation == DeviceOrientation.Portrait {
            return portraitRect.origin.x != 0 || portraitRect.origin.y != 0
                || portraitRect.size.height != 0 || portraitRect.size.width != 0
        } else {
            return landscapeRect.origin.x != 0 || landscapeRect.origin.y != 0
                || landscapeRect.size.height != 0 || landscapeRect.size.width != 0
        }
    }
    func savedSettingForOrientation(forOrientation: DeviceOrientation) -> NSRect {
        if forOrientation == DeviceOrientation.Portrait {
            print("Using Portrait settings for \(name): \(portraitRect)")
            return portraitRect
        } else {
            print("Using Landscape settings for \(name): \(portraitRect)")
            return landscapeRect
        }
    }

    
    //MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: PropertyKey.nameKey)
        aCoder.encode(uid, forKey: PropertyKey.uidKey)
        
        aCoder.encode(NSStringFromRect(portraitRect), forKey: PropertyKey.portraitRectKey)
        aCoder.encode(NSStringFromRect(landscapeRect), forKey: PropertyKey.landscapeRectKey)
        
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObject(forKey: PropertyKey.nameKey) as! String
        let uid = aDecoder.decodeObject(forKey: PropertyKey.uidKey) as! String
        let pRect = NSRectFromString(aDecoder.decodeObject(forKey: PropertyKey.portraitRectKey) as! String)
        let lRect = NSRectFromString(aDecoder.decodeObject(forKey: PropertyKey.landscapeRectKey) as! String)
        
        // Must call designated initializer.
        self.init(name: name, uid: uid, portraitRect:pRect, landscapeRect:lRect)
    }
    
}
