-- Lua implementation of a PI controller using integer math
-- Written by Michiel Fokke <michiel@fokke.org>
-- Based on http://www.ledin.com/integer-algorithms-implementation-and-issues/
-- MIT license, http://opensource.org/licenses/MIT

require("mcl")
dofile("hal.lua")
dofile("config.lua")

params = params or {}
vals = vals or {}

function Param(p)
-- added space and comment, because NodeMCU does not like double closing brackets
-- nor does it like a closing bracket at the end of a line
  if params[p[KEY] ] == nil then
    params[p[KEY] ] = p[DEFAULT] --
  end
end
dofile("params.lua")

picontroller = newPicontroller()
temp_buf = newRingbuffer(5)
hum_buf = newRingbuffer(5)
hum_avg = newRunningAverageList{size=6, maxElements=120}

for i= 1, 6 do
  for j= 1, 120 do
    hum_avg.push(1000*params["humSP"])
  end
end

function control()
  print("Measuring humidity")
  status, temp, hum, temp_dec, hum_dec = dht.read(DHT11_PIN)
  gpio.write(LED_PIN, gpio.HIGH)
  tmr.alarm(LED_ALARM, 100, 0, function() gpio.write(LED_PIN, gpio.LOW) end)
  if( status == dht.ERROR_CHECKSUM ) then
    print( "DHT Checksum error." )
    tmr.alarm(CONTROLLER_ALARM, 2000, 0, control)
  elseif( status == dht.ERROR_TIMEOUT ) then
    print( "DHT Time out." )
    tmr.alarm(CONTROLLER_ALARM, 2000, 0, control)
  elseif( status == dht.OK ) then
    hum_avg.push(hum*1000+hum_dec)
    temp_buf.push(temp*1000+temp_dec)
    hum_buf.push(hum*1000+hum_dec)
    vals["temp"] = temp_buf.avg()
    vals["hum"] = hum_buf.avg()
    print( string.format("Humidity = %d.%d, temperature = %d.%d, setpoint = %d.%d", \
      floor(vals["hum"]/1000),vals["hum"]-floor(vals["hum"]/1000), floor(vals["temp"]/1000), \
      vals["temp"]-floor(vals["temp"]/1000), floor(hum_avg.avg()/1000), \
      hum_avg.avg()-floor(hum_avg.avg()/1000)))
    picontroller.Kp(params["controllerKp"])
    picontroller.Ki(params["controllerKi"])
    vals["u"] = picontroller.u(hum_avg.avg()/1000, vals["hum"]/1000)
    print( "Adjusting PWM to "..vals["u"] )
    print(string.format("humSP = %d", hum_avg.avg()))
    pwm.setduty(CONTROLLER_PIN, vals["u"] )
    tmr.alarm(CONTROLLER_ALARM, params["controllerinterval"]*1000, 0, control)
  end
end

pwm.close(LED_PIN)
gpio.mode(LED_PIN, gpio.OUTPUT)
gpio.write(LED_PIN, gpio.LOW)

pwm.stop(CONTROLLER_PIN)
gpio.mode(CONTROLLER_PIN, gpio.OUTPUT)
pwm.setup(CONTROLLER_PIN, 1000, 100)
pwm.start(CONTROLLER_PIN)

control()

-- vim: set si ts=2 sw=2 expandtab:
