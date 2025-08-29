--管理器
--默认 帧布局
local gui = {
    x = 0,
    y = 0,
    width = 500,
    height = 500,
    views = setmetatable({}, { __mode = 'kv' }),                 --
    tree_views = { {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {} }, --按图层排序分布视图
    input_state = {
        layer = nil,                                             --焦点图层
        isPressed = false,                                       --点击
        pressed_views = {},                                      --选中的视图集合
        isMoved = false,                                         --滑动
        hover_view = nil,                                        --焦点视图
        keypressed_view = nil,                                   --键盘锁定视图(暂时用这一个标识 文字输入与键盘未区分)
        --input_text_view = nil,                                   --文字输入视图
    }
}



function gui:add_view(view) --添加视图
    local _layer = view._layer
    --view.parent = self
    local name = tostring(view) --以自己地址为唯一标识
    --
    view.gui = self;            --设置管理器索引
    --如果图层区域不存在
    if not gui.tree_views[_layer] then
        gui.tree_views[_layer] = {} --初始化图层
    end
    table.insert(self.tree_views[_layer], view)
    --图层1排序
    if _layer == 1 then
        --由小到大排序
        table.sort(self.tree_views[1], function(a, b)
            --print(a._layer, b._layer)
            return a._draw_order < b._draw_order
        end) --排序
    end
    --table.insert(self.views, view)
    --添加到整体区域
    self.views[name] = view;
    table.sort(self.views, function(a, b)
        --print(a._layer, b._layer)
        return a._layer < b._layer
    end) --排序
end

function gui:set_hover_view(view) --设置焦点视图 只对图层1视图生效
    --print(view._layer)
    if view._layer == 1 then
        local tree_views = self.tree_views[1] --图层1索引
        --绘图总比顶层的值大1
        local o2 = #tree_views - 1
        local t2 = tree_views[o2]

        view._draw_order = t2._draw_order + 1

        --图层1排序
        table.sort(tree_views, function(a, b)
            --print(a._layer, b._layer)
            return a._draw_order < b._draw_order
        end) --排序
        --print(view._draw_order, tree_views[#tree_views]._draw_order)
        -----事件传递相关
        local input_state = self.input_state      --事件状态表
        local hover_view = input_state.hover_view --焦点视图
        if hover_view then                        --焦点视图存在
            --执行失去焦点事件
            hover_view.hover = false              --焦点视图取消焦点
            hover_view:_off_hover()               --执行失去焦点回调
        end
        --重新赋值焦点视图
        input_state.hover_view = view;
        input_state.layer = view._layer; --设置焦点图层
        view:_on_hover()                 --执行获取焦点回调
    else
        -- print(1)
        assert(true, "设置焦点视图失败 视图图层不是图层1")
    end
end

function gui:load(...)
    -- body
end

function gui:update(dt)
    -- body
    for i, view in pairs(self.views) do
        --print(view.update)
        -- if rawget(view, "update") then
        if view.visible then
            view:update(dt)
        end
        -- end
    end
    --print("视图总量:" .. #self.views)
end

local draw = function(view)
    for i, view in pairs(view) do
        if view.visible then
            view:draw()
            draw(view.children)
        end
    end
end
function gui:draw(...)
    -- body
    --只扫描图层第1层
    for i, view in pairs(self.tree_views[1]) do
        if view.visible then
            view:_draw()
        end
    end
end

--输入


function gui.point_in_rect(x, y, rectX, rectY, width, height) --点是否在矩形内
    return x >= rectX
        and x <= rectX + width
        and y >= rectY
        and y <= rectY + height
end

--适配多平台输入
if love.system.getOS() == "Windows" then
    function gui:mousemoved(id, x, y, dx, dy, istouch, pre)
        local input_state = self.input_state
        local tree_views = self.tree_views;
        local layer = input_state.layer;                                        --焦点图层
        local hover_view = input_state.hover_view                               --焦点视图
        local pressed_views = input_state.pressed_views                         --选中的视图集合--鼠标模式选中的视图[1]
        if pressed_views[1] then                                                --鼠标模式选中视图存在 执行选中视图滑动回调
            return pressed_views[1]:_mousemoved(id, x, y, dx, dy, istouch, pre) --中断后续 执行滑动回调
        else
            if hover_view and layer then                                        --存在焦点视图 与焦点图层
                --print(hover_view, layer)
                --判断当前焦点视图是否失去焦点
                if hover_view:containsPoint(x, y) then                                      --单独判断焦点视图 视图还有焦点 扫描子视图
                    if hover_view.children then                                             --存在子视图
                        for i, view in pairs(hover_view.children) do                        --从焦点视图下一层向上迭代
                            if view.visible then                                            --如果视图可见                                                   --如果扫描视图可见                                                     --可见
                                if view:containsPoint(x, y) then                            --如果点在视图内
                                    hover_view.hover = false;                               --焦点视图取消焦点
                                    hover_view:_off_hover()                                 --失去焦点回调
                                    input_state.hover_view = view;                          --赋值焦点视图
                                    input_state.layer = view._layer;                        --赋值焦点图层
                                    view:_on_hover()                                        --中断后续 新的焦点视图执行获取焦点回调
                                    return view:_mousemoved(id, x, y, dx, dy, istouch, pre) --中断后续 执行滑动回调
                                end
                            end
                        end
                    end
                    --没有失去焦点继续执行滑动回调
                    return hover_view:_mousemoved(id, x, y, dx, dy, istouch, pre) --执行焦点视图回调
                else                                                              --视图失去焦点
                    hover_view.hover = false                                      --焦点视图取消焦点
                    hover_view:_off_hover()                                       --失去焦点回调
                    local layer = hover_view._layer                               --获取焦点视图的上一层

                    --扫描父视图
                    if hover_view.parent then
                        local view = hover_view.parent                                  --获取父视图
                        if view.visible then                                            --如果视图可见                                                   --如果扫描视图可见                                                     --可见
                            if view:containsPoint(x, y) then                            --如果点在视图内
                                input_state.hover_view = view;                          --赋值焦点视图
                                input_state.layer = view._layer;                        --赋值焦点图层
                                view:_on_hover()                                        --中断后续 新的焦点视图执行获取焦点回调
                                return view:_mousemoved(id, x, y, dx, dy, istouch, pre) --中断后续 执行滑动回调
                            end
                        end
                    end
                    input_state.hover_view = nil --取消焦点视图
                    --[[
            --扫描子视图
            if hover_view.children then                                             --存在子视图
                for i, view in pairs(hover_view.children) do                           --从焦点视图下一层向上迭代
                    if view.visible then                                            --如果视图可见                                                   --如果扫描视图可见                                                     --可见
                        if view:containsPoint(x, y) then                            --如果点在视图内
                            input_state.hover_view = view;                          --赋值焦点视图
                            input_state.layer = view._layer;                        --赋值焦点图层
                            return view:_mousemoved(id, x, y, dx, dy, istouch, pre) --中断后续 执行回调
                        end
                    end
                end
            end

            --扫描同图层
            local tree_views_chliden = tree_views[layer]                        --获取图层集合
            for i2 = #tree_views_chliden, 1, -1 do
                local view = tree_views_chliden[i2]                             --获取视图
                if view.visible then                                            --如果视图可见                                                   --如果扫描视图可见                                                     --可见
                    if view:containsPoint(x, y) then                            --如果点在视图内
                        input_state.hover_view = view;                          --赋值焦点视图
                        input_state.layer = view._layer;                        --赋值焦点图层
                        return view:_mousemoved(id, x, y, dx, dy, istouch, pre) --中断后续 执行回调
                    end
                end
            end]]
                end
            else --新的全控件顶层扫描 用于赋予视图焦点
                --  print(123)
                for i = #tree_views, 1, -1 do
                    local tree_views_chliden = tree_views[i] --图层
                    for i2 = #tree_views_chliden, 1, -1 do
                        local view = tree_views_chliden[i2]
                        if not hover_view then                                              --没有焦点视图才循环
                            if view.visible then                                            --如果视图可见                                                   --如果扫描视图可见                                                     --可见
                                if view:containsPoint(x, y) then                            --如果点在视图内
                                    input_state.hover_view = view;                          --赋值焦点视图
                                    input_state.layer = view._layer;                        --赋值焦点图层
                                    view:_on_hover()                                        --中断后续 新的焦点视图执行获取焦点回调
                                    return view:_mousemoved(id, x, y, dx, dy, istouch, pre) --中断后续 执行滑动回调
                                end
                            end
                        end
                    end
                end
            end
        end
        -- print(hover_view, layer)
    end

    function gui:mousepressed(id, x, y, dx, dy, istouch, pre)          --pre短时间按下次数 模拟双击
        local input_state = self.input_state
        local hover_view = input_state.hover_view                      --焦点视图
        local pressed_views = input_state.pressed_views                --选中的视图集合--鼠标模式选中的视图[1]
        if hover_view then                                             --鼠标模式焦点视图一定存在
            if hover_view:containsPoint(x, y) then                     --复检焦点视图点击
                pressed_views[1] = hover_view;                         --赋值选中视图
                --输入相关逻辑
                if input_state.keypressed_view then                    --输入视图是否存在
                    if hover_view ~= input_state.keypressed_view then  --输入函数失去选中
                        input_state.keypressed_view:loss_keypressed(); --执行失去输入权限回调
                        input_state.keypressed_view = hover_view;      --赋值输入视图
                    end
                else
                    input_state.keypressed_view = hover_view; --赋值输入视图
                end

                return hover_view:_mousepressed(id, x, y, nil, nil, istouch, pre) --回调
            end
        else                                                                      --无焦点视图且点击空白
            if input_state.keypressed_view then
                input_state.keypressed_view:loss_keypressed();                    --执行失去输入权限回调
                input_state.keypressed_view = nil;                                --赋值输入视图
            end
        end
    end

    function gui:mousereleased(id, x, y, dx, dy, istouch, pre)        --pre短时间按下次数 模拟双击
        local input_state = self.input_state
        local pressed_views = input_state.pressed_views               --选中的视图集合--鼠标模式选中的视图[1]
        local view = pressed_views[1]                                 --迭代选中视图集合
        if view then
            if view:containsPoint(x, y) then                          --释放按钮在选中视图中
                view:_on_click(id, x, y, dx, dy, istouch, pre)        --执行点击回调
                view:_mousereleased(id, x, y, nil, nil, istouch, pre) --回调
                view:off_hover(id, x, y, dx, dy, istouch, pre)        --失去焦点回调
            else
                view:_mousereleased(id, x, y, nil, nil, istouch, pre) --回调
                view:off_hover(id, x, y, dx, dy, istouch, pre)        --失去焦点回调
            end
        end
        input_state.pressed_views[1] = nil --鼠标模式选中视图赋值
    end

    function gui:wheelmoved(id, x, y)                   --滚轮滑动
        local input_state = self.input_state
        local hover_view = input_state.hover_view       --焦点视图
        local pressed_views = input_state.pressed_views --选中的视图集合--鼠标模式选中的视图[1]

        if hover_view and not pressed_views[1] then     --存在焦点视图 且鼠标未选中视图
            return hover_view:_wheelmoved(nil, x, y)
        end
    end
elseif love.system.getOS() == "Android" then --多点触控支持
    gui.input_state.touch_id = {}


    function gui.get_touch_id(id) --将触摸id转换为数子
        if (tostring(id) == "userdata: NULL") then
            return 1
        elseif (tostring(id) == "userdata: 0x00000001") then
            return 2
        elseif (tostring(id) == "userdata: 0x00000002") then
            return 3
        elseif (tostring(id) == "userdata: 0x00000003") then
            return 4
        elseif (tostring(id) == "userdata: 0x00000004") then
            return 5
        elseif (tostring(id) == "userdata: 0x00000005") then
            return 6
        elseif (tostring(id) == "userdata: 0x00000006") then
            return 7
        elseif (tostring(id) == "userdata: 0x00000007") then
            return 8
        end
        return 1;
    end

    --回调
    function gui:touchpressed(id, x, y, dx, dy, ispressure, pressure) --触摸按下
        local input_state = self.input_state
        local tree_views = self.tree_views;
        local hover_view = input_state.hover_view       --焦点视图
        local pressed_views = input_state.pressed_views --选中的视图集合--鼠标模式选中的视图[1]
        local id = self.get_touch_id(id)                --获取触摸id
        --顶层向下扫描视图
        for i = #tree_views, 1, -1 do
            local tree_views_chliden = tree_views[i] --图层
            for i2 = #tree_views_chliden, 1, -1 do
                local view = tree_views_chliden
                    [i2]                         --如果扫描视图可见                                                     --可见
                if view:containsPoint(x, y) then --如果点在视图内
                    pressed_views[id] = view;    --赋值触控id视图

                    --输入相关逻辑
                    if id == 1 then                                                 --只处理单指
                        if input_state.keypressed_view then                         --输入视图是否存在
                            if pressed_views[1] ~= input_state.keypressed_view then --输入函数失去选中
                                input_state.keypressed_view:loss_keypressed();      --执行失去输入权限回调
                                input_state.keypressed_view = pressed_views[1];     --赋值输入视图
                            end
                        else
                            input_state.keypressed_view = pressed_views[1]; --赋值输入视图
                        end
                    end

                    return view:_mousepressed(id, x, y, dx, dy, true, pre) --中断后续 执行获取焦点回调
                else                                                       --点击了空白
                    if input_state.keypressed_view then
                        input_state.keypressed_view:loss_keypressed();     --执行失去输入权限回调
                        input_state.keypressed_view = nil;                 --赋值输入视图
                    end
                end
            end
        end
    end

    function gui:touchmoved(id, x, y, dx, dy, ispressure, pressure)   --触摸滑动
        local input_state = self.input_state
        local pressed_views = input_state.pressed_views               --选中的视图集合--鼠标模式选中的视图[1]
        local id = self.get_touch_id(id)                              --获取触摸id
        if pressed_views[id] then                                     --如果触摸id视图存在
            local view = pressed_views[id]
            view.isDragging = true;                                   --视图拖动变量赋值
            return view:_mousemoved(id, x, y, dx, dy, true, pressure) --执行回调        ;
        end
    end

    function gui:touchreleased(id, x, y, dx, dy, ispressure, pressure) --触摸抬起
        local input_state = self.input_state
        local pressed_views = input_state.pressed_views                --选中的视图集合--鼠标模式选中的视图[1]
        local id = self.get_touch_id(id)                               --获取触摸id
        if pressed_views[id] then                                      --如果触摸id视图存在
            local view = pressed_views[id]
            if view then
                if view:containsPoint(x, y) then                                  --释放按钮在选中视图中
                    view:_on_click(id, x, y, dx, dy, ispressure, pressure)        --执行点击回调
                    view.hover = false                                            --清楚视图焦点
                    view:_mousereleased(id, x, y, nil, nil, ispressure, pressure) --回调
                    view:off_hover(id, x, y, dx, dy, ispressure, pressure)        --失去焦点回调
                else
                    view:_mousereleased(id, x, y, nil, nil, ispressure, pressure) --回调
                    view:off_hover(id, x, y, dx, dy, ispressure, pressure)        --失去焦点回调
                end
            end

            view.hover = false      --清楚视图焦点

            pressed_views[id] = nil --触摸id视图赋值为空
            return;
        end
    end
end

function gui:keypressed(key)                            --键盘点击事件
    --print(123)
    local input_state = self.input_state                --输入状态库
    local keypressed_view = input_state.keypressed_view --输入视图
    -- print(keypressed_view)
    if keypressed_view then
        keypressed_view:keypressed(key)
    end
end

function gui:textinput(text)                            --文字输入事件
    --print(123)
    local input_state = self.input_state                --输入状态库
    local keypressed_view = input_state.keypressed_view --输入视图
    -- print(keypressed_view)
    if keypressed_view then
        keypressed_view:textinput(text)
    end
end

return gui;
