//
//  AppDelegate.swift
//  AppleWatchExample
//
//  Copyright © 2018 Electric Imp. All rights reserved.
//
//  SPDX-License-Identifier: MIT
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
//  EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
//  OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
//  ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.



import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var myDevices:DeviceList!
    let docsDir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions:
        [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        // Point 'myDevices' at the device list singleton
        self.myDevices = DeviceList.sharedDevices

        // Set universal window tint for views that delegate this property to this object
        self.window!.tintColor = UIColor.init(red: 0.05, green: 0.67, blue: 0.70, alpha: 1.0)

        // Load in default device list if the file has already been saved
        let docsPath = self.docsDir[0] + "/devices"
        if FileManager.default.fileExists(atPath: docsPath) {
            // Devices file is present on the iDevice, so load it in
            let load = NSKeyedUnarchiver.unarchiveObject(withFile:docsPath)

            if load != nil {
                let devices1 = load as! DeviceList
                let devices2 = devices1.devices as Array
                self.myDevices.devices.removeAll()
                self.myDevices.devices.append(contentsOf:devices2)
                self.myDevices.currentDevice = devices1.currentDevice
                NSLog("Device list loaded (%@)", docsPath);
            }
        }

        var installCount: Int = 0
        for i in 0..<self.myDevices.devices.count {
            let device: Device = self.myDevices.devices[i]
            if device.isInstalled {
                installCount = installCount + 1
            }
        }

        // Set Settings Page details
        let defaults: UserDefaults = UserDefaults.standard
        defaults.set(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String, forKey: "com.ei.applewatchexample.app.version")
        defaults.set(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String, forKey: "com.ei.applewatchexample.app.build")
        defaults.set("\(installCount)", forKey: "com.ei.applewatchexample.devices.installcount")
        defaults.set("\(self.myDevices.devices.count)", forKey: "com.ei.applewatchexample.devices.listcount")
        
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {

        saveDevices()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {

        saveDevices()
        NotificationCenter.default.post(name:NSNotification.Name("com.ei.applewatchexample.will.quit"), object:self)
    }

    func saveDevices() {

        let defaults: UserDefaults = UserDefaults.standard

        if self.myDevices.devices.count > 0 {
            var installCount: Int = 0
            for i in 0..<self.myDevices.devices.count {
                let device: Device = self.myDevices.devices[i]
                if device.isInstalled {
                    installCount = installCount + 1
                }
            }

            defaults.set("\(installCount)", forKey: "com.ei.applewatchexample.devices.installcount")
            defaults.set("\(self.myDevices.devices.count)", forKey: "com.ei.applewatchexample.devices.listcount")
            defaults.set(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String, forKey: "com.ei.applewatchexample.app.version")
            defaults.set(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String, forKey: "com.ei.applewatchexample.app.build")

            // The app is going into the background or closing, so save the list of devices
            let docsPath = self.docsDir[0] + "/devices"

            // Run through the list of devices to look for empty device records,
            // which we don't want to save
            var i: Int = 0
            repeat {
                let device: Device = self.myDevices.devices[i]

                if device.name == "" && device.app == "" && device.code == "" {
                    // This is an empty device record so remove it
                    self.myDevices.devices.remove(at: i)
                }

                i = i + 1
            } while (self.myDevices.devices.count > i)

            let success = NSKeyedArchiver.archiveRootObject(self.myDevices, toFile:docsPath)
            if success {
                NSLog("Device list saved (%@)", docsPath)
            } else {
                NSLog("Device list save failed")
            }
        } else {
            NSLog("No devices to save")
        }
    }
}

