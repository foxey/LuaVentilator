-- Configuration HTTP server for Ventilator
--
-- Written by Michiel Fokke <michiel@fokke.org>
--
-- MIT license, http://opensource.org/licenses/MIT

print("Starting server")
 
params = params or {}
vals = vals or {}

-- load parameters
local param_keys={}
function Param(p)
  param_keys[p[KEY]]=p
  params[p[KEY]]=params[p[KEY]] or p[DEFAULT]
end
dofile("params.lua")

-- load value descriptions
local value={}
function Value(v)
  value[v[KEY]]=v
end
dofile("values.lua")
  
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
            if param_keys[k] ~= nil then
              params[k] = v
              print(string.format("params[\"%s\"] = %s", k,v))
            end
          end
        end

        print("HTTP 200")
    
        conn:send("HTTP/1.1 200 OK\n\n")
        conn:send("<!DOCTYPE HTML>\n")
        conn:send("<html>\n")
        conn:send('<head><meta  content="text/html; charset=utf-8">\n')
        conn:send("<title>Ventilator configurator</title></head>\n<body>\n")
        conn:send("<h1>Sensor values</h1>\n")
        for v in pairs(value) do
          conn:send(string.format('%s: %s %s<br>\n', v[DESC], vals[v[KEY]] or "", v[UNIT]))
        end

        conn:send('<h1>Set parameters</h1>\n')
        conn:send('<form action="" method="POST">\n')

        for _,p in pairs(param_keys) do
          conn:send(string.format('<p>%s <input type="input" name="%s" value="%s"> %s</p>\n', p[DESC], p[KEY], params[p[KEY]] or "", p[UNIT]))

        conn:send('"></p>\n<input type="submit" value="Update values">\n')
        conn:send('</body></html>\n')
      end
    end
    conn:on("sent",function(conn) conn:close() end)
  end)
end)

-- vim: set si ts=2 sw=2 expandtab:

