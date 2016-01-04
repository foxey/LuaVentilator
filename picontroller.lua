-- Lua implementation of a PI controller using integer math
--
-- Written by Michiel Fokke <michiel@fokke.org>
--
-- Based on http://www.ledin.com/integer-algorithms-implementation-and-issues/
--
-- MIT license, http://opensource.org/licenses/MIT

CONTROLLER_ALARM=0
COLLECT_ALARM=1
LED_ALARM=2

DHT11_PIN = 3 --  Sensor data pin, GPIO2
LED_PIN = 1  -- Led power pin, GPIO5
CONTROLLER_PIN = 4

MAX_INTEGRATOR = 1024
U_MIN = 100

local S = 0

if vals == nil then
  vals = {}
end

if params == nil then
  params = {}
end
if params["controllerinterval"] == nil then
  params["controllerinterval"] = 5
end
if params["controllerKp"] == nil then
  params["controllerKp"] = 100
end
if params["controllerKi"] == nil then
  params["controllerKi"] = 100
end
if params["humSP"] == nil then
  params["humSP"] = 10
end

function control()
  print("Measuring humidity")
  status, vals["temp"], vals["hum"], temp_dec, hum_dec = dht.read(DHT11_PIN)
  gpio.write(LED_PIN, gpio.HIGH)
  tmr.alarm(LED_ALARM, 100, 0, function() gpio.write(LED_PIN, gpio.LOW) end)
  if( status == dht.ERROR_CHECKSUM ) then
    print( "DHT Checksum error." )
    tmr.alarm(CONTROLLER_ALARM, 2000, 0, control)
  elseif( status == dht.ERROR_TIMEOUT ) then
    print( "DHT Time out." )
    tmr.alarm(CONTROLLER_ALARM, 2000, 0, control)
  elseif( status == dht.OK ) then
    print( "Humidity = "..vals["hum"]..", temperature = "..vals["temp"]..", setpoint = "..params["humSP"] )
    vals["u"] = picontroller(params["humSP"], vals["hum"])
    print( "Adjusting PWM to "..vals["u"] )
    print( "S= "..S )
    pwm.setduty(CONTROLLER_PIN, vals["u"] )
    tmr.alarm(CONTROLLER_ALARM, params["controllerinterval"]*1000, 0, control)
  end
end

function picontroller(r, y)
  local u
  local e = y - r -- Humidity is inversely proportional to ventilator RPM, thus error is inverted.
  S = S + e
  if S > MAX_INTEGRATOR then
    S = MAX_INTEGRATOR
    print( "picontroller: Limited S to "..MAX_INTEGRATOR )
  elseif S < -MAX_INTEGRATOR then
    S = -MAX_INTEGRATOR
    print( "picontroller: Limited S to -"..MAX_INTEGRATOR )
  end
  u = (params["controllerKp"] * (e + (params["controllerKi"] * S) / 100)) / 100
  if u > 1023 then
    return 1023
  elseif u < U_MIN then
    return U_MIN
  else
    return u
  end
end


pwm.close(LED_PIN)
gpio.mode(LED_PIN, gpio.OUTPUT)
gpio.write(LED_PIN, gpio.LOW)

pwm.stop(CONTROLLER_PIN)
gpio.mode(CONTROLLER_PIN, gpio.OUTPUT)
pwm.setup(CONTROLLER_PIN, 1000, U_MIN)
pwm.start(CONTROLLER_PIN)

control()

