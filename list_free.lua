local view = require "view.view"
local list_free = view:new()
list_free.__index = list_free
function list_free:new(x, y, width, height, gravity)
    --独有属性
    local instance = setmetatable({
        contentHeight = 800,                  -- 内容总高度（大于容器高度）
        contentWidth = 800,                   -- 内容总宽度（大于容器高度）
        offsetY = 0,                          -- 当前滚动偏移量
        dragStartY = 0,                       -- 拖动起始位置
        offsetX = 0,                          -- 当前滚动偏移量
        dragStartX = 0,                       -- 拖动起始位置
        scrollSpeed = 10,                     -- 滚轮滑动速度
        isDragging = false,                   -- 拖动状态标记
        isPressed = false,                    --点击标志
        gap = 10,                             --元素间隔
        itemHeight = 20,                      --元素宽高
        hover_ele = nil,                      --焦点元素
        pressed_ele = nil,                    --点击元素
        text_size = 15,                       --文字大小
        bar_hw = 10,                          --滚动条宽高
        bar_max_time = 300,                   --滚动条自动隐藏延时
        bar_on_time = 0,                      --滚动条时间标识
        bar_visible = false,                  --滚动条显示标识
        hover_item = nil,                     --焦点子元素标签
        hoverColor = { 0.8, 0.8, 1, 1 },      --获取焦点颜色
        pressedColor = { 0.6, 1, 1, 0.8 },    --点击时颜色
        backgroundColor = { 0.6, 0.6, 1, 1 }, --背景颜色
        borderColor = { 0, 0, 0, 1 },         --边框颜色

        --
        x = x or 0,
        y = y or 0,
        width = width or 100,
        height = height or 50,
        children = {},  -- 子视图列表
        visible = true, --是否可见
        parent = nil,   --父视图
    }, self)
    instance.contentItems = {
        { text = "tex1" },
        { text = "text2" },
        { text = "text3" },
        { text = "text4" },
    } --子视图


    return instance
end

--多平台适配加载 迭代函数

if love.system.getOS() == "Windows" then --鼠标焦点支持
    function list_free:update(dt)
        --print(123)
        self.offsetY = math.max(0, math.min(
            self.offsetY,
            self.contentHeight - self.height
        ))
        self.offsetX = math.max(0, math.min(
            self.offsetX,
            self.contentWidth - self.width))
        if self.hover then --有焦点开始自动更新焦点item
            local x, y = love.mouse.getPosition()
            local x1, y1 = self:get_local_Position(x, y)
            if self.hover_ele then --存在焦点元素

            else                   --不存在焦点元素

            end
        end
        --自动滚动条更新时间
        if self.bar_visible then
            if self.bar_on_time >= 0 then
                self.bar_on_time = self.bar_on_time - (dt * 1000); --时间迭代
            else
                self.bar_visible = false;                          --隐藏滚动条
            end
        end
    end
elseif love.system.getOS() == "Android" then --多点触控支持
    function list_free:update(dt)
        --print(123)
        self.offsetY = math.max(0, math.min(
            self.offsetY,
            self.contentHeight - self.height
        ))

        --自动滚动条更新时间
        if self.bar_visible then
            if self.bar_on_time >= 0 then
                self.bar_on_time = self.bar_on_time - (dt * 1000); --时间迭代
            else
                self.bar_visible = false;                          --隐藏滚动条
            end
        end
    end
end


function list_free:draw()
    -- === 1. 绘制容器背景 ===
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill",
        self.x, self.y,
        self.width, self.height
    )
    love.graphics.setColor(self.borderColor)
 
    -- === 2. 启用剪裁区域（仅容器内可见） ===
    love.graphics.setScissor(self.x, self.y, self.width, self.height)
    --love.graphics.setColor(self.borderColor)
    -- === 3. 绘制内容（应用滑动偏移） ===
    for i, item in ipairs(self.contentItems) do
        -- 计算世界坐标（应用滚动偏移）
        local offsetX = self.x - self.offsetX
        local offsetY = self.y - self.offsetY
        local itemHeight = self.itemHeight --元素高度
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(item.text)
        local textHeight = font:getHeight()
        local y = offsetY + ((i - 1) * itemHeight)
       

        love.graphics.print(item.text, offsetX, y)

        love.graphics.setColor(self.backgroundColor)
        love.graphics.rectangle("fill", offsetX, y, textWidth, itemHeight, 5)
        love.graphics.setColor(self.borderColor)
        love.graphics.rectangle("line", offsetX, y, textWidth, itemHeight, 5)
         love.graphics.print(item.text, offsetX, y)
        --绘制分割线
        --[[
        love.graphics.setColor(0, 0, 0)
        love.graphics.line(self.x, itemY - self.gap / 2, self.x + item.width, itemY - self.gap / 2)
        local font = love.graphics.getFont()           -- 获取当前字体（默认字体或已设置的字体
        local text_width = tonumber(font:getWidth(item.text))
        local text_height = tonumber(font:getHeight()) -- 获取字体行高（单行高度）
        local text_x = (self.x + (item.width / 2)) - (text_width / 2)
        local text_y = (itemY + (item.height / 2)) - (text_height / 2)
        -- 显示text 居中显示
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(item.text, text_x, text_y)]]
    end

    -- === 4. 禁用剪裁区域 ===
    love.graphics.setScissor()

    -- === 5. 绘制UI辅助信息 ===
    love.graphics.setColor(self.borderColor)
    love.graphics.rectangle("line",
        self.x, self.y,
        self.width, self.height
    )

    -- 在draw函数中添加：--绘制滚动条
    if self.bar_visible then
        if self.height < self.contentHeight then
            local barHeight = self.height * (self.height / self.contentHeight)
            local barY = self.y + (self.offsetY / self.contentHeight) * self.height
            love.graphics.rectangle("fill", self.x + self.width - 10, barY, 8, barHeight)
        end
        if self.width < self.contentWidth then
            local barWidth = self.width * (self.width / self.contentWidth)
            local barX = self.x + (self.offsetX / self.contentWidth) * self.width
            love.graphics.rectangle("fill", barX, self.y + self.height - 10, barWidth, 8)
        end
    end
    -- 显示滚动提示
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Scroll  Offset: " .. math.floor(self.offsetY), self.x, self.y + self.height + 10)
    love.graphics.print("Drag  or use Mouse Wheel", self.x, self.y + self.height + 20)
end

function list_free:display_bar()
    self.bar_visible = true               --显示滚动条
    self.bar_on_time = self.bar_max_time; --赋值延时时间
end

function list_free:get_count(x1, y1)          --获取鼠标焦点元素
    local fact_y = y1 + self.offsetY
    local height = self.itemHeight + self.gap --元素真实高度
    return (fact_y - (fact_y % height)) / height + 1
end

function list_free:mousepressed(id, x, y, dx, dy, istouch, pre)
    -- 获取相对点击位置
    local x1, y1 = self:get_local_Position(x, y)
    --赋予元素点击颜色
    if self.hover_ele then                                  --存在焦点元素
        local items = self.contentItems                     --元素总表
        if items[self.hover_ele] then                       --焦点元素存在
            items[self.hover_ele].color = self.pressedColor --点击颜色
        end
    else                                                    --无焦点元素 点击判断                                                    --判断点击元素
        local items = self.contentItems                     --元素总表
        local count = self:get_count(x1, y1)                --获取焦点元素
        if items[count] then                                --元素存在
            --print(items[count])
            self.pressed_ele = count                        --点击元素赋值
            items[count].color = self.pressedColor          --点击颜色
            --print(dump(self.pressedColor))
        end
        --print(dump(items[count].color))
        --print(count)
    end

    self.dragStartY = y             --储存开始拖动位置
    self.startOffset = self.offsetY --点击位置储存
end

function list_free:mousemoved(id, x, y, dx, dy, istouch, pre)
    local x1, y1 = self:get_local_Position(x, y)
    if self.isPressed then --点击
        -- 根据鼠标移动距离更新滚动位置
        self.offsetY = self.offsetY - dy
        self.offsetX = self.offsetX - dx
        self:display_bar() --显示滚动条
    else                   --鼠标移动 不做响应式 做即时 逻辑移至update
    end
end

function list_free:off_hover(...)                              --失去焦点
    if self.hover_ele then                                     --存在焦点元素
        local items = self.contentItems                        --元素总表
        if items[self.hover_ele] then                          --焦点元素存在
            items[self.hover_ele].color = self.backgroundColor --取消焦点颜色
            self.hover_ele = nil                               --焦点赋值为空
        end
    end
end

function list_free:mousereleased(id, x, y, dx, dy, istouch, pre)
    local x1, y1 = self:get_local_Position(x, y)
    local count = self:get_count(x1, y1)                                           --获取焦点元素
    --抬起颜色赋值
    if self.hover_ele then                                                         --存在焦点元素
        local items = self.contentItems                                            --元素总表
        local count = self:get_count(x1, y1)                                       --获取焦点元素
        if self.hover_ele == count then                                            --还是此元素
            items[self.hover_ele].color = self.backgroundColor                     --抬起颜色赋值
        end
    elseif self.pressed_ele then                                                   --存在点击元素
        local items = self.contentItems                                            --元素总表
        if items[self.pressed_ele] then                                            --点击元素存在
            if not self.isDragging then                                            --没拖动执行点击回调
                self:item_on_click(self.pressed_ele, items[self.pressed_ele].text) --执行元素点击回调
            end
            items[self.pressed_ele].color = self.backgroundColor                   --取消点击颜色
            self.pressed_ele = nil                                                 --点击元素赋值为空
        end
        --print(1)
    end
    self.isDragging = false --拖动变量清空
end

function list_free:wheelmoved(id, x, y) --滚轮滑动
    self.offsetY = self.offsetY - y * self.scrollSpeed
    self:display_bar()                  --显示滚动条
end

function list_free:_on_click(id, x, y, dx, dy, istouch, pre) --拦截点击事件
    -- body
    local items = self.contentItems                          --元素总表
    local hover_ele = self.hover_ele
    if items[hover_ele] then                                 --元素存在执行回调
        return self:item_on_click(hover_ele, items[hover_ele].text)
    end
end

--重写回调
function list_free:change_hover(count, text) --鼠标滑动list_free时item获取焦点时的回调
    --print(count, text)
end

function list_free:item_on_click(count, text) --元素点击事件
    -- body
    --print(count, text)
end

return list_free;
