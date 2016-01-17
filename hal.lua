-- Hardware abstraction layer for Ventilator on ESP8266
--
-- Written by Michiel Fokke <michiel@fokke.org>
--
-- MIT license, http://opensource.org/licenses/MIT

CONTROLLER_ALARM=0
COLLECT_ALARM=1
LED_ALARM=2

DHT11_PIN = 3 --  Sensor data pin, GPIO2
LED_PIN = 1  -- Led power pin, GPIO5
CONTROLLER_PIN = 4 -- Powers the onboard LED (test mode)