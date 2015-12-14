print("Get available APs")
available_aps = ""
wifi.setmode(wifi.STATION)
wifi.sta.getap(function(t)
   if t then
      for k,v in pairs(t) do
         ap = string.format("%-10s",k)
         ap = trim(ap)
         print(ap)
         available_aps = available_aps .. "<li>".. ap .."</li>"
      end
      print(available_aps)
      print("Starting Alarm!")
      tmr.alarm(0,5000,1, function() setup_server(available_aps) end )
   end
end)

local unescape = function (s)
   s = string.gsub(s, "+", " ")
   s = string.gsub(s, "%%(%x%x)", function (h)
         return string.char(tonumber(h, 16))
      end)
   return s
end

function setup_server(aps)
   print("Setting up Wifi AP")
   wifi.setmode(wifi.SOFTAP)
   wifi.ap.config({ssid="ESP8266"})  
   wifi.ap.setip({ip="192.168.0.1",netmask="255.255.255.0",gateway="192.168.0.1"})
   print("Setting up webserver")

--web server
srv = nil
   srv=net.createServer(net.TCP)
   srv:listen(80,function(conn)
       conn:on("receive", function(client,request)
           local buf = ""
           local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
           if(method == nil)then
               _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP")
           end
           local _GET = {}
           if (vars ~= nil)then
               for k, v in string.gmatch(vars, "(%w+)=([^%&]+)&*") do
                   _GET[k] = unescape(v)
               end
           end
             
           if (_GET.psw ~= nil and _GET.ap ~= nil) then
              client:send("Saving data..")
              file.open("config.lua", "w")
              file.writeline('ssid = "' .. _GET.ap .. '"')
              file.writeline('password = "' .. _GET.psw .. '"')
              file.close()
              node.compile("config.lua")
              file.remove("config.lua")
              client:send(buf)
              node.restart()
           end
   
           buf = "<html><body>"
           buf = buf .. "<h3>Configure WiFi</h3><br>"
           buf = buf .. "<form method='get' action='http://" .. wifi.ap.getip() .."'>"
           buf = buf .. "Available APs:<br>"
           buf = buf .. "<ul>" .. aps .. "</ul><br>"
           buf = buf .. "Enter wifi SSID: <input type='text' name='ap'></input><br>"
           buf = buf .. "Enter wifi password: <input type='password' name='psw'></input><br>"
           buf = buf .. "<br><button type='submit'>Save</button>"                   
           buf = buf .. "</form></body></html>"
           client:send(buf)
           client:close()
           collectgarbage()
       end)
   end)
   
   print("Please connect to: " .. wifi.ap.getip())
   tmr.stop(0)
end

function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end