//
//  DeviceList.swift
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



import Foundation

    // This class provides a simple means to hold a list of devices as a singleton
    // available in common to all other classes

class DeviceList: NSObject, NSCoding {

    // MARK: Class Singleton Properties
    static let sharedDevices: DeviceList = DeviceList()

    // MARK: Class Properties
    var devices: [Device] = []
    var currentDevice: Int = -1

    
    // MARK: - Initialization Methods

    override init() {

        self.currentDevice = -1
        self.devices = []
    }

    
    // MARK: - Coding Methods

    func encode(with encoder:NSCoder) {

        encoder.encode(self.currentDevice, forKey: "applewatchexample.current.index")
        encoder.encode(self.devices, forKey: "applewatchexample.device.list")
    }

    required init?(coder decoder: NSCoder) {

        self.devices = decoder.decodeObject(forKey: "applewatchexample.device.list") as! Array
        self.currentDevice = decoder.decodeInteger(forKey: "applewatchexample.current.index")
    }
}
