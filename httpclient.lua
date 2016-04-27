-- HTTP client to post sensordata to Thingspeak for Ventilator
--
-- Written by Michiel Fokke <michiel@fokke.org>
--
-- MIT license, http://opensource.org/licenses/MIT

dofile("hal.lua")
dofile("config.lua")

host = "api.thingspeak.com"
alivecount = 0

params = params or {}
vals = vals or {}

-- load parameters
function Param(p)
  params[p[KEY]]=params[p[KEY]] or p[DEFAULT]
end
dofile("params.lua")

ipaddr = nil

function dnslookup()
  if (wifi.sta.status() ~= 5) then
    print(string.format("Waiting for wifi. Status is %s", wifi.sta.status()))
    wifi.setmode(wifi.STATION)
    wifi.sta.config(SSID , WIFI_PASSWORD)
  else
    tmr.stop(COLLECT_ALARM)
    print("Lookup "..host)
    if (dnsserver ~= nil) then
      print(string.format("Set 2nd dns server to %s", dnsserver))
      net.dns.setdnsserver(dnsserver,1)
    end
    conn=net.createConnection(net.TCP, false)
    conn:dns(host , getIp)
  end
end

function getIp(conn, ip)
  if (ip == nil) then
    print(string.format("Lookup for %s at %s and %s failed. Retrying..."), host, net.dns.getdnsserver(0), net.dns.getdnsserver(1))
    tmr.delay(2000000)
    node.restart()
  else
    ipaddr = ip
  end
  collect()
end

function collect()
  if (wifi.sta.status() ~= 5) then
    print("Wifi not connected. Status is "..wifi.sta.status())
    wifi.setmode(wifi.STATION)
    wifi.sta.config(SSID , WIFI_PASSWORD)
    tmr.alarm(COLLECT_ALARM, 1000, 0, collect)
  elseif ipaddr == nil then
    print("Waiting for DNS lookup of "..host)
    tmr.alarm(COLLECT_ALARM, 500, 0, collect)
  elseif vals["temp"] ~= nil and vals["hum"] ~= nil then
    print("Sending data to "..ipaddr)
    local conn=net.createConnection(net.TCP, false)
    conn:on("receive", function(conn, pl) print(pl) alivecount = 0 end)
    -- fokke.org: 83.161.137.43
    conn:connect(80,ipaddr)
    conn:send(string.format("GET /update?key=%s&field1=%d.%03d&field2=%d.%03d", api_key.,math.floor(vals["temp"]/1000), math.floor(vals["temp"]%1000), math.floor(vals["hum"]/1000), math.floor(vals["hum"]%1000))
    if params["humSP"] ~= nil then
      conn:send("&field3="..params["humSP"])
    end
    if vals["u"] ~= nil then
      conn:send("&field4="..vals["u"])
    end
    conn:send(" HTTP/1.1\r\n")
    conn:send("Host: "..host.."\r\n")
    conn:send("Connection: keep-alive\r\nAccept: */*\r\n")
    conn:send("\r\n")
    alivecount = alivecount + 1
    if alivecount > 1 then
      print("Already missed "..alivecount.." keep alives. Will restart after "..params["collectkeepalive"].." misses.")
    elseif alivecount > tonumber(params["collectkeepalive"]) then
      print("Missed "..params["collectkeepalive"].." keep alives. Restarting")
      node.restart()
    end    
    tmr.alarm(COLLECT_ALARM, params["collectinterval"]*1000, 0, collect)
  end
end

if (wifi.sta.status() ~= 5) then
  wifi.setmode(wifi.STATION)
  wifi.sta.config(SSID , WIFI_PASSWORD)
end

tmr.alarm(COLLECT_ALARM, 500, 1, dnslookup)
