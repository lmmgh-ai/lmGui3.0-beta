local view = require "view.view"
local tree_menu = view:new()
tree_menu.__index = tree_menu
function tree_menu:new(x, y, width, height)
    local instance = setmetatable({
        --独有属性
        --创建的选项卡
        item            = require("tree_item"),
        children_item   = {}, --第一层选项卡
        items           = {}, --所有选项卡索引
        --view自带
        textColor       = { 0, 0, 0, 1 },
        hoverColor      = { 0.8, 0.8, 1, 1 },
        pressedColor    = { 0.6, 1, 1, 1 },
        backgroundColor = { 0.6, 0.6, 1, 1 },
        borderColor     = { 0, 0, 0, 1 },
        --
        x               = x or 0,
        y               = y or 0,
        width           = width or 100,
        height          = height or 100,
        children        = {},   -- 子视图列表
        visible         = true, --是否可见
        parent          = nil,  --父视图
        -- 回调函数，子类可以重写，也可以直接赋值
    }, self)

    return instance
end

function tree_menu:add_item(text) --根据菜单添加选项卡
    local item = self.items[text]
    if item then
        return item:new(text)
    else
        self.item:new(text or 'erro')
        return self.children_item[text]:new(text)
    end
end

function tree_menu:draw()
    for i, item in pairs(self.items) do
        self.first_item:draw(0, 0, 0)
    end
end

function tree_menu:mousepressed(id, x, y, dx, dy, istouch, pre)
    -- 获取相对点击位置
    local x1, y1 = self:get_local_Position(x, y)
end

function tree_menu:on_click(id, x, y, dx, dy, istouch, pre)
    -- body
    --self:destroy()
    print(self:get_local_Position(x, y))
end

return tree_menu;
