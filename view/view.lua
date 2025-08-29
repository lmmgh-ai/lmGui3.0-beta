-- 基础view类
view = {}
view.__index = view

-- 构造函数 这些属性 可以被继承
function view:new(x, y, width, height)
    local instance = setmetatable({
        x                = x or 0,
        y                = y or 0,
        width            = width or 0,
        height           = height or 0,
        children         = {},                   -- 子视图列表
        visible          = true,                 --是否可见
        hover            = false,                --是否获取焦点(鼠标悬浮在控件上 强制获取焦点)
        isPressed        = false,                --是否点击
        isDragging       = false,                --是否拖动(点击后的滑动)
        parent           = nil,                  --父视图
        name             = "",                   --以自己内存地址作为唯一标识
        id               = "",                   --自定义索引
        hoverColor       = { 0.8, 0.8, 1, 1 },   --获取焦点颜色
        pressedColor     = { 0.6, 0.6, 1, 0.8 }, --点击时颜色
        backgroundColor  = { 0.6, 0.6, 1, 1 },   --背景颜色
        borderColor      = { 0, 0, 0, 1 },       --边框颜色
        ---交互扩展
        --扩展虚拟宽高
        is_extension     = false, --是否扩展状态 点击视图判断使用扩展宽高判断
        extension_x      = 0,     --扩展的坐标
        extension_y      = 0,
        extension_width  = 0,
        extension_height = 0,
        _layer           = 1,   --图层
        _draw_order      = 1,   --默认根据 数值约大在当前图层约在前(目前视图在图层1起作用)
        gui              = nil, --管理器索引
        input_state      = {
            select = nil,       --选中的view;
            isPressed = false,  --点击
            isMoved = false,    --滑动
            hover_view = nil,
        }
    }, self)

    return instance
end

-- 设置位置
function view:setPosition(x, y)
    self.x = x
    self.y = y
end

-- 设置尺寸
function view:setSize(width, height)
    self.width  = width
    self.height = height
end

-- 添加子视图
function view:add_view(view)
    if view.parent then --如果存在父视图
        view:removeFromSuperview()
    end

    local gui = self.gui;
    --
    local name = tostring(view)    --以自己地址为唯一标识
    view.name = name;              --设置唯一标识
    --table.insert(self.children, view)
    self.children[name] = view;    --添加子视图集合(唯一id)
    view.parent = self;            --为chlid赋值父视图
    view._layer = self._layer + 1; --设置图层
    gui:add_view(view)             --添加到视图
    --调用子视图改变函数
    self:change_children_callback()
    return view
end

--改变子视图数量后的回调 适用需要对子视图数量更新做出反应的视图
function view:change_children_callback()
end

--设置视图可见
function view:set_visible(val)
    if val == true or val == false then
        self.visible = val;
        if self.children then --存在子视图
            for i, child in pairs(self.children) do
                child:set_visible(val)
            end
        end
    end
end

--销毁视图自身
function view:destroy()
    self:set_visible(false); --自身不可见
    local gui = self.gui;
    local name = self.name;
    gui.views[name] = nil --全体视图索引清空

    --清除图层索引
    for i, view in ipairs(gui.tree_views[self._layer]) do
        if view == self then
            view = nil
            break
        end
    end
    if self.parent then                      --存在父视图
        if self.parent.children then         --父视图存在子视图
            self.parent.children[name] = nil --取消索引
        end
    end
    if self.chliden then
        for i, chlid in pairs(self.chliden) do
            chlid:destroy() --调用子视图清除函数
        end
    end
    -- body
end

--将自身置顶 获取输入焦点 绘图顶层
function view:set_hover_view()
    if self.layer == 1 then --顶层图层
        return self.gui:set_hover_view(self)
    else
        self._draw_order = 2 --赋予绘图等级
        --排序
        table.sort(self.father.children, function(a, b)
            --print(a._layer, b._layer)
            return a._draw_order < b._draw_order
        end) --排序
    end
end

-- 从父视图中移除
function view:removeFromSuperview()
    if not self.parent then return end
    for i, v in ipairs(self.parent.children) do
        if v == self then
            table.remove(self.parent.children, i)
            self.parent = nil
            break
        end
    end
end

-- 移除所有子视图
function view:removeAllSubviews()
    for i = #self.children, 1, -1 do
        self.children[i]:removeFromSuperview()
    end
end

--迭代子类函数 非专业勿动
function view:_draw()
    if self.visible then
        self:draw()
        -- 绘制子视图
        --绘图偏移
        love.graphics.push()
        love.graphics.translate(self.x, self.y)
        for i, child in pairs(self.children) do
            --print(i)
            child:_draw()
        end
        love.graphics.pop()
    else
    end
end

function view.point_in_rect(x, y, rectX, rectY, width, height) --点是否在矩形内
    return x >= rectX
        and x <= rectX + width
        and y >= rectY
        and y <= rectY + height
end

--获取自身绝对位置
function view:getAbsolutePosition()
    local absX, absY = self.x, self.y
    local parent = self.parent

    while parent do
        absX = absX + parent.x
        absY = absY + parent.y
        parent = parent.parent
    end

    return absX, absY
end

--全局点转换相对点
function view:get_local_Position(x, y)
    local parent = self.parent
    local x1 = x - self.x
    local y1 = y - self.y
    if parent then
        return parent:get_local_Position(x1, y1)
    else
        return x1, y1;
    end
end

--相对点转换全局点
function view:get_world_Position(x, y)
    local parent = self.parent
    local x1 = x + self.x
    local y1 = y + self.y
    if parent then
        return parent:get_world_Position(x1, y1)
    else
        return x1, y1;
    end
end

-- 检测点全局点是否在视图内
function view:containsPoint(x, y)
    local absX, absY = self:get_world_Position(0, 0)
    return x >= absX and x <= absX + self.width and
        y >= absY and y <= absY + self.height
end

function view:_mousemoved(id, x, y, dx, dy, istouch, pre)
    --输入点转换相对输入点
    self.isDragging = true --拖动变量赋值
    return self:mousemoved(id, x, y, dx, dy, istouch, pre)
end

function view:_mousepressed(id, x, y, dx, dy, istouch, pre) --pre短时间按下次数 模拟双击
    self.isPressed = true                                   --点击变量赋值
    --输入点转换相对输入点
    return self:mousepressed(id, x, y, dx, dy, istouch, pre)
end

function view:_mousereleased(id, x, y, dx, dy, istouch, pre) --pre短时间按下次数 模拟双击
    self.isPressed = false                                   --点击变量赋值
    self:mousereleased(id, x, y, dx, dy, istouch, pre)       --释放回调
    self.isDragging = false                                  --拖动赋值
    --输入点转换相对输入点
end

function view:_wheelmoved(id, x, y) --滚轮滑动
    return self:wheelmoved(id, x, y)
end

function view:_on_hover(id, x, y, dx, dy, istouch, pre) --获取焦点回调
    --self:_mousemoved(id, x, y, dx, dy, istouch, pre)
    self.hover = true                                   --焦点变量赋值
    return self:on_hover()
end

function view:_off_hover() --失去焦点回调
    -- return self:_mousemoved(id, x, y, dx, dy, istouch, pre)
    self.hover = false     --焦点变量赋值
    return self:off_hover();
end

function view:_on_click(id, x, y, dx, dy, istouch, pre) --单击
    return self:on_click(id, x, y, dx, dy, istouch, pre);
end

--系统回调
function view:update(dt) --绘图函数
    -- body
end

function view:draw() -- 被操作时更新自己

end

function view:on_hover() --获取焦点回调

end

function view:off_hover() --失去焦点回调 在输入release回调之后

end

--输入回调 在获取[焦点][输入权限][锁定点击]
function view:mousemoved(id, x, y, dx, dy, istouch, pre) --滑动回调

end

function view:mousepressed(id, x, y, dx, dy, istouch, pre) --pre短时间按下次数 模拟双击

end

function view:mousereleased(id, x, y, dx, dy, istouch, pre) --pre短时间按下次数 模拟双击

end

function view:wheelmoved(id, x, y) --滚轮滑动
    -- body
end

function view:keypressed(key) --键盘按下回调

end

function view:loss_keypressed() --失去输入权限时执行回调

end

function view:textinput(text) --键盘输入文本回调

end

function view:on_click(id, x, y, dx, dy, istouch, pre) --单击
    --  print("点击", self)
    return true;
end

function view:on_long_click(self) --长按
    return true;
end

function view:on_double_click(self) --双击
    return true;
end

return view;
