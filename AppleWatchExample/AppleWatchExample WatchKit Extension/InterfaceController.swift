//
//  InterfaceController.swift
//  AppleWatchExample WatchKit Extension
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



import WatchKit
import ClockKit
import Foundation
import WatchConnectivity


class InterfaceController: WKInterfaceController, WCSessionDelegate {

    // MARK: Class UI Outlets
    @IBOutlet weak var deviceTable: WKInterfaceTable!

    // MARK: Class Properties
    let watchSession: WCSession = WCSession.default
    let docsDir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
    var myDevices: DeviceList! = nil
    var listChanged: Bool = false
    var apps: [String : Any] = [:]


    // MARK: - Lifecycle Functions

    override func awake(withContext context: Any?) {

        super.awake(withContext: context)

        // Set up app and UI
        self.myDevices = DeviceList()
        self.watchSession.delegate = self
        self.watchSession.activate()
        self.setTitle("Electric Imp")
    }
    
    override func willActivate() {

        // This method is called when watch view controller is about to be visible to user
        super.willActivate()

        // Load in the device list if it's present
        let docsPath = self.docsDir[0] + "/devices"
        if FileManager.default.fileExists(atPath: docsPath) {
            // Devices file is present on the iDevice, so load it in
            let load = NSKeyedUnarchiver.unarchiveObject(withFile:docsPath)

            if load != nil {
                let devicesList: DeviceList = load as! DeviceList
                let devices: [Device] = devicesList.devices as Array
                self.myDevices.devices.removeAll()
                self.myDevices.devices.append(contentsOf: devices)
                self.myDevices.currentDevice = devicesList.currentDevice
            }
        }

        // Read in the current apps list
        do {
            if let file = Bundle.main.url(forResource: "apps", withExtension: "json") {
                let data = try Data(contentsOf: file)
                // NSLog(String.init(data: data, encoding: String.Encoding.utf8)!)
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let object = json as? [String: Any] {
                    self.apps = object
                } else {
                    NSLog("Error", "Apps list JSON is invalid")
                }
            } else {
                NSLog("Error", "Apps list file missing")
            }
        } catch {
            NSLog("Error", "Apps list file damaged")
        }

        // Present the UI
        initializeUI()
    }
    
    override func didDeactivate() {

        // This method is called when watch view controller is no longer visible
        super.didDeactivate()

        // Save the device list
        if listChanged { saveDevices() }
    }


    // MARK: - Utility Functions

    func saveDevices() {

        // The app is going into the background or closing, so save the list of devices
        if self.myDevices.devices.count > 0 {
            let docsPath = self.docsDir[0] + "/devices"
            let success = NSKeyedArchiver.archiveRootObject(self.myDevices, toFile:docsPath)
            listChanged = !success
        }
    }

    func initializeUI() {

        // Prepare the UI
        if self.myDevices.devices.count == 0 {
            // There are no devices to be listed yet, so create a table row
            // that says just that
            self.deviceTable.setNumberOfRows(1, withRowType: "main.table.row")
            let aRow: TableRow = self.deviceTable.rowController(at: 0) as! TableRow
            aRow.nameLabel.setText("No Devices")
        } else {
            // Tell the table how many rows it will need to show
            self.deviceTable.setNumberOfRows(self.myDevices.devices.count, withRowType: "main.table.row")

            // Run through the device list to add each device to the UI
            for i in 0..<self.myDevices.devices.count {
                let aDevice: Device = self.myDevices.devices[i]
                let aRow: TableRow = self.deviceTable.rowController(at: i) as! TableRow
                aRow.nameLabel.setText(aDevice.name)
                aRow.appIcon.setImage(UIImage.init(named: getAppNameLower(aDevice.app)))
            }
        }
    }


    // MARK: - Table Handler Functions

    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {

        if self.myDevices.devices.count == 0 {
            // The app doesn't know about any devices, so tell the user to sync data from the iPhone
            let waa: WKAlertAction = WKAlertAction.init(title: "OK", style: WKAlertActionStyle.default, handler: {
                // NOP
            })

            presentAlert(withTitle: "Add Some Devices",
                         message: "Please run the Controller app on your iPhone, add some devices, and click ‘Activate’",
                         preferredStyle: WKAlertControllerStyle.alert,
                         actions: [waa])
        } else {
            // Work out what type of app the selected device is running and
            // pop up the appropriate interface controller
            let aDevice: Device = self.myDevices.devices[rowIndex]
            var name: String = ""

            name = getAppNameLower(aDevice.app) + ".ui"

            if name.count > 0 {
                self.pushController(withName: name, context: aDevice)
            }
        }
    }

    func getAppNameLower(_ code:String) -> String {

        return getAppName(code).lowercased()
    }

    func getAppName(_ code: String) -> String {

        let apps: [[String : Any]] = self.apps["apps"] as! [[String : Any]]
        if apps.count > 0 {
            for i in 0..<apps.count {
                let app = apps[i]
                if code == app["code"] as! String {
                    return app["name"] as! String
                }
            }
        }

        return "unknown"
    }


    // MARK: - WCSessionDelegate Functions

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {

        WKInterfaceDevice.current().play(.click)

        DispatchQueue.main.async() {
            self.processContext()
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {

        // NOP
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {

        // NOP
    }

    func processContext() {

        // Get the latest received context and use the data that it contains
        // to reconstruct the device list, making sure we save the list and
        // re-display the UI
        if let context = watchSession.receivedApplicationContext as? [String : String] {
            WKInterfaceDevice.current().play(.click)
            if let dataString = context["info"] {
                let ds = dataString as NSString
                if ds.length != 0 {
                    if ds == "clear" {
                        self.myDevices.devices.removeAll()
                    } else {
                        let devices = ds.components(separatedBy: "\n\n")
                        if devices.count > 1 {
                            self.myDevices.devices.removeAll()
                            for i in 0..<devices.count - 1 {
                                let d = devices[i] as NSString
                                let device = d.components(separatedBy: "\n")
                                let aDevice: Device = Device()
                                aDevice.name = device[0]
                                aDevice.code = device[1]
                                aDevice.app = device[2]

                                self.myDevices.devices.append(aDevice)
                            }
                        }
                    }
                } else {
                    self.myDevices.devices.removeAll()
                }

                saveDevices()
                initializeUI()
            }
        }
    }
}
