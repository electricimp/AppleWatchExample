//
//  Device.swift
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

class Device: NSObject, NSCoding {

    // MARK: Class Properties
    var name: String = ""
    var code: String = ""
    var app: String = ""
    var watchSupported: Bool = false
    var hasChanged: Bool = false
    var isInstalled: Bool = false
    var installState: Int = -1
    
    // MARK: Class Constants
    enum State {
        static let Installing = 1
        static let Removing = 0
        static let None = -1
    }

    
    // MARK: - Initialization Methods

    override init() {

        self.name = ""
        self.code = ""
        self.app = ""
        self.watchSupported = false
        self.isInstalled = false
        self.hasChanged = false
        self.installState = State.None
    }


    // MARK: - Coding Methods

    required init?(coder decoder: NSCoder) {

        self.name = ""
        self.code = ""
        self.app = ""
        self.watchSupported = false
        self.isInstalled = false
        self.hasChanged = false
        self.installState = State.None
        
        if let n = decoder.decodeObject(forKey: "device.name") { self.name = n as! String }
        if let c = decoder.decodeObject(forKey: "device.code") { self.code = c as! String }
        if let a = decoder.decodeObject(forKey: "device.app") { self.app = a as! String }

        self.watchSupported = decoder.decodeBool(forKey: "device.watch")
        self.isInstalled = decoder.decodeBool(forKey: "device.installed")
    }

    func encode(with encoder: NSCoder) {

        encoder.encode(self.name, forKey: "device.name")
        encoder.encode(self.code, forKey: "device.code")
        encoder.encode(self.app, forKey: "device.app")
        encoder.encode(self.watchSupported, forKey: "device.watch")
        encoder.encode(self.isInstalled, forKey: "device.installed")
    }
}
