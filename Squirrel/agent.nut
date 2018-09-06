#require "Rocky.class.nut:2.0.1"

api <- Rocky();

api.get("/applewatchexample/appinfo", function(context) {
    // Send back the app's UUID and an indicator to show whether AppleWatchExample is supported
    // ie. the Watch app includes a suitable control UI for the device type
    local info = { "appcode": "<UUID>",
                   "watchsupported": "true" };
    context.send(200, http.jsonencode(info));
});

api.get("/applewatchexample/state", function(context) {
    // Send back device settings in string format:
    // "x.y.z", where setting values are separated by periods in a pre-arranged
    // sequence. Binary values are represented as "1" (true) and "0" (false).
    // This string is returned by the placeholder function 'getSettings()'.
    // The code add ".1" or ".0" to the end of the string to indicate whether the
    // device is connected to the agent or not
    local settingsString = getSettings() + "." + (device.isconnected() ? "1" : "0");
    context.send(200, settingsString);
});
