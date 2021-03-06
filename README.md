# Electric Imp Example Code: Apple Watch Support #

Control Electric Imp Platform-based Internet of Things devices from your Apple Watch.

## Usage ##

The iPhone app provides a means to add devices — enter the device’s agent ID and a user-friendly name — and sync the list of devices to the Watch app, which will provide an appropriate UI for each type of device as they are selected. The design is modular, allowing you to add UIs and the *WKInterfaceController* objects that control them to personalize the app.

Or simply take the code apart and use it as the foundation for a completely different UI — the choice is yours.

## Testing ##

This example is fully working. If you have a spare development device, create a Device Group and add the included agent code then run it. You can use Xcode to build and run the iOS and watchOS code in the Simulator, allowing you to run both and see the effects in the impCentral device log.

**Note** Remember to pair a Watch to an iDevice via Xcode's **Devices and Simulators** panel first.

## Design ##

### iOS App ###

The Watch app’s iPhone-based companion collates your imp-enabled devices and syncs them with the Watch. Tap **Edit** to add a new device and then select it in order to give it a convenient name and to enter its agent ID. Tap **Get Device Data** to check what app the device is running and whether it is supported by AppleWatchExample. Click **Devices** to go back when you’re done.

Typically, the iOS app will only be used to add devices. An end-user should not need to use it too often.

Each device is listed with a switch which can be used to sync that device with the Watch app, either to add or remove it.

You can update the Watch separately by tapping **Actions** and then **Update Watch**. This is also useful if you re-order the list of devices. Re-ordering is activated by tapping **Actions** and then **Re-order Device List**.

The app stores the current list of devices across app restarts and relaunches.

The list is sync’d with the Watch by sending a string of all the devices to appear on the Watch: device name, agent ID and UUID fields are separated by newlines; device records are separated by two newlines. The string is absolute: it contains all the devices to appear on the Watch from the point it is sent; the Watch app recreates its own list from the string.

The code includes a file, `apps.json`, which lists the apps’ UUIDs and human-readable names as an array of objects within the *apps* object:

```json
{ "apps": [
    { "code": "<UUID_1>",
      "name": "APP_NAME_1" },
    { "code": "<UUID_2>",
      "name": "<APP_NAME_2" } ]
}
```

This file is read at launch and used to determine which icons to display based upon the UUID provided by the imp application's agent code. All local app data look-ups use this file’s contents. As such it provides a single place to update app details. 

**Note** The app icon’s filename should match the app’s name in lower case, for example:

| App Name | App icon name |
| --- | --- |
| MyFirstApp | myfirstapp(.png/jpg/tif) |

You should embed the same `apps.json` in both your iOS and Watch app bundles. A sample file is included in this repo.

App icons should be added to the Asset file of both the iOS app and the Watch app Extension.

### Watch App ###

The Watch app presents a list of available devices. Selecting any of these presents a standard UI customised for the application the device is running. The device-specific UI presents the name of the device; its application type (hard-coded in the UI); a series of controls relevant to the device; and finally a button which takes the user back to the device list (easier than tapping on the tiny title bar).

The *WKInterfaceController* instance which manages the device-specific UI is designed to disable the device controls until it has received status information from the device’s agent *(see below)*. Once this information is received, the device-specific controls are enabled. The *WKInterfaceController* instance presents a red flashing graphic to indicate that it is attempting to connect to the device's agent; this stops flashing and goes green when the connection is made, otherwise it remains red.

**Note** The watch app loads in each UI's *WKInterfaceController* instance by name: the name of the app (as in the `app.json` file, above) in lower case and suffixed `.ui`. For example:

| App Name | App UI file |
| --- | --- |
| MyFirstApp | myfirstapp.ui |

The instance name is set in Xcode Interface Builder's Storyboard Identifier field for the *WKInterfaceController* instance.

### Squirrel ###

The Electric Imp application component of the design makes use of Electric Imp's [Rocky library](https://developer.electricimp.com/libraries/utilities/rocky) to serve standard application information at `/applewatchexample/appinfo`, and a device status (online or offline) information at `/applewatchexample/state`. These and other application control endpoints can of course be modified as required — just update the appropriate section of the relevant *WKInterfaceController* instance.

`/applewatchexample/appinfo` returns the following JSON:

```json
{ "appcode": "<APP_UUID>",
  "watchsupported": true };
```

`/applewatchexample/state` is used to return current device state information. This is provided as a JSON string, derived from the contents of the *settings* table in the function *getSettings()*:

```json
{ "switchstate": true,
  "slidervalue": 18,
  "isconnected": true };
```

The Watch code expects the data in this form. However, you are free to choose other structures &mdash; just modify the *WKInterfaceController* sub-class' *urlSession(session, task, didCompleteWithError)* function.

In addition, the example code uses the endpoint `/applewatchexample/action` to receive actions from the Watch app. If you are retro-fitting Apple Watch support to an existing imp application, you may have your own API already in place. In this case, you should modify the Watch app's control trigger functions accordingly.

### Notes ###

At this time, the example code does not support multiple watches paired to the same iOS device.

### Copyright and License ###

Copyright &copy; 2018, Electric Imp.

Apple Watch Example is made available under the MIT licence.
