 	print("Starting server")
 
  if params == nil then 
    params = {}
  end
 
 if vals == nil then 
    vals = {}
  end
  
  srv=net.createServer(net.TCP) srv:listen(80,function(conn)
    conn:on("receive",function(conn,payload)
    --next row is for debugging output only
    print(payload)
    local e = payload:find("\r\n", 1, true)
    if not e then
      conn:send('HTTP/1.1 400 Bad request\n\n')
    else
      local line = payload:sub(1, e - 1)
      local r = {}
      _, _, method, url = line:find("^([A-Z]+) (.-) HTTP/[1-9]+.[0-9]+$")
   
      if method ~= "GET" and method ~= "POST" then
        print("HTTP Error 405")
        conn:send('HTTP/1.1 405 Method Not Allowed\n\n')
      elseif url ~= "/" and url ~="/index.html" then
        print("HTTP Error 404")
        conn:send('HTTP/1.1 404 Not found\n\n')
      else
        body_idx = {payload:find("\r\n\r\n", 1, true)}
        if body_idx ~= nil then
          body = payload:sub(body_idx[1]+1, #payload)
          payload = nil
          collectgarbage()
          --parse POST values from body
          for k,v in string.gmatch(body, "(%w+)=([^&]+)") do
            params[k] = v
            print(string.format("params[\"%s\"] = %s", k,v))
          end
        end

        print("HTTP 200")
    
        conn:send('HTTP/1.1 200 OK\n\n')
        conn:send('<!DOCTYPE HTML>\n')
        conn:send('<html>\n')
        conn:send('<head><meta  content="text/html; charset=utf-8">\n')
        conn:send('<title>Ventilator configurator</title></head>\n<body>\n')
        if vals["hum"] ~= nil then
            conn:send("<h1>Sensor values</h1>\n")
          if vals["temp"] ~= nil then
            conn:send("Temperature: "..vals["temp"])
          end
          conn:send("\n<br>Humidity: "..vals["hum"].."<br>\n")
        end
        conn:send('<h1>Set parameters</h1>\n')
        conn:send('<form action="" method="POST">\n')
        conn:send('<p>Humidity setpoint <input type="input" name="humSP" value="')
        if params["humSP"] ~= nil then
          conn:send(params["humSP"])
        end
        conn:send('"> %</p>\n<p>Controller interval <input type="input" name="controllerinterval" value="')
        if params["controllerinterval"] ~= nil then
          conn:send(params["controllerinterval"])
        end
        conn:send('"> sec</p>\n<p>Controller Kp value <input type="input" name="controllerKp" value="')
        if params["controllerKp"] ~= nil then
          conn:send(params["controllerKp"])
        end
        conn:send('"></p>\n<p>Controller Ki value <input type="input" name="controllerKi" value="')
        if params["controllerKi"] ~= nil then
          conn:send(params["controllerKi"])
        end        
        conn:send('"></p>\n<p>Collect interval <input type="input" name="collectinterval" value="')
        if params["collectinterval"] ~= nil then
          conn:send(params["collectinterval"])
        end        
        conn:send('"> sec</p>\n<input type="submit" value="Update values">\n')
        conn:send('</body></html>\n')
      end
    end
    conn:on("sent",function(conn) conn:close() end)
  end)
end)


