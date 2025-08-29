local view = require "view.view"
local line_layout = view:new()
line_layout.__index = line_layout
function line_layout:new(x, y, width, height)
    --独有属性
    local instance = setmetatable({
        text            = "line_layout",
        textColor       = { 0, 0, 0, 1 },
        hoverColor      = { 0.8, 0.8, 1, 1 },
        pressedColor    = { 0.6, 1, 1, 1 },
        backgroundColor = { 0.6, 0.6, 1, 1 },
        borderColor     = { 0, 0, 0, 1 },
        orientation     = "horizontal", --horizontal,vertical--子视图布局方向
        gravity         = "top|left",   --子视图重力
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

function line_layout:draw()
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
    love.graphics.print(self.text, self.x, self.y)
end

--重写添加视图后回调
function line_layout:change_children_callback() --改变子视图数量后的回调 适用需要对子视图数量更新做出反应的视图
    --self:update_weiht()
    self:update_gravity()
end

function line_layout:string_segmentation(str, reps) --按指定间隔字符分割
    local resultStrList = {}
    string.gsub(str, '[^' .. reps .. ']+', function(w)
        --table.insert(resultStrList, w)
        resultStrList[w] = 0
    end)
    return resultStrList
end

function line_layout:gravity_string_analysis(str) --将字字符串转化为表
    -- body
    local str = string.lower(str)                 --将参数大写转为小写
    return self:string_segmentation(str, "|")
end

function line_layout:update_weiht()
    local ele = self.children --获取子视图
    --print(dump(ele))
    --[[
    if not rawget(self, "w") then --未重写宽
        --窗口宽高
        local dw, dh = love.window.getMode()
        self.w = dw
    end
    if not rawget(self, "h") then --未重写高
        --窗口宽高
        local dw, dh = love.window.getMode()
        self.h = dh;
    end]]
    --抽象了写法 可以自适应水平与垂直
    local abstract_value1 = "height"
    local abstract_value2 = "width"
    if self.orientation then --判断自身布局方向
        if self.orientation == "vertical" then
            abstract_value1 = "height"
            abstract_value2 = "width"
        end
        if self.orientation == "horizontal" then
            abstract_value1 = "width"
            abstract_value2 = "height"
        end
    end

    -- print(self.w, self.h)
    --print(abstract_value1)

    local weight = 0;    --整体权重
    --读取整体权重
    local all_buffer = 0 --子布局绝对宽/高度集合
    --先将子视图宽高储存起来
    for i, c in ipairs(ele) do
        --优先使用子布局的宽高
        -- print(c[abstract_value1])
        --print(i)
        if c.weight then --如果存在权重
            if c.weight ~= -1 and c.weight ~= 0 then
                assert(type(c.weight) == "number", "权重值必须是数字")
                weight = weight + c.weight;
            else
                -- weight = weight + 1;
            end
        else
            if c[abstract_value1] and c[abstract_value1] ~= -1 then
                all_buffer = all_buffer + c[abstract_value1] --储存到整体缓存
                -- print('weight' .. c.weight)
            end
        end
    end
    if weight == 0 then --没有权重 弹出
        return;
    end
    --print(weight, all_buffer)
    --剩余高度
    local fwh = self[abstract_value1] - all_buffer; --自身宽/高减去子元素的权重
    local cwh;                                      --权重均值
    if fwh > 0 then                                 --子布局的绝对宽高度是大于宽高
        --权重均分剩余高度
        cwh = math.floor(fwh / weight);             --1权重的高度
    else
        --权重均分额外高度 超出父布局部分
        cwh = math.floor(math.abs(fwh) / weight); --1权重的高度
    end
    --print(fwh, cwh)
    --分配权重
    for i, c in ipairs(ele) do
        if c[abstract_value1] and c[abstract_value1] ~= -1 then --拥有绝对宽高不参与权重分配
        else
            if c.weight and c.weight ~= -1 and c.weight ~= 0 then
                c[abstract_value1] = c.weight * cwh;
            else
                c[abstract_value1] = cwh;
            end
        end
        --print(c.w)
        if c[abstract_value2] then
            if c[abstract_value2] == -1 then
                c[abstract_value2] = self[abstract_value2]
            end
        else
            c[abstract_value2] = self[abstract_value2]
        end
    end


    --
end

function line_layout:update_gravity()
    local ele = self.children --获取子视图
    -- print(dump2(ele))
    -- print(dump(ele))
    --子视图坐标是相对父视图的
    if self.gravity and type(self.gravity) == "string" then
        local gravity_tab = self:gravity_string_analysis(self.gravity) --解析重力字符
        --print(dump(gravity_tab))
        --print(dump(gravity_tab))
        if gravity_tab.center then               --首先解析居中属性
            --将横坐标居中
            local max;                           --参考
            local dw, dh = love.window.getMode() --获取屏幕宽高
            local cx = self.w / 2                --父布局中心横坐标
            for i, child in ipairs(ele) do
                child.x = cx - child.w / 2
            end
            --将纵坐标居中
            local ch = 0;          --子布局高度和
            local cey = self.h / 2 --父布局中心纵坐标
            for i, child in ipairs(ele) do
                ch = ch + child.h
            end
            local sy = cey - ch / 2 --子布局初始高度
            if sy < self.y then     --强制控制首个子布局显示
                sy = self.y;
            end

            for i, child in ipairs(ele) do
                child.y = sy;
                sy = sy + child.h
            end
        end


        if gravity_tab.left then
            if self.orientation == "vertical" then
                for i, c in pairs(ele) do
                    --print(dump2(c))
                    -- print(i)
                    c.x = 0;
                end
            elseif self.orientation == "horizontal" then --top
                local sx = 0
                for i, c in pairs(ele) do
                    c.x = sx;
                    sx = sx + c.width
                end
            end
        end
        if gravity_tab.right then
            if self.orientation == "vertical" then
                for i, c in pairs(ele) do
                    c.x = self.width - c.width;
                end
            elseif self.orientation == "horizontal" then --bottom
                local cw = 0;                            --子布局高度和
                for i, c in pairs(ele) do
                    cw = cw + c.width
                end
                local sx = self.width - cw --子布局初始位置
                for i, c in pairs(ele) do
                    c.x = sx;
                    sx = sx + c.width
                end
            end
        end
        if gravity_tab.top then
            if self.orientation == "vertical" then
                local sy = 0
                for i, c in pairs(ele) do
                    c.y = sy;
                    sy = sy + c.height
                end
            elseif self.orientation == "horizontal" then --bottom
                for i, c in pairs(ele) do
                    c.y = 0;
                end
            end
        end
        if gravity_tab.bottom then
            if self.orientation == "vertical" then
                local ch = 0; --子布局高度和
                for i, c in pairs(ele) do
                    ch = ch + c.height
                end
                local sy = self.height - ch --子布局初始位置
                for i, c in pairs(ele) do
                    c.y = sy;
                    sy = sy + c.height
                end
            elseif self.orientation == "horizontal" then --bottom
                for i, c in pairs(ele) do
                    c.y = self.height - c.height;
                end
            end
        end
    else
        --assert(false,"重力解析错误:"..)
    end
end

function line_layout:on_click(id, x, y, dx, dy, istouch, pre)
    -- body
    --self:destroy()
    print(self:get_local_Position(x, y))
end

return line_layout;
