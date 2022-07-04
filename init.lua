local log = hs.logger.new('LOGGER', 'debug')

hs.hotkey.bind({"ctrl", "cmd", "shift"}, "L", function()
    local response = hs.http.asyncGet("http://10.0.0.21:9123/elgato/lights", {}, function(status, body, headers)
        log.f(body)
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

function sendSerial(status)
    local cmd = string.format("/Users/fred/Code/2040-zoom-controller/venv/bin/python /Users/fred/Code/2040-zoom-controller/serial_script.py %s", status)
    log.f("Executing `%s`", cmd)
    log.f(hs.execute(cmd))
end

function updateZoomStatus()
    log.f("Updating zoom status")
    local zoom = hs.application("zoom.us")
    log.f("zoom: %s", zoom)
    if zoom == nil then
        sendSerial("NO_MEETING")
        return
    end
    local callActive = zoom:findWindow("Zoom Meeting")
    local audioOn = zoom:findMenuItem({"Meeting", "Mute Audio"})
    local videoOn = zoom:findMenuItem({"Meeting", "Stop Video"})
    if callActive == nil then
        sendSerial("NO_MEETING")
    else
        if audioOn ~= nil then
            sendSerial("MIC_ON")
        else
            sendSerial("MIC_OFF")
        end
        
        if videoOn ~= nil then
            sendSerial("CAM_ON")
        else
            sendSerial("CAM_OFF")
        end
    end
end

t = hs.timer.doEvery(1, updateZoomStatus)