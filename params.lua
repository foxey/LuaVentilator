-- Parameter configuration for Ventilator
--
-- Written by Michiel Fokke <michiel@fokke.org>
--
-- MIT license, http://opensource.org/licenses/MIT

-- keys (watch for collisions with keys in values.lua!)
KEY=1
DESC=2
UNIT=3
DEFAULT=4

-- key, description, units, default
Param{ "humSP", "Humidity setpoint", "%", 40 }
Param{ "controllerinterval", "Controller interval ", "sec", 5 }
Param{ "controllerKp", "Controller Kp value", "/1000", 2000 }
Param{ "controllerKi", "Controller Ki value", "/1000", 3000 }
Param{ "collectinterval", "Collect interval", "sec", 30 }
Param{ "collectkeepalive", "Collect keepalive", "", 10 }
