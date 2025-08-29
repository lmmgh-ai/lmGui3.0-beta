local item = {
    text = text or "",         -- 菜单项显示文本
    action = action or nil,    -- 点击时执行的动作函数
    children = children or {}, -- 子菜单项列表
    isExpanded = false,        -- 是否展开
    x = 0,                     -- X坐标
    y = 0,                     -- Y坐标
    width = 200,               -- 宽度
    height = 30,               -- 高度
    isHovered = false          -- 是否被鼠标悬停
}

--选项卡继承
tree_item = {}
tree_item.__index = tree_item

-- 创建新的菜单项
function tree_item:new(text, children, action)
    local item = {
        text = text or "",         -- 菜单项显示文本
        action = action or nil,    -- 点击时执行的动作函数
        children = children or {}, -- 子菜单项列表
        isExpanded = false,        -- 是否展开
        x = 0,                     -- X坐标
        y = 0,                     -- Y坐标
        width = 200,               -- 宽度
        height = 30,               -- 高度
        isHovered = false          -- 是否被鼠标悬停
    }
    setmetatable(item, tree_item)
    return item
end

-- 添加子菜单项
function tree_item:addChild(child)
    table.insert(self.children, child)
end

-- 切换展开/折叠状态
function tree_item:toggle()
    self.isExpanded = not self.isExpanded
end

-- 检查点是否在菜单项区域内
function tree_item:isPointInside(x, y)
    return x >= self.x and x <= self.x + self.width and
        y >= self.y and y <= self.y + self.height
end

-- 处理鼠标点击事件
function tree_item:onClick(x, y)
    -- 如果点击在当前菜单项上
    if self:isPointInside(x, y) then
        -- 如果有子菜单，则切换展开状态
        if #self.children > 0 then
            self:toggle()
        else
            -- 如果没有子菜单且有动作函数，则执行
            if self.action then
                self.action()
            end
        end
        return true
    end

    -- 如果菜单项是展开的，检查子菜单
    if self.isExpanded then
        for _, child in ipairs(self.children) do
            if child:onClick(x, y) then
                return true
            end
        end
    end

    return false
end

-- 更新鼠标悬停状态
function tree_item:onMouseMove(x, y)
    self.isHovered = self:isPointInside(x, y)

    -- 更新子菜单的悬停状态
    for _, child in ipairs(self.children) do
        child:onMouseMove(x, y)
    end
end

-- 绘制菜单项
function tree_item:draw(offsetX, offsetY, level)
    -- 设置当前菜单项的位置
    self.x = offsetX + level * 20 -- 每级缩进20像素
    self.y = offsetY

    -- 根据悬停状态设置颜色
    if self.isHovered then
        love.graphics.setColor(0.7, 0.7, 1, 1)   -- 悬停时的背景色
    else
        love.graphics.setColor(0.9, 0.9, 0.9, 1) -- 正常背景色
    end

    -- 绘制菜单项背景
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

    -- 绘制边框
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)

    -- 绘制文本
    love.graphics.setColor(0, 0, 0, 1) -- 黑色文字
    love.graphics.print(self.text, self.x + 10, self.y + 8)

    -- 如果有子菜单，绘制展开/折叠指示器
    if #self.children > 0 then
        if self.isExpanded then
            love.graphics.print("-", self.x + self.width - 20, self.y + 8)
        else
            love.graphics.print("+", self.x + self.width - 20, self.y + 8)
        end
    end

    -- 更新偏移量用于下一个菜单项
    local newOffsetY = offsetY + self.height

    -- 如果菜单项是展开的，绘制子菜单
    if self.isExpanded then
        for _, child in ipairs(self.children) do
            newOffsetY = child:draw(offsetX, newOffsetY, level + 1)
        end
    end

    return newOffsetY
end

-- 获取菜单项总高度（包括展开的子菜单）
function tree_item:getTotalHeight()
    local height = self.height

    if self.isExpanded then
        for _, child in ipairs(self.children) do
            height = height + child:getTotalHeight()
        end
    end

    return height
end

-----------------------------------------------
return tree_item;
