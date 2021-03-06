//
//  DeviceDetailViewController.swift
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

class DeviceDetailViewController: UIViewController,
    UITextFieldDelegate,
    URLSessionDelegate,
    URLSessionDataDelegate {


    // MARK: Class Outlets
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var codeField: UITextField!
    @IBOutlet weak var codeLabel: UILabel!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var connectionProgress: UIActivityIndicatorView!
    @IBOutlet weak var appTypeLabel: UILabel!
    @IBOutlet weak var appTypeField: UITextField!
    @IBOutlet weak var supportLabel: UILabel!
    
    // MARK: Class Properties
    var myDevices: DeviceList!
    var currentDevice: Device!
    var receivedData: NSMutableData! = nil
    var serverSession: URLSession?
    var apps: [String : Any] = [:]


    // MARK: - Lifecycle Functions
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Set up the UI
        self.appTypeField.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {

        super.viewWillAppear(animated)
        
        // Display the device info
        if self.currentDevice != nil {
            // New items have a 'code' property that is an empty string
            if self.currentDevice.code.count > 0 {
                self.nameField.text = self.currentDevice.name
                self.nameLabel.text = self.currentDevice.app.count > 0 ? "The Device’s Name:" : "Enter the Device’s Name:"
                
                self.codeField.text = self.currentDevice.code
                self.codeLabel.text = self.currentDevice.app.count > 0 ? "The Device’s Agent ID Code:" : "Enter the Device’s Agent ID Code:"
                
                self.infoButton.setTitle((self.currentDevice.app.count > 0 ? "Refresh Device Data" : "Get Device Data"), for: UIControlState.normal)
                self.appTypeField.text = getAppName(self.currentDevice.app)
                self.supportLabel.text = "Watch control" + (!self.currentDevice.watchSupported ? " not" : "") + " supported"
            }
        } else {
            // Clear the fields
            self.nameField.text = ""
            self.nameLabel.text = "Enter the Device’s Name:"
            self.codeLabel.text = "Enter the Device’s Agent ID Code:"
            self.codeField.text = ""
            self.infoButton.setTitle("Get Device Data", for: UIControlState.normal)
            self.appTypeField.text = ""
            self.supportLabel.text = ""
        }
    }
    
    @objc func appWillQuit(note:NSNotification) {

        NotificationCenter.default.removeObserver(self)
    }


    // MARK: - Control Methods

    @objc func changeDetails() {

        if self.currentDevice != nil {
            // Check that the device is supported — if not, warn the user
            if !self.currentDevice.watchSupported && self.currentDevice.app.count != 0 {
                let alert = UIAlertController.init(title: "This device can’t be controlled by your watch", message: "Are you sure you wish to add it to the device list? If you do, it will not sync to your watch.", preferredStyle: UIAlertControllerStyle.alert)
                
                var action = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { (_) in
                    self.saveData()
                    self.goBack()
                })
                alert.addAction(action)
                
                action = UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: { (_) in
                    self.currentDevice = nil
                    self.goBack()
                })
                alert.addAction(action)
                
                self.present(alert, animated: true)
                return
            }
            
            saveData()
        }

        goBack()
    }
    
    func saveData() {
        
        // The view is about to close so save the text fields' content
        // if there is anything to save
        if self.currentDevice.code != self.codeField.text! {
            self.currentDevice.code = self.codeField.text!
            self.currentDevice.hasChanged = true
        }
        
        if self.currentDevice.name != self.nameField.text! {
            self.currentDevice.name = self.nameField.text!
            self.currentDevice.hasChanged = true
        }
    }
    
    func goBack() {
        
        // Stop listening for 'will enter foreground' notifications
        NotificationCenter.default.removeObserver(self)
        
        // Jump back to the list of devices
        self.navigationController!.popViewController(animated: true)
    }
    
    @IBAction func getProxy(_ sender: Any) {
        
        getDeviceInfo()
    }


    // MARK: - Text Field Delegate Functions

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {

        for item in self.view.subviews {
            let view = item as UIView
            if view.isKind(of: UITextField.self) { view.resignFirstResponder() }
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        textField.resignFirstResponder()
        return true
    }
    

    // MARK: - Connection Functions

    func getDeviceInfo() {

        if let code : String = self.codeField.text {
            if code.count != 0 {
                let url:URL? = URL(string: "https://agent.electricimp.com/" + code + "/applewatchexample/appinfo")

                if url == nil {
                    reportError("DeviceDetailViewController.getDeviceInfo() generated a malformed URL string", "Could not connect to the device")
                    return
                }

                connectionProgress.startAnimating()

                var request:URLRequest = URLRequest(url:url!,
                                                    cachePolicy:URLRequest.CachePolicy.reloadIgnoringLocalCacheData,
                                                    timeoutInterval:60.0)
                request.httpMethod = "GET"

                if self.serverSession == nil {
                    self.serverSession = URLSession(configuration:URLSessionConfiguration.default,
                                                    delegate:self,
                                                    delegateQueue:OperationQueue.main)
                }

                let task:URLSessionDataTask = serverSession!.dataTask(with:request)
                task.resume()
            } else {
                let alert = UIAlertController.init(title: "Missing Agent ID",
                                                   message: "Please enter an agent ID in the appropriate field",
                                                   preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"),
                                              style: UIAlertActionStyle.default,
                                              handler: nil))
                self.present(alert, animated: true)
            }
        }
    }


    // MARK: - URLSession Delegate Functions

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {

        if self.receivedData == nil { self.receivedData = NSMutableData() }
        self.receivedData.append(data)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {

        let rps = response as! HTTPURLResponse
        let code = rps.statusCode;

        if code > 399 {
            if code == 404 {
                completionHandler(code == 404 ? URLSession.ResponseDisposition.cancel : URLSession.ResponseDisposition.allow)
            }
        } else {
            completionHandler(URLSession.ResponseDisposition.allow);
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {

        if error != nil {
            reportError("DeviceDetailViewController.didCompleteWithError() could not connect to the impCloud", "Could not connect to the device")
        } else {
            if self.receivedData.length > 0 {
                // let dataString:String? = String(data:self.receivedData as Data, encoding:String.Encoding.ascii)
                var appData: [String:String]

                do {
                    appData = try JSONSerialization.jsonObject(with: self.receivedData as Data, options: JSONSerialization.ReadingOptions.allowFragments) as! [String:String]
                    if let code = appData["appcode"] {
                        self.appTypeField.text = getAppName(code)
                        self.currentDevice.app = code
                    }
                    
                    self.currentDevice.watchSupported = appData["watchsupported"] == "true" ? true : false
                    self.supportLabel.text = "Watch control" + (appData["watchsupported"] == "false" ? " not" : "") + " supported"
                    self.currentDevice.hasChanged = true
                } catch {
                    reportError("DeviceDetailViewController.didCompleteWithError() send malformed JSON" , "Could not connect to the device")
                }
            }
        }

        task.cancel()
        self.connectionProgress.stopAnimating()
        self.receivedData = nil
    }
    
    
    // MARK: - Utility Functions

    func reportError(_ logMessage:String, _ reportMessage:String) {

        // Log the detailed message
        NSLog(logMessage)

        // Report the basic message to the user via an alert
        let alert = UIAlertController.init(title: "Error", message: reportMessage, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true)
    }

    func getAppName(_ code: String) -> String {
        
        // Return the app's name as derived from its known UUID
        // The name is used to get the appropriate icon file
        let apps: [[String : Any]] = self.apps["apps"] as! [[String : Any]]
        if apps.count > 0 {
            for i in 0..<apps.count {
                let app = apps[i]
                if code == app["code"] as! String {
                    return app["name"] as! String
                }
            }
        }
        
        // Otherwise just return "unknown"
        return "unknown"
    }

}

