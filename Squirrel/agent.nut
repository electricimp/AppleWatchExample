// IMPORTS
#require "Rocky.class.nut:2.0.1"

// GLOBALS
api <- Rocky();
settings <- {};

// FUNCTIONS
function setDefaults() {
    // Reset settings to default values
    settings = {};
    settings.switchState <- true;
    settings.sliderValue <- 10;

    // Write the new settings to persistent storage (overwriting exisiting file)
    server.save(settings);
}

function getSettings() {
    // Construct a settings string in JSON format
    local settingsTable = {};
    settingsTable.switchstate <- ("switchState" in settings ? settings.switchState : true);
    settingsTable.slidervalue <- ("sliderValue" in settings ? settings.sliderValue : 10);
    settingsTable.isconnected <- device.isconnected();
    return http.jsonencode(settingsTable);
}

// RUNTIME START

// Load in the persisted settings
local s = server.load();
if (s.len() == 0) {
    // There are no persisted settings, so create a new one
    setDefaults();
    server.log("Writing default settings");
} else {
    // 's' is the loaded table of settings, to point 'settings' at the same table
    server.log("Read settings from persistent storage");
    settings = s;
}

// Set up the Apple Watch API

// The following are the minimum endpoints expected by the Watch app:
// get application info, and get device settings
api.get("/applewatchexample/appinfo", function(context) {
    // Send back the app's UUID and an indicator to show whether AppleWatchExample is supported
    // ie. the Watch app includes a suitable control UI for the device type
    
    // NOTE Use the next two lines for the sample MyFirstApp, or comment them out and
    //      uncomment the subsequent two lines for the sample MySecondApp (values from apps.json)
    /*
    // MyFirstApp
    local info = { "appcode": "8B6B3A11-00B4-4304-BE27-ABD11DB1B774",
                   "watchsupported": "true" };
    */
    
    // MySecondApp
    local info = { "appcode": "DCD2B79C-4467-433C-B0D3-7448EDA17575",
                   "watchsupported": "true" };
    

    server.log("App info requested by Watch");
    context.send(200, http.jsonencode(info));
});

api.get("/applewatchexample/state", function(context) {
    // Send back device settings in string format:
    // "x.y.z", where setting values are separated by periods in a pre-arranged
    // sequence. Binary values are represented as "1" (true) and "0" (false).
    // This string is returned by the placeholder function 'getSettings()'.
    // The code add ".1" or ".0" to the end of the string to indicate whether the
    // device is connected to the agent or not
    server.log("Settings requested by Watch");
    local settingsString = getSettings();
    context.send(200, settingsString);
});

// The following endpoint is used to apply settings when they are changed in the 
// Watch app UI. A POST request to /actions updates the passed setting(s):
// { "action"  : <update/state/slider>, // The setting being changed or action taken
//   "value"   : <?> }                  // An appropriate setting value (optional)
api.post("/actions", function(context) {
    try {
        local data = http.jsondecode(context.req.rawbody);
        
        if ("action" in data) {
            if (data.action == "update") {
                // Watch UI button pressed
                server.log("Watch UI button pressed - resetting defaults");
                setDefaults();
            }

            if (data.action == "state") {
                settings.switchState = data.value == "on" ? true : false;
                server.log("Watch UI switch turned " + data.value);
            }

            if (data.action == "slider") {
                settings.sliderValue = data.value.tointeger();
                server.log("Watch UI slider set to " + data.value);
            }

            // NOTE Typically the application would relay any updated settings values
            //      to the device at this point, but this had been ommitted for clarity
        }
    } catch (err) {
        server.error(err);
        context.send(400, "Bad data posted");
        return;
    }

    // Return 'OK' to the Watch
    context.send(200, "OK");

    // Persist the updated settings
    local result = server.save(settings);
    if (result != 0) server.error("Could not save settings to persistent storage (code: " + result + ")");
}.bindenv(this));
