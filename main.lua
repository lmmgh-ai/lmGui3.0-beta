require "fun"
gui = require "gui"
local test = require "test"
local debugGraph = require "debugGraph"
CustomPrint = require "print"
CustomPrint:init()
--加载字体
local path = "YeZiGongChangTangYingHei-2.ttf"
local font = love.graphics.newFont(path)
love.graphics.setFont(font)

--加载测试文件
---------------------------------
require("test.main")
--require("test.main2")
---------------------------------
function love.load(...)
    debugGraph:load(...)
end

function love.update(dt)
    gui:update(dt)
    debugGraph:update(dt)
    CustomPrint:update(dt)
end

function love.draw()
    love.graphics.clear(1, 1, 1) -- 白色背景
    gui:draw()
    love.graphics.setColor({ 0, 0, 0 })
    debugGraph:draw()
    CustomPrint:draw()
end

function love.keypressed(key)
    gui:keypressed(key)
end

function love.textinput(text)
    gui:textinput(text)
end

if love.system.getOS() == "Android" then
    function love.touchpressed(id, x, y, dx, dy, pressure) --触摸按下
        --  print((tostring(id)=="userdata: NULL"))
        --print((tostring(id)=="userdata: 0x00000001"))
        -- print(love.getVersion())
        gui:touchpressed(id, x, y, dx, dy, true, pressure)
    end

    function love.touchmoved(id, x, y, dx, dy, pressure) --触摸滑动
        gui:touchmoved(id, x, y, dx, dy, true, pressure)
    end

    function love.touchreleased(id, x, y, dx, dy, pressure) --触摸抬起
        gui:touchreleased(id, x, y, dx, dy, true, pressure)
    end
elseif love.system.getOS() == "Windows" then
    function love.mousemoved(x, y, dx, dy, istouch) --鼠标滑动
        gui:mousemoved(nil, x, y, dx, dy, istouch, nil)
    end

    function love.mousepressed(x, y, id, istouch, pressure) --pre短时间按下次数 模拟双击
        gui:mousepressed(id, x, y, nil, nil, istouch, pressure)
    end

    function love.mousereleased(x, y, id, istouch, pressure) --pre短时间按下次数 模拟双击
        gui:mousereleased(id, x, y, nil, nil, istouch, pressure)
    end

    function love.wheelmoved(x, y)
        gui:wheelmoved(nil, x, y)
    end
end
