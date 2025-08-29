local view = require "view.view"
local utf8 = require("utf8")
utf8.sub = function(str, start_pos, end_pos)
    if not end_pos then end_pos = -1 end
    local start_byte = utf8.offset(str, start_pos)
    local end_byte = utf8.offset(str, end_pos + 1)
    if end_byte then end_byte = end_byte - 1 end

    return string.sub(str, start_byte, end_byte)
end


local edit_text = view:new()
edit_text.__index = edit_text
function edit_text:new(text, x, y, width, height)
    --独有属性
    local instance = setmetatable({
        textColor = { 0, 0, 0, 1 },
        hoverColor = { 0.9, 0.9, 0.9, 1 },
        pressedColor = { 0.6, 1, 1, 1 },
        backgroundColor = { 255, 255, 255, 1 },
        borderColor = { 0, 0, 0, 1 },
        text = text or "Hello World",                                -- 输入的文本内容
        isActive = false,                                            -- 是否处于激活状态（正在输入）
        cursorPos = string.len(defaultValue or ""),                  -- 光标位置
        scrollX = 0,                                                 -- 文本水平滚动偏移
        font = love.graphics.getFont() or love.graphics.newFont(14), -- 字体
        cursorColor = { 0, 0, 1, 1 },                                -- 光标颜色
        cursorBlinkTime = 0,                                         -- 光标闪烁计时器
        onSelectAll = false,                                         -- 是否全选状态
        ------
        x = x or 0,
        y = y or 0,
        width = width or 50,
        height = height or 50,
        children = {},  -- 子视图列表
        visible = true, --是否可见
        parent = nil,   --父视图
        -- 回调函数，子类可以重写，也可以直接赋值
    }, self)

    return instance
end

-- 查找单词开头位置
function edit_text:findWordStart(pos)
    local i = pos
    -- 跳过空白字符
    while i > 0 and utf8.sub(self.text, i, i):match("%s") do
        i = i - 1
    end
    -- 跳过非空白字符
    while i > 0 and not utf8.sub(self.text, i, i):match("%s") do
        i = i - 1
    end
    return i
end

-- 查找单词结尾位置
function edit_text:findWordEnd(pos)
    local i = pos + 1
    local len = utf8.len(self.text)
    -- 跳过空白字符
    while i <= len and utf8.sub(self.text, i, i):match("%s") do
        i = i + 1
    end
    -- 跳过非空白字符
    while i <= len and not utf8.sub(self.text, i, i):match("%s") do
        i = i + 1
    end
    return i - 1
end

-- 获取输入框文本
function edit_text:getValue()
    return self.text
end

-- 设置输入框文本
function edit_text:setValue(value)
    self.text = value or ""
    self.cursorPos = utf8.len(self.text) --光标位置
    self.isActive = false                --取消输入状态
end

-- 检查输入框是否处于激活状态
function edit_text:isFocused()
    return self.isActive
end

function edit_text:draw()
    if not self.visible then return end
    --[[
    -- 绘制按钮背景
    if self.isPressed then
        love.graphics.setColor(self.pressedColor)
    elseif self.hover then
        love.graphics.setColor(self.hoverColor)
    else
        love.graphics.setColor(self.backgroundColor)
    end]]

    -- 保存当前图形状态
    local r, g, b, a = love.graphics.getColor()
    local font = love.graphics.getFont()

    -- 绘制背景
    if self.isActive then
        love.graphics.setColor(self.pressedColor)
    else
        love.graphics.setColor(self.borderColor)
    end
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

    -- 绘制内边框（创建边框效果）
    if self.hover then
        love.graphics.setColor(self.hoverColor)
    else
        love.graphics.setColor(self.backgroundColor)
    end
    love.graphics.rectangle("fill", self.x + 2, self.y + 2, self.width - 4, self.height - 4)

    -- 设置文本颜色和字体
    love.graphics.setColor(self.textColor)
    love.graphics.setFont(self.font)

    -- 计算可见文本区域
    local textX = self.x + 5 - self.scrollX
    local textY = self.y + (self.height - self.font:getHeight()) / 2

    -- 绘制文本
    love.graphics.print(self.text, textX, textY)

    -- 如果输入框处于激活状态，绘制光标
    if self.isActive then
        -- 计算光标位置
        local cursorText = utf8.sub(self.text, 1, self.cursorPos)
        local cursorX = textX + self.font:getWidth(cursorText)

        -- 处理文本滚动，确保光标始终可见
        if cursorX < self.x + 5 then
            self.scrollX = self.scrollX - (self.x + 5 - cursorX)
        elseif cursorX > self.x + self.width - 5 then
            self.scrollX = self.scrollX + (cursorX - (self.x + self.width - 5))
        end

        -- 重置光标位置（滚动后需要重新计算）
        cursorText = utf8.sub(self.text, 1, self.cursorPos)
        cursorX = textX + self.font:getWidth(cursorText)

        -- 绘制光标（闪烁效果）
        if self.cursorBlinkTime % 1 < 0.5 then
            love.graphics.setColor(self.cursorColor)
            love.graphics.line(cursorX, self.y + 5, cursorX, self.y + self.height - 5)
        end
    end
    -- 恢复之前的图形状态
    love.graphics.setColor(r, g, b, a)
    love.graphics.setFont(font)
end

function edit_text:update(dt)
    self.cursorBlinkTime = self.cursorBlinkTime + dt --更新光标闪烁计时器
end

function edit_text:keypressed(key)           --键盘按下
    if self.isActive then
        local text_len = utf8.len(self.text) --文字长度
        if key == "backspace" then
            -- 处理全选删除
            if self.onSelectAll then
                self.text = ""
                self.cursorPos = 0
                self.onSelectAll = false
            elseif self.cursorPos > 0 then
                -- 删除光标前一个字符
                local before = utf8.sub(self.text, 1, self.cursorPos - 1)
                local after = utf8.sub(self.text, self.cursorPos + 1, text_len)
                self.text = before .. after
                self.cursorPos = self.cursorPos - 1
            end
            self.cursorBlinkTime = 0
            return true
        elseif key == "delete" then
            -- 删除光标后一个字符
            if self.cursorPos < utf8.len(self.text) then
                local before = utf8.sub(self.text, 1, self.cursorPos)
                local after = utf8.sub(self.text, self.cursorPos + 2, text_len)
                self.text = before .. after
            end
            self.cursorBlinkTime = 0
            return true
        elseif key == "left" then
            -- 光标左移
            if love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
                -- Ctrl+Left: 移动到单词开头
                self.cursorPos = self:findWordStart(self.cursorPos)
            else
                self.cursorPos = math.max(0, self.cursorPos - 1)
            end
            self.cursorBlinkTime = 0
            return true
        elseif key == "right" then
            -- 光标右移
            if love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
                -- Ctrl+Right: 移动到单词结尾
                self.cursorPos = self:findWordEnd(self.cursorPos)
            else
                self.cursorPos = math.min(utf8.len(self.text), self.cursorPos + 1)
            end
            self.cursorBlinkTime = 0
            return true
        elseif key == "home" then
            -- 移动到行首
            self.cursorPos = 0
            self.cursorBlinkTime = 0
            return true
        elseif key == "end" then
            -- 移动到行尾
            self.cursorPos = utf8.len(self.text)
            self.cursorBlinkTime = 0
            return true
        elseif key == "a" and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
            -- Ctrl+A: 全选
            self.onSelectAll = true
            return true
        elseif key == "c" and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
            -- Ctrl+C: 复制（这里简化处理）
            return true
        elseif key == "v" and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
            -- Ctrl+V: 粘贴（这里简化处理）
            return true
        end
    end
    return false
end

function edit_text:loss_keypressed()         --失去输入权限时执行回调
    self.isActive = false                    --取消输入状态
    if love.system.getOS() == "Android" then --安卓手动关闭输入法
        love.keyboard.setTextInput(false)
    end
end

function edit_text:textinput(text) --文字输入
    -- print(text)
    --print(love.window.getDesktopDimensions())
    if self.isActive then
        -- 如果是全选状态，先清除文本
        if self.onSelectAll then
            self.text = ""
            self.cursorPos = 0
            self.onSelectAll = false
        end

        -- 在光标位置插入字符
        local before = utf8.sub(self.text, 1, self.cursorPos) --光标前
        local after = ""                                      --光标后
        local text_len = utf8.len(self.text)
        if text_len ~= self.cursorPos then
            --print("插入")
            after = utf8.sub(self.text, self.cursorPos, text_len)
            -- print(after)
        end

        self.text = before .. text .. after
        self.cursorPos = self.cursorPos + utf8.len(text) --设置光标位置
        self.cursorBlinkTime = 0                         -- 重置光标闪烁
        --print(before, after, self.cursorPos, utf8.len(self.text))
        return true
    end
    return false
end

function edit_text:mousepressed(id, x, y, dx, dy, istouch, pre) --pre短时间按下次数 模拟双击
    if love.system.getOS() == "Android" then                    --安卓手动启动输入法
        love.keyboard.setTextInput(true)
    end
    local x1, y1 = self:get_local_Position(x, y) --获取相对点击位置
    self.isActive = true
    self.cursorBlinkTime = 0                     -- 重置光标闪烁

    -- 计算点击位置对应的光标位置
    local textX = self.x + 5 - self.scrollX
    local relativeX = x1 - textX

    -- 找到最接近点击位置的字符位置
    local minDist = math.huge
    local bestPos = 0

    for i = 0, utf8.len(self.text) do
        local charX = self.font:getWidth(utf8.sub(self.text, 1, i))
        local dist = math.abs(relativeX - charX)
        if dist < minDist then
            minDist = dist
            bestPos = i
        end
    end

    self.cursorPos = bestPos
end

function edit_text:on_click(...)
    -- body
end

return edit_text;
