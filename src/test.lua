ngx.say("<h3>hello, world! this is test page.</h3>")

local clock = os.clock
function sleep(n)
    local t0 = clock()
    while clock() - t0 <= n do end
end

local function working()
    local i = 0
    while true do
        i = i + 1
        ngx.say("<p>coroutine productor: " .. tostring(i) .. "</p>")

        math.randomseed(os.time())
        local s = math.random(0, 6)
        ngx.say("<p>coroutine sleep: " .. tostring(s) .. "</p>")
        sleep(s)

        coroutine.yield(i)
    end
end

local co1 = coroutine.create(working)
local co2 = coroutine.create(working)

local status, value

for i = 0, 10, 1 do
    status, value = coroutine.resume(co1)
    ngx.say("<p>receive result: " .. tostring(value) .. ", status: " ..
                tostring(status) .. "</p><br>")
    status, value = coroutine.resume(co2)
    ngx.say("<p>receive result: " .. tostring(value) .. ", status: " ..
                tostring(status) .. "</p><br>")
end
