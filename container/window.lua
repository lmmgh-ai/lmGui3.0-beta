local view = require "view.view"
local window = view:new()
window.__index = window
function window:new(x, y, width, height)
    --独有属性
    local instance = setmetatable({
        title = title or "window",                -- 窗口标题
        is_title_Dragging = false,                -- 是否正在拖拽
        dragOffsetX = 0,                          -- 拖拽时的X偏移量
        dragOffsetY = 0,                          -- 拖拽时的Y偏移量
        isResizable = true,                       -- 是否可调整大小
        isMinimized = false,                      -- 是否最小化
        isMaximized = false,                      -- 是否最大化
        min_width = 0,                            --调整窗口最小高度
        min_height = 25,                          --调整窗口最小高度
        originalX = x or 100,                     -- 原始X坐标（用于还原）
        originalY = y or 100,                     -- 原始Y坐标（用于还原）
        originalWidth = width or 300,             -- 原始宽度（用于还原）
        originalHeight = height or 200,           -- 原始高度（用于还原）
        titleBarHeight = 25,                      -- 标题栏高度
        borderWidth = 10,                         -- 边框宽度（用于调整大小）
        backgroundColor = { 0.9, 0.9, 0.9, 0.9 }, -- 背景颜色
        titleBarColor = { 0.2, 0.4, 0.8, 1 },     -- 标题栏颜色
        borderColor = { 0.1, 0.1, 0.1, 1 },       -- 边框颜色
        textColor = { 1, 1, 1, 1 },               -- 文字颜色
        buttons = {},                             -- 窗口按钮集合
        content = "",                             -- 窗口内容
        visible = true,                           -- 窗口是否可见
        --
        x = x or 0,
        y = y or 0,
        width = width or 50,
        height = height or 50,
        children = {},  -- 子视图列表
        visible = true, --是否可见
        parent = nil,   --父视图
        -- 回调函数，子类可以重写，也可以直接赋值
    }, self)
    --初始化窗口按钮
    instance:createButtons()

    return instance
end

--额外带标题栏需要重写绘图函数
function window:_draw()
    if self.visible then
        self:draw()
        -- 绘制子视图
        love.graphics.push()
        --额外增加标题的偏移
        love.graphics.translate(self.x, self.y + self.titleBarHeight)
        --开启剪裁
        love.graphics.setScissor(self.x, self.y, self.width, self.height)
        for i, child in pairs(self.children) do
            --print(i)
            child:_draw()
        end
        --关闭剪裁
        love.graphics.setScissor()
        love.graphics.pop()
    else
    end
end

--额外带标题栏需要重写传递给子视图的位置
--全局点转换相对点
function window:get_local_Position(x, y)
    local parent = self.parent
    local x1 = x - self.x
    local y1 = y - self.y - self.titleBarHeight
    if parent then
        return parent:get_local_Position(x1, y1)
    else
        return x1, y1;
    end
end

--相对点转换全局点
function window:get_world_Position(x, y)
    local parent = self.parent
    local x1 = x + self.x
    local y1 = y + self.y + self.titleBarHeight
    if parent then
        return parent:get_world_Position(x1, y1)
    else
        return x1, y1;
    end
end

-- 检测点全局点是否在视图内
function window:containsPoint(x, y)
    local absX, absY = self:get_world_Position(0, -self.titleBarHeight)
    return x >= absX and x <= absX + self.width and
        y >= absY and y <= absY + self.height
end

function window:draw()
    if not self.visible then return end

    -- 保存当前的绘图状态
    love.graphics.push()

    -- 绘制窗口背景
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

    -- 绘制标题栏
    love.graphics.setColor(self.titleBarColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.titleBarHeight)

    -- 绘制窗口边框
    love.graphics.setColor(self.borderColor)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.titleBarHeight)

    -- 绘制标题文字
    love.graphics.setColor(self.textColor)
    love.graphics.print(self.title, self.x + 10, self.y + 5)

    -- 绘制窗口按钮
    for i, button in ipairs(self.buttons) do
        -- 绘制按钮背景
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        love.graphics.rectangle("fill", self.x + button.x, self.y + button.y, button.width, button.height)

        -- 绘制按钮边框
        love.graphics.setColor(0.3, 0.3, 0.3, 1)
        love.graphics.rectangle("line", self.x + button.x, self.y + button.y, button.width, button.height)

        -- 绘制按钮文字
        love.graphics.setColor(self.textColor)
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(button.text)
        local textHeight = font:getHeight()
        love.graphics.print(button.text,
            self.x + button.x + (button.width - textWidth) / 2,
            self.y + button.y + (button.height - textHeight) / 2)
    end

    -- 绘制调整大小手柄
    if self.isResizable and not self.isMaximized then
        love.graphics.setColor(0.3, 0.3, 0.3, 1)
        love.graphics.polygon("fill",
            self.x + self.width - 10, self.y + self.height,
            self.x + self.width, self.y + self.height - 10,
            self.x + self.width, self.y + self.height)
    end

    -- 绘制窗口内容（如果窗口没有最小化）
    if not self.isMinimized then
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.printf(self.content,
            self.x + 10,
            self.y + self.titleBarHeight + 10,
            self.width - 20,
            "left")
    end

    -- 恢复之前的绘图状态
    love.graphics.pop()
end

-- 创建窗口控制按钮
function window:createButtons()
    local buttonSpacing = 5                                      --按钮间隔
    local buttonSize = self.titleBarHeight - (buttonSpacing * 2) --按钮大小
    --local rightOffset = self.width - buttonSpacing
    local W_width = self.width;
    local titleBarHeight = self.titleBarHeight --标题栏高度
    -- 关闭按钮
    table.insert(self.buttons, {
        x = W_width - (titleBarHeight * (#self.buttons + 1)),
        y = buttonSpacing,
        width = buttonSize,
        height = buttonSize,
        text = "×",
        action = function(self)
            --self.visible = false
            self:set_visible(false) --隐藏
        end
    })



    -- 最大化按钮
    table.insert(self.buttons, {
        x = W_width - (titleBarHeight * (#self.buttons + 1)),
        y = buttonSpacing,
        width = buttonSize,
        height = buttonSize,
        text = "□",
        action = function(self)
            if not self.isMaximized then
                self.originalX      = self.x
                self.originalY      = self.y
                self.originalWidth  = self.width
                self.originalHeight = self.height
                self.x              = 0
                self.y              = 0
                self.width          = love.graphics.getWidth()
                self.height         = love.graphics.getHeight()
                self.isMaximized    = true
            else
                self.x           = self.originalX
                self.y           = self.originalY
                self.width       = self.originalWidth
                self.height      = self.originalHeight
                self.isMaximized = false
            end
            return self:updateButtons()
        end
    })

    -- 最小化按钮
    table.insert(self.buttons, {
        x = W_width - (titleBarHeight * (#self.buttons + 1)),
        y = buttonSpacing,
        width = buttonSize,
        height = buttonSize,
        text = "−",
        action = function(self)
            self.isMinimized = not self.isMinimized
        end
    })
    --设置窗口可调整最小宽度
    self.min_width = #self.buttons * titleBarHeight
end

-- 更新按钮位置（当窗口大小改变时）
function window:updateButtons()
    local buttonSize    = 16
    local buttonSpacing = 4
    local rightOffset   = self.width - buttonSize - 8

    self.buttons[1].x   = rightOffset
    self.buttons[2].x   = rightOffset - buttonSize - buttonSpacing
    self.buttons[3].x   = rightOffset - (buttonSize + buttonSpacing) * 2

    -- 更新按钮的Y坐标（居中）
    for i, button in ipairs(self.buttons) do
        button.y = (self.titleBarHeight - buttonSize) / 2
    end
end

-- 检查鼠标是否在窗口内
function window:isMouseInWindow()
    local mx, my = love.mouse.getPosition()
    return mx >= self.x and mx <= self.x + self.width and
        my >= self.y and my <= self.y + self.height
end

-- 检查鼠标是否在标题栏内
function window:isMouseInTitleBar()
    local mx, my = love.mouse.getPosition()
    return mx >= self.x and mx <= self.x + self.width and
        my >= self.y and my <= self.y + self.titleBarHeight
end

-- 检查鼠标是否在调整大小区域
function window:isMouseInResizeArea()
    if not self.isResizable then return false end

    local mx, my = love.mouse.getPosition()
    local borderWidth = self.borderWidth

    return (mx >= self.x + self.width - borderWidth and mx <= self.x + self.width and
        my >= self.y + self.height - borderWidth and my <= self.y + self.height)
end

--处理鼠标点击事件
function window:mousepressed(id, x, y, dx, dy, istouch, pre)
    if not self.visible then return false end

    -- 检查是否点击了调整大小区域
    if self:isMouseInResizeArea() and not self.isMaximized then
        self.isResizing    = true
        self.resizeOffsetX = x - (self.x + self.width)
        self.resizeOffsetY = y - (self.y + self.height)
        return true
    end

    -- 检查是否点击了按钮
    for i, btn in ipairs(self.buttons) do
        if x >= self.x + btn.x and x <= self.x + btn.x + btn.width and
            y >= self.y + btn.y and y <= self.y + btn.y + btn.height then
            btn.action(self)
            return true
        end
    end

    -- 检查是否点击了标题栏（用于拖拽）
    if self:isMouseInTitleBar() and not self.isMaximized then
        self.is_title_Dragging = true
        self.dragOffsetX       = x - self.x
        self.dragOffsetY       = y - self.y
        return true
    end



    return false
end

-- 处理鼠标释放事件
function window:mousereleased(id, x, y, dx, dy, istouch, pre)
    self.is_title_Dragging = false
    self.isResizing = false
end

-- 处理鼠标移动事件
function window:mousemoved(id, x, y, dx, dy, istouch, pre)
    if not self.visible then return end

    -- 处理窗口调整大小
    if self.isResizing and not self.isMaximized then
        local newWidth = x - self.x - self.resizeOffsetX
        local newHeight = y - self.y - self.resizeOffsetY

        -- 限制最小窗口大小
        if newWidth >= self.min_width then
            self.width = newWidth
        end
        if newHeight >= self.min_height then
            self.height = newHeight
        end

        -- 更新按钮位置
        self:updateButtons()
        return --拦截拖动
    end

    -- 处理窗口拖拽
    if self.is_title_Dragging and not self.isMaximized then
        self.x = x - self.dragOffsetX
        self.y = y - self.dragOffsetY
    end
end

-- 设置窗口内容
function window:setContent(content)
    self.content = content or ""
end

-- 显示窗口
function window:show()
    self.visible = true
end

-- 隐藏窗口
function window:hide()
    self.visible = false
end

-- 切换窗口可见性
function window:toggle()
    self.visible = not self.visible
end

return window;
