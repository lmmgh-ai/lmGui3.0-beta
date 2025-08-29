local view = require "view.view"
local border_layout = view:new()
border_layout.__index = border_layout
function border_layout:new(x, y, width, height)
    --独有属性
    local instance = setmetatable({
        text            = "border_layout",
        textColor       = { 0, 0, 0, 1 },
        hoverColor      = { 0.8, 0.8, 1, 1 },
        pressedColor    = { 0.6, 1, 1, 1 },
        backgroundColor = { 0.6, 0.6, 1, 1 },
        borderColor     = { 0, 0, 0, 1 },
        --
        x               = x or 0,
        y               = y or 0,
        width           = width or 50,
        height          = height or 50,
        children        = {},   -- 子视图列表
        visible         = true, --是否可见
        parent          = nil,  --父视图
        -- 回调函数，子类可以重写，也可以直接赋值
    }, self)

    return instance
end

function border_layout:draw()
    if not self.visible then return end

    -- 绘制按钮背景
    if self.isPressed then
        love.graphics.setColor(self.pressedColor)
    elseif self.hover then
        love.graphics.setColor(self.hoverColor)
    else
        love.graphics.setColor(self.backgroundColor)
    end

    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 5)
    love.graphics.setColor(self.borderColor)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 5)

    -- 绘制文本
    love.graphics.setColor(self.textColor)
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(self.text)
    local textHeight = font:getHeight()
    love.graphics.print(self.text, self.x + (self.width - textWidth) / 2, self.y + (self.height - textHeight) / 2)
end

function border_layout:on_click(id, x, y, dx, dy, istouch, pre)
    -- body
    --self:destroy()
    print(self:get_local_Position(x, y))
end

return border_layout;
