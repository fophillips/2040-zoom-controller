local log = hs.logger.new('LOGGER', 'debug')

function getMeetStatus()
    local result, output, _ = hs.osascript.javascript([[
        (function(){
            var chrome = Application("Google Chrome");
            var tabIndex = -1;
            for(win of chrome.windows()) {
                tabIndex = win.tabs().findIndex(t => t.name().match(/^Meet - /));
            }

            if(tabIndex !== -1) {
                var tab = win.tabs()[tabIndex];
            } else {
                return -1;
            }

            var micOn = tab.execute({javascript: "document.querySelector('[aria-label=\"Turn off microphone (⌘ + d)\"]')"});
            var camOn = tab.execute({javascript: "document.querySelector('[aria-label=\"Turn off camera (⌘ + e)\"]')"});

            if(micOn && camOn) {
                return 3;
            }
            if(micOn) {
                return 2;
            }
            if(camOn) {
                return 1;
            }
            return 0;
        })();
    ]])

    return output
end

function leaveMeet()
    log.f("Leaving meet")
    hs.osascript.javascript([[
        (function(){
            var chrome = Application("Google Chrome");
            var tabIndex = -1;
            for(win of chrome.windows()) {
                tabIndex = win.tabs().findIndex(t => t.name().match(/^Meet - /));
            }

            if(tabIndex !== -1) {
                var tab = win.tabs()[tabIndex];
            } else {
                return -1;
            }

            tab.execute({javascript: "document.querySelector('[aria-label=\"Leave call\"]').click()"})
        })();
    ]])
end

function leaveZoom()
    log.f("Leaving zoom")
    local zoom = hs.application("zoom.us")
    hs.eventtap.keyStroke({"cmd"}, "W", 0, zoom)
end

function leaveCall()
    if getMeetStatus() ~= -1 then
        leaveMeet()
    end

    if getZoomStatus() ~= -1 then
        leaveZoom()
    end
end

hs.hotkey.bind({"ctrl", "cmd", "shift"}, "E", leaveCall)

hs.hotkey.bind({"ctrl", "cmd", "shift"}, "L", function()
    local response = hs.http.asyncGet("http://10.0.0.21:9123/elgato/lights", {}, function(status, body, headers)
        local settings = hs.json.decode(body)
        if settings["lights"][1]["on"] == 0 then
            settings["lights"][1]["on"] = 1
        else
            settings["lights"][1]["on"] = 0
        end
        local new_settings = hs.json.encode(settings)
        log.f(new_settings)
        hs.http.asyncPut("http://10.0.0.21:9123/elgato/lights", new_settings, {}, function(status, body, headers)
            log.f(status)
        end)
    end)
end)

hs.hotkey.bind({"ctrl", "cmd", "shift"}, "\\", function()
    if getMeetStatus() ~= -1 then
        local chrome = hs.application("Google Chrome")
        hs.eventtap.keyStroke({"cmd"}, "d", 0, chrome)
    end

    if getZoomStatus() ~= -1 then
        local zoom = hs.application("zoom.us")
        hs.eventtap.keyStroke({"cmd", "shift"}, "A", 0, zoom)
    end
end)

hs.hotkey.bind({"ctrl", "cmd", "shift"}, "V", function()
    if getMeetStatus() ~= -1 then
        local chrome = hs.application("Google Chrome")
        hs.eventtap.keyStroke({"cmd"}, "e", 0, chrome)
    end

    if getZoomStatus() ~= -1 then
        local zoom = hs.application("zoom.us")
        hs.eventtap.keyStroke({"cmd", "shift"}, "V", 0, zoom)
    end
end)

function sendSerial(status)
    local cmd = string.format("/Users/fred/Code/2040-zoom-controller/venv/bin/python /Users/fred/Code/2040-zoom-controller/serial_script.py %s", status)
    log.f("Executing `%s`", cmd)
    log.f(hs.execute(cmd))
end

function getZoomStatus()
    local zoom = hs.application("zoom.us")
    if zoom == nil then
        return -1
    end
    local callActive = zoom:findWindow("Zoom Meeting")
    local audioOn = zoom:findMenuItem({"Meeting", "Mute Audio"})
    local videoOn = zoom:findMenuItem({"Meeting", "Stop Video"})

    if callActive == nil then
        return -1
    end

    if audioOn ~= nil and videoOn ~= nil then
        return 3
    end

    if audioOn ~= nil then
        return 2
    end

    if videoOn ~= nil then
        return 1
    end

    return 0
end

function setController(status)
    if status == -1 then
        sendSerial("NO_MEETING")
    else
        if status == 2 or status == 3 then
            sendSerial("MIC_ON")
        else
            sendSerial("MIC_OFF")
        end
        
        if status == 1 or status == 3 then
            sendSerial("CAM_ON")
        else
            sendSerial("CAM_OFF")
        end
    end
end

function updateStatus()
    local meet = getMeetStatus()
    local zoom = getZoomStatus()

    log.f("meet=%s zoom=%s", meet, zoom)

    if meet ~= -1 then
        setController(meet)
    else
        setController(zoom)
    end
end

t = hs.timer.doEvery(3, updateStatus)
t2 = hs.timer.doEvery(3600, hs.relaunch)