local view = require "view.view"
local text = view:new()
text.__index = text
function text:new(text, x, y, width, height)
    --独有属性
    local instance = setmetatable({
        text           = tostring(text) or "text",
        text_x         = 0,
        text_y         = 0,
        text_color     = { 0, 0, 0, 1 }, --文字颜色
        text_cache     = nil,            --当文字被省略后原文字被存在这个变量中
        text_font      = nil,            --单独字体显示 字体对象
        text_copy      = false,          --是否允许复制文本
        text_size      = nil,            --字体大小
        text_align     = "center",       --left, center, right 文本对齐方式
        text_max_lines = 1,              --最大显示行数
        text_ellipsis  = "end",          --start middle end 省略前段中间结尾 size_to_fit 自适
        --
        x              = x or 0,
        y              = y or 0,
        width          = width or 50,
        height         = height or 50,
        children       = {},   -- 子视图列表
        visible        = true, --是否可见
        parent         = nil,  --父视图
        -- 回调函数，子类可以重写，也可以直接赋值
    }, self)
    --初始字体显示位置
    instance:update_text_xy() --更新字体显示位置
    return instance
end

function text:update_text_xy()           --更新字体显示位置
    --初始化字体
    local font = love.graphics.getFont() -- 获取当前字体（默认字体或已设置的字体
    if self.text_font then
        font = self.text_font
    else
        font = love.graphics.getFont()
    end
    -- 获取文本宽度和高度
    local text_width = tonumber(font:getWidth(self.text))
    local text_height = tonumber(font:getHeight()) -- 获取字体行高（单行高度）
    --设置文本居中显示
    self.text_x = (self.x + (self.width / 2)) - (text_width / 2)
    self.text_y = (self.y + (self.height / 2)) - (text_height / 2)
end

function text:draw()
    --绘制背景
    if self.isPressed then
        love.graphics.setColor(self.pressedColor)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 5)
    elseif self.hover then
        love.graphics.setColor(self.hoverColor)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 5)
    else
        -- love.graphics.setColor(self.backgroundColor)
    end
    --文字
    love.graphics.setColor(self.text_color)
    love.graphics.print(self.text, self.text_x, self.text_y)
    --love.graphics.printf(self.text, self.text_x, self.text_y, self.width, self.text_align)
end

return text;
