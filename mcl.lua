-- Mathematical class library
-- Written by Michiel Fokke <michiel@fokke.org>
-- MIT license, http://opensource.org/licenses/MIT

function printf(s,...) io.write(s:format(...)) end

function newRingbuffer(mySize)
  local self = { buffer = {}, size = mySize or 3, index = 0 }
  local push = function (v)
    self.buffer[self.index+1] = v
    self.index = (self.index + 1) % self.size
    return v
  end  
  local sum = function ()
    sum = 0
    for _,v in ipairs(self.buffer) do
      sum = sum + v
    end
    return sum
  end
  local avg = function ()
    return sum()/#self.buffer
  end
  return {
    push = push,
    sum = sum,
    avg = avg
  }
end

function newRunningAverage()
  local self = { n = 0, sum = 0 }
  local push = function (v)
    self.sum = self.sum + v
    self.n = self.n + 1
    return self.n
  end
  local reset = function ()
    self.sum = 0
    self.n = 0
    return 0
  end
  local avg = function ()
    return self.sum/self.n
  end
  return {
    push = push,
    reset = reset,
    avg = avg
  }
end

function newRunningAverageList(arg)
  local self = { buffer = {}, size = arg.size or 1, maxElements = arg.maxElements or 5, index = 0}
  for i=1, self.size do
    self.buffer[i] = newRunningAverage()
  end
  local push = function (v)
    for i=1, self.size do
      if i == (((self.index/self.maxElements)-1)%self.size)+1 then
--        print(string.format("index=%d, resetting buffer %d", self.index, i))
        self.buffer[i].reset()
      end
      self.buffer[i].push(v)
    end
    self.index = (self.index + 1) % (self.size * self.maxElements)
    return(v)
  end
  local avg = function (i)
    if i then
      return self.buffer[i].avg()
    else
--      print (string.format("returning avg for index %d",math.floor(((self.index-1)/self.maxElements)%self.size)+1))
      return self.buffer[math.floor(((self.index-1)/self.maxElements)%self.size)+1].avg()
    end
  end
  local index = function ()
    return self.index
  end
  return {
    push = push,
    index = index,
    avg = avg
  }
end

function newPicontroller(arg)
  local MAX_INTEGRATOR = 1024
  local U_MIN = 100
  local U_MAX = 1023
  local arg = arg or {}
  local self = { Kp = arg.Kp or 1000 , Ki = arg.Ki or 1000, u = U_MIN, S = 0}
  function u(r, y)
    local e = y - r -- Humidity is inversely proportional to ventilator RPM, thus error is inverted.
    self.S = self.S + e
    if self.S > MAX_INTEGRATOR then
      self.S = MAX_INTEGRATOR
      print( "picontroller: Limited S to "..MAX_INTEGRATOR )
    elseif self.S < -MAX_INTEGRATOR then
      self.S = -MAX_INTEGRATOR
      print( "picontroller: Limited S to -"..MAX_INTEGRATOR )
    end
    self.u = (self.Kp * (e + (self.Ki * self.S) / 1000)) / 1000
--    printf( "u = %.3f, Kp = %.3f, e = %.3f, Ki = %.3f, S = %.3f\n", self.u, self.Kp, e, self.Ki, self.S)
    if self.u > U_MAX then
      return U_MAX
    elseif self.u < U_MIN then
      return U_MIN
    else
      return self.u
    end
  end
  function Kp(v)
    self.Kp = v or self.Kp
    return self.Kp
  end
  function Ki(v)
    self.Ki = v or self.Ki
    return self.Ki
  end
  return {
    u = u,
    Kp = Kp,
    Ki = Ki
  }
end

-- vim: set si ts=2 sw=2 expandtab:
