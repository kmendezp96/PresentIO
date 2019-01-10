//
//  AppDelegate.swift
//  PresentIO
//
//  Created by Gonçalo Borrêga on 27/02/15.
//  Copyright (c) 2015 Borrega. All rights reserved.
//

import Cocoa

import AVFoundation
import AVKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    
    @IBOutlet var window: NSWindow!
    
    @IBOutlet weak var menuItemDevice: NSMenuItem!
    @IBOutlet weak var menuDevice: NSMenu!
    @IBOutlet weak var menuItemFit: NSMenuItem!
    
    var session : AVCaptureSession = AVCaptureSession()

    let notifications = NotificationManager()
    var devices : [AVCaptureDevice] = []
    var deviceSessions : [AVCaptureDevice: Skin] = [:]
    
    var deviceSettings : [Device] = []
    var deviceSettingsLoaded = false
    
    var selectedDevice : Skin? {
        didSet {
            updateMenu()
        }
    }

    func applicationDidFinishLaunching(aNotification: NSNotification) {

        self.selectedDevice = nil
        
        // Opt-in for getting visibility on connected screen capture devices (iphone/ipad)
        DeviceUtils.registerForScreenCaptureDevices()
        
        self.loadObservers()
        
        // Required to receive the AVCaptureDeviceWasConnectedNotification
        //self.session.startRunning()
        
        self.refreshDevices()
        
        
       
    }
    
    func loadDeviceSettings() {
        let loaded = NSKeyedUnarchiver.unarchiveObject(withFile: Device.ArchivePath) as? [Device]
        if loaded != nil {
            self.deviceSettings = loaded!
        } else {
            self.devices = []
        }
        deviceSettingsLoaded = true
    }
    
    
    func saveDeviceSettings() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(self.deviceSettings, toFile: Device.ArchivePath)
        if !isSuccessfulSave {
            NSLog("Failed to save device settings.")
        }
        deviceSettingsLoaded = true
    }
    func findDeviceSettings(device: AVCaptureDevice) -> Device {
        if (!deviceSettingsLoaded ) {
            loadDeviceSettings()
        }
        for d in deviceSettings {
            if d.uid == device.uniqueID {
                return d
            }
        }
        
        let newDevice = Device(fromDevice: device)!
        self.deviceSettings.append(newDevice)
        return newDevice
    }
    

    func applicationWillTerminate(aNotification: NSNotification) {
        
        self.notifications.deregisterAll()
    }

    func loadObservers() {
        
        notifications.registerObserver(name: NSNotification.Name.AVCaptureSessionRuntimeError.rawValue, forObject: session, dispatchAsyncToMainQueue: true, block: {note in
            let err = note?.userInfo![AVCaptureSessionErrorKey] as! NSError
            //self.window.presentError( err )
            NSLog(err.description)
        })
        
        
        notifications.registerObserver(name: NSNotification.Name.AVCaptureSessionDidStartRunning.rawValue, forObject: session,
        block: {note in
            print("Did start running")
            self.refreshDevices()
        })
        notifications.registerObserver(name: NSNotification.Name.AVCaptureSessionDidStartRunning.rawValue,
            forObject: session, block: {note in
            print("Did stop running")
        })

                
        notifications.registerObserver(name: NSNotification.Name.AVCaptureSessionDidStartRunning.rawValue, forObject: nil, dispatchAsyncToMainQueue: true, block: {note in
            print("Device connected")
            self.refreshDevices()
        })
        notifications.registerObserver(name: NSNotification.Name.AVCaptureSessionDidStartRunning.rawValue, forObject: nil, dispatchAsyncToMainQueue: true, block: {note in
            print("Device disconnected")
            self.refreshDevices()
        })
        
        
    }
    
    func startNewSession(device:AVCaptureDevice) -> Skin {
        

        let size = DeviceUtils(deviceType: .iPhone).skinSize
        let frame = DeviceUtils.getCenteredRect(windowSize: size!, screenFrame: NSScreen.main!.frame)
        let window = NSWindow(contentRect: frame,
                              styleMask: NSWindow.StyleMask(rawValue:  NSWindow.StyleMask.borderless.rawValue | NSWindow.StyleMask.resizable.rawValue),
                              backing: NSWindow.BackingStoreType.buffered, defer: false)
        
        window.isMovableByWindowBackground = true
        let frameView = NSMakeRect(0, 0,size!.width, (size?.height)!)
        
        let skin = Skin(frame: frameView)
        skin.initWithDevice(device: device)
        skin.ownerWindow = window
        window.contentView!.addSubview(skin)
        
        skin.registerNotifications()
        skin.updateAspect()
        
        window.backgroundColor = NSColor.clear
        window.isOpaque = false
        
        window.makeKeyAndOrderFront(NSApp)

        return skin
    }

    func refreshDevices() {
        
        self.devices = AVCaptureDevice.devices(for: AVMediaType.muxed)
            +  AVCaptureDevice.devices(for: AVMediaType.video)
        
        // A running device was disconnected?
        for(device, deviceView) in deviceSessions {
            if ( !self.devices.contains(device) ) {
                deviceView.endSession()
                deviceView.window?.close()
                self.deviceSessions[device] = nil
            }
        }
        
        
        // A new device connected?
        for device in self.devices {
            if device.modelID == "iOS Device" {
                if (!self.deviceSessions.keys.contains(device)) {
                    
                    // support only one session for now, until multiple devices videos start working
                    if(self.deviceSessions.count > 0) {
                        print("Only one session supported.")
                        let alert = NSAlert()
                        alert.messageText = "Only one device supported"
                        alert.addButton(withTitle: "OK")
                        alert.informativeText = "You can only display one device at a time. Please disconnect your other device."
                        alert.runModal()

                        break;
                    } else {
                        self.deviceSessions[device] = startNewSession(device: device)
                    }
            }
        }
        }

        if self.deviceSessions.count > 0 {
           self.window!.close()
        } else {
           self.window!.makeKeyAndOrderFront(NSApp)
        }

        
    }
    
    func updateMenu() {

        if(self.selectedDevice != nil) {
            menuDevice.title = selectedDevice!.deviceSettings!.name
            menuItemDevice.isEnabled = true
        } else {
            menuDevice.title = "No Device connected"
            menuItemDevice.isEnabled = false
        }
    }

    
    @IBAction func fitToScreen(sender: AnyObject) {
        self.selectedDevice?.scaleToFit(forgetSettings: true)
    }
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        updateMenu()
    }
    
    
    

}

