LED_ALARM=2
COLLECT_ALARM=1
CONTROLLER_ALARM=0

DHT11_PIN = 3 --  Sensor data pin, GPIO2
LED_PIN = 1  -- Led power pin, GPIO5

SSID="ssid"
WIFI_PASSWORD="password"
api_key = "1234567890ABCDEF"

dnsserver = "8.8.8.8"
host = "api.thingspeak.com"

if vals == nil then
  vals = {}
end

if params == nil then
  params = {}
end
if params["collectinterval"] == nil then
  params["collectinterval"] = 30
end
  
ipaddr = nil

function dnslookup()
  if (wifi.sta.status() ~= 5) then
    print("Waiting for wifi. Status is "..wifi.sta.status())
  else
    tmr.stop(COLLECT_ALARM)
    print("Lookup "..host)
    if (dnsserver ~= nil) then
      print("Set 2nd dns server to "..dnsserver)
      net.dns.setdnsserver(dnsserver,1)
    end
    conn=net.createConnection(net.TCP, false)
    conn:dns(host , getIp)
  end
end

function getIp(conn, ip)
  if (ip == nil) then
    print("Lookup for "..host.." at "..net.dns.getdnsserver(0).." and "..net.dns.getdnsserver(1).." failed. Retrying...")
    tmr.delay(2000000)
    node.restart()
  else
    ipaddr = ip
  end
  collect()
end

function collect()
  if ipaddr == nil then
    print("Waiting for DNS lookup of "..host)
    tmr.alarm(COLLECT_ALARM, 500, 0, collect)
  elseif vals["temp"] ~= nil and vals["hum"] ~= nil then
    print("Sending data to "..ipaddr)
    local conn=net.createConnection(net.TCP, false)
    conn:on("receive", function(conn, pl) print(pl) end)
    -- fokke.org: 83.161.137.43
    conn:connect(80,ipaddr)
    conn:send("GET /update?key="..api_key.."&field1="..vals["temp"].."&field2="..vals["hum"])
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
    tmr.alarm(COLLECT_ALARM, params["collectinterval"]*1000, 0, collect)
  end
end

if (wifi.sta.status() ~= 5) then
  wifi.setmode(wifi.STATION)
  wifi.sta.config(SSID , WIFI_PASSWORD)
end

tmr.alarm(COLLECT_ALARM, 500, 1, dnslookup)