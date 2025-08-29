local view = require "view.view"
local Slider = view:new()
Slider.__index = Slider
function Slider:new(x, y, width, height, gravity)
    local instance = setmetatable({
        x = x or 0,
        y = y or 0,
        width = width or 100,
        height = height or 20,
        id = nil,
        --
        ------
        slider_orientation = "horizontal", --horizontal,vertical--滑块拖动方向
        slider_x = 0,
        slider_y = 0,
        slider_width = 50,
        slider_height = 20,
        slider_number_min = 0,   --滑块最小输出值
        slider_number_max = 100, --滑块最大输出值
        slider_number_on = 0,    --滑块当前出值
        slider_hover = false,
        slider_isPressed = false,
        hoverColor = { 0.8, 0.8, 1, 1 },
        pressedColor = { 0.6, 1, 1, 1 },
        backgroundColor = { 0.6, 0.6, 1, 1 },
        borderColor = { 0, 0, 0, 1 },
    }, self)
    if gravity then --垂直
        instance.slider_orientation = "vertical"
    else            --默认横向
        instance.slider_orientation = "horizontal"
    end

    if instance.height > instance.width then
        instance.slider_width = instance.width
        instance.slider_height = instance.width
    elseif instance.height < instance.width then
        instance.slider_width = instance.height
        instance.slider_height = instance.height
    end

    return instance;
end

function Slider:draw()
    --背景
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    --背景边框
    love.graphics.setColor(self.borderColor)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    --开始绘制滑块
    if self.slider_isPressed then
        love.graphics.setColor(self.pressedColor)
    elseif self.slider_hover then
        love.graphics.setColor(self.hoverColor)
    else
        love.graphics.setColor(self.backgroundColor)
    end
    --绘制滑块
    love.graphics.push()
    love.graphics.translate(self.x, self.y) --偏移底框距离
    love.graphics.rectangle("fill", self.slider_x, self.slider_y, self.slider_width, self.slider_height, 5)
    love.graphics.setColor(self.borderColor)
    love.graphics.rectangle("line", self.slider_x, self.slider_y, self.slider_width, self.slider_height, 5)
    love.graphics.pop()
    if self.hover then --整体获取焦点 绘制底框
    end
end

function Slider:mousepressed(id, x, y, dx, dy, istouch, pre)
    local x1, y1 = self:get_local_Position(x, y)
    --print(x - self.x, y - self.y)
    if self.point_in_rect(x1, y1, self.slider_x, self.slider_y, self.slider_width, self.slider_height) then
        self.slider_isPressed = true --滑块被点击
    end
    -- print(self.slider_isPressed)
end

function Slider:mousemoved(id, x, y, dx, dy, istouch, pre)
    local x1, y1 = self:get_local_Position(x, y)
    --print(x1, y1)
    -- print(self.slider_x, self.slider_y, self.slider_width, self.slider_height)
    if self.point_in_rect(x1, y1, self.slider_x, self.slider_y, self.slider_width, self.slider_height) then
        self.slider_hover = true
    else
        self.slider_hover = false
    end
    --print(self.slider_isPressed)
    -- print(id, x, y, dx, dy,istouch, pre)
    if self.slider_isPressed then
        if self.slider_orientation == "vertical" then
            self:step_Value(dy)
        elseif self.slider_orientation == "horizontal" then
            self:step_Value(dx)
        end
    end
end

function Slider:off_hover() --失去焦点回调
    self.slider_isPressed = false;
    self.slider_hover = false
    self.hover = false;
end

function Slider:mousereleased(id, x, y, dx, dy, istouch, pre)
    self.slider_hover = false
    self.slider_isPressed = false;
end

function Slider:wheelmoved(id, x, y) --滚轮滑动
    -- body
    self:step_Value(-y * 5)
end

function Slider:step_Value(v) --滑块位置计算函数
    local v1 = ''
    local v2 = 0
    if self.slider_orientation == "horizontal" then
        v1 = "slider_x"
        v2 = self.width - self.slider_width
    elseif self.slider_orientation == "vertical" then
        v1 = "slider_y"
        v2 = self.height - self.slider_height
    else
        v1 = "slider_x"
        v2 = self.width - self.slider_width
    end
    --print(v1, v2)
    if self[v1] + v < 0 then
        ---print(1)
        self[v1] = 0
    elseif self[v1] + v > v2 then
        --print(2)
        self[v1] = v2
    else
        --print(123)
        local cv = (v2) / self.slider_number_max
        self[v1] = self[v1] + (cv * v)
    end
    self.slider_number_on = self[v1] / self.slider_number_max * 100
end

return Slider;
