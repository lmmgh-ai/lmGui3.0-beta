local view = require "view.view"
local select_button = view:new()
select_button.__index = select_button
function select_button:new(x, y, width, height)
    --独有属性
    local instance = setmetatable({
        text            = "select_button",
        textColor       = { 0, 0, 0, 1 },
        hoverColor      = { 0.8, 0.8, 1, 1 },
        pressedColor    = { 0.6, 1, 1, 1 },
        backgroundColor = { 0.6, 0.6, 1, 1 },
        borderColor     = { 0, 0, 0, 1 },
        radius          = 8,      -- 圆形按钮半径
        label           = "text", -- 标签文本
        itemHeight      = 30,     --元素高度
        gap             = 5,      --优化间隔
        selects         = {
            { label = "label", is_select = false },
            { label = "label", is_select = false },
            { label = "label", is_select = false },
            { label = "label", is_select = false },

        },                  --标签集合
        out_selects     = { --输出标签
            --label = false,
        },
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
    instance:update_item() --更新宽高
    return instance
end

function select_button:add_label(label) --添加标签
    if type(label) == "string" then
        table.insert(self.selects, { label = label, is_select = false })
        self.out_selects[label] = false
    elseif type(label) == "table" then
    end
end

function select_button:update_item() --增加新选项调整控件宽高
    self.height = #self.selects * self.itemHeight
    local max_text_width = 0
    local font = love.graphics.getFont() --获取当前字体

    for i, c in ipairs(self.selects) do
        if max_text_width ~= 0 then
            if tonumber(font:getWidth(c.label)) >= max_text_width then
                max_text_width = tonumber(font:getWidth(c.label))
            end
        else
            max_text_width = tonumber(font:getWidth(c.label))
        end
    end
    self.width = self.itemHeight + max_text_width + self.gap * 3
end

function select_button:draw()
    if not self.visible then return end


    love.graphics.setColor(self.backgroundColor)
    -- 绘制背景
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 1)
    love.graphics.setColor(self.borderColor)
    -- 绘制边框
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 1)

    if self.isPressed then
        love.graphics.setColor(self.pressedColor)
    elseif self.hover then
        love.graphics.setColor(self.hoverColor)
    else
        love.graphics.setColor(self.backgroundColor)
    end

    -- 设置线条宽度
    --love.graphics.setLineWidth(2)
    for i, sel in pairs(self.selects) do
        local itemHeight = self.itemHeight  --元素高度
        local gap = self.gap
        local radius = itemHeight / 2 - gap --宽高

        -- 绘制外圆
        local x = 0
        local y = ((i * itemHeight) - itemHeight)
        local rx = x + itemHeight / 2
        local ry = y + itemHeight / 2
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(sel.label)
        local textHeight = font:getHeight()
        local lx = itemHeight + gap * 2
        local ly = ry - textHeight / 2
        if sel.is_select then
            -- 如果被选中，绘制实心圆
            love.graphics.setColor(0.2, 0.6, 1) -- 蓝色
            love.graphics.circle("fill", rx, ry, radius)
            love.graphics.setColor(1, 1, 1)     -- 白色边框
            love.graphics.circle("line", rx, ry, radius)
        else
            -- 如果未被选中，绘制空心圆
            love.graphics.setColor(0.8, 0.8, 0.8) -- 灰色
            love.graphics.circle("line", rx, ry, radius)
            --love.graphics.rectangle("line", x, y, itemHeight, itemHeight, 5)
        end
        love.graphics.print(sel.label, lx, ly)
    end
end

function select_button:get_count(x1, y1) --获取鼠标焦点元素
    local fact_y = y1
    local height = self.itemHeight       --元素真实高度
    return (fact_y - (fact_y % height)) / height + 1
end

function select_button:on_click(id, x, y, dx, dy, istouch, pre)
    -- body
    --self:destroy()
    local x1, y1 = self:get_local_Position(x, y) --获取局部点
    local count = self:get_count(x1, y1)         --判断项
    local sel = self.selects[count]
    local out_selects = self.out_selects         --输出项
    if sel then                                  --判断项存在
        if sel.is_select then
            sel.is_select = false
            out_selects[sel.label] = false
        else
            sel.is_select = true
            out_selects[sel.label] = true
        end
        return self:change_state(self.out_selects) --执行回调
    else
        assert(true, "select_button 错误")
    end

    --print(self:get_local_Position(x, y))
end

function select_button:get_select(lable) --根据标签获取状态
    return self.out_selects[lable];
end

function select_button:get_selects() --获取所有选中标签
    return self.out_selects;
end

----------------回调
function select_button:change_state(out_selects) --状态被改变时调用函数
    --selects
    --如何索引状态 sellects.label
    --否定状态 nil or false
end

return select_button;
