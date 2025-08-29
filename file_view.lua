local view = require "view.view"
local file_view = view:new()
file_view.__index = file_view
function file_view:new(path)
    --独有属性
    local instance = setmetatable({
        text            = "file_view",
        textColor       = { 0, 0, 0, 1 },
        hoverColor      = { 0.8, 0.8, 1, 1 },
        pressedColor    = { 0.6, 1, 1, 1 },
        backgroundColor = { 0.6, 0.6, 1, 1 },
        borderColor     = { 0, 0, 0, 1 },
        --
        currentDir      = "/",--love.filesystem.getSource() or "", -- 获取程序根目录
        files           = {},                                -- 当前目录文件列表
        directories     = {},                                -- 当前目录文件夹列表
        selectedItem    = nil,                               -- 当前选中项
        scroll          = 0,                                 -- 滚动位置
        itemHeight      = 30,                                -- 每项高度
        visibleItems    = 10,                                -- 可视项数量
        history         = {},                                -- 路径历史记录
        historyIndex    = 1,                                 -- 当前历史索引
        filter          = "*",                               -- 文件过滤类型
        x               = x or 0,
        y               = y or 0,
        width           = width or 400,
        height          = height or 400,
        children        = {},   -- 子视图列表
        visible         = true, --是否可见
        parent          = nil,  --父视图
        -- 回调函数，子类可以重写，也可以直接赋值
    }, self)

    return instance
end

-- 初始化文件管理器
function file_view:init()
    self:refreshDirectory()
    table.insert(self.history, self.currentDir) -- 添加到历史记录
end

-- 刷新当前目录内容
function file_view:refreshDirectory()
    self.files       = {}
    self.directories = {}

    -- 添加返回上级目录选项
    if self.currentDir ~= love.filesystem.getSource() then
        table.insert(self.directories, "[..]")
    end

    -- 获取目录列表
    local items = love.filesystem.getDirectoryItems(self.currentDir)
    for _, item in ipairs(items) do
        local path = self.currentDir .. "/" .. item
        if love.filesystem.getInfo(path).type == "directory" then
            table.insert(self.directories, "[" .. item .. "]")
        else
            -- 应用文件类型过滤
            if self.filter == "*" or item:match("%." .. self.filter .. "$") then
                table.insert(self.files, item)
            end
        end
    end

    -- 排序目录和文件
    table.sort(self.directories)
    table.sort(self.files)
end

-- 绘制文件管理器界面
function file_view:draw()
    -- 绘制窗口背景
    love.graphics.setColor(0.95, 0.95, 0.95)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

    -- 绘制窗口边框
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)

    -- 绘制标题栏
    love.graphics.setColor(0.2, 0.4, 0.8)
    love.graphics.rectangle("fill", self.x, self.y, self.width, 30)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(" 文件管理器", self.x + 10, self.y + 5)

    -- 绘制地址栏
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", self.x + 10, self.y + 40, self.width - 20, 25)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(self.currentDir, self.x + 15, self.y + 45)

    -- 绘制文件区域背景
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", self.x + 10, self.y + 80, self.width - 20,
        self.height - 120)

    -- 绘制文件和目录列表
    local startY = self.y + 85
    local totalItems = #self.directories + #self.files
    local visibleStart = math.max(0, math.min(self.scroll, totalItems - self.visibleItems))

    -- 绘制目录项（黄色）
    for i, dir in ipairs(self.directories) do
        if i > visibleStart and i <= visibleStart + self.visibleItems then
            local yPos = startY + (i - visibleStart - 1) * self.itemHeight
            self:drawItem(dir, yPos, i)
        end
    end

    -- 绘制文件项（白色）
    for i, file in ipairs(self.files) do
        local idx = #self.directories + i
        if idx > visibleStart and idx <= visibleStart + self.visibleItems then
            local yPos = startY + (idx - visibleStart - 1) * self.itemHeight
            self:drawItem(file, yPos, idx)
        end
    end

    -- 绘制操作按钮
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.rectangle("fill", self.x + 10, self.y + self.height - 35, 80, 25)
    love.graphics.rectangle("fill", self.x + self.width - 90, self.y + self.height - 35, 80,
        25)

    love.graphics.setColor(0, 0, 0)
    love.graphics.print(" 打开", self.x + 30, self.y + self.height - 30)
    love.graphics.print(" 取消", self.x + self.width - 70, self.y + self.height - 30)
end

-- 绘制单个文件/目录项
function file_view:drawItem(name, y, index)
    -- 高亮选中项
    if self.selectedItem == index then
        love.graphics.setColor(0.2, 0.5, 0.8, 0.5)
        love.graphics.rectangle("fill", self.x + 12, y, self.width - 24, self.itemHeight - 5)
    end

    -- 设置文本颜色（目录为橙色，文件为黑色）
    if name:sub(1, 1) == "[" then
        love.graphics.setColor(0.8, 0.5, 0) -- 目录颜色
    else
        love.graphics.setColor(0, 0, 0)     -- 文件颜色
    end

    love.graphics.print(name, self.x + 20, y + 5)
end

-- 处理鼠标点击
function file_view:mousemoved(id, x, y, dx, dy, istouch, pre)
    -- 检查是否在窗口内
    --if not self:isInWindow(x, y) then return false end
local x1, y1 = self:get_local_Position(x, y)
    -- 检查操作按钮点击
    if button == 1 then
        -- 打开按钮
        if x > self.x + 10 and x < self.x + 90 and
            y > self.y + self.height - 35 and y < self.y + self.height - 10 then
            if self.selectedItem then
                self:openSelected()
                return true
            end
        end

        -- 取消按钮
        if x > self.x + self.width - 90 and x < self.x + self.width - 10 and
            y > self.y + self.height - 35 and y < self.y + self.height - 10 then
            return "cancel"
        end
    end

    -- 检查文件区域点击
    if y > self.y + 80 and y < self.y + self.height - 40 then
        local itemIndex = math.floor((y - self.y - 85) / self.itemHeight) + self.scroll + 1
        local totalItems = #self.directories + #self.files

        if itemIndex <= totalItems then
            -- 双击检测
            local currentTime = love.timer.getTime()
            if self.selectedItem == itemIndex and currentTime - self.lastClickTime < self.doubleClickDelay then
                self:openItem(itemIndex)
            else
                self.selectedItem  = itemIndex
                self.lastClickTime = currentTime
            end
            return true
        end
    end

    return false
end

-- 打开选中项
function file_view:openSelected()
    if self.selectedItem then
        self:openItem(self.selectedItem)
    end
end

-- 打开指定索引的项
function file_view:openItem(index)
    if index <= #self.directories then
        -- 处理目录点击
        local dirName = self.directories[index]
        if dirName == "[..]" then
            -- 返回上级目录
            self:goBack()
        else
            -- 进入子目录
            local folderName = dirName:sub(2, -2) -- 去除方括号
            self:changeDirectory(self.currentDir .. "/" .. folderName)
        end
    else
        -- 处理文件选择
        local fileIndex = index - #self.directories
        local fileName = self.files[fileIndex]
        print("选中的文件: " .. self.currentDir .. "/" .. fileName)
        return self.currentDir .. "/" .. fileName
    end
end

-- 返回上级目录
function file_view:goBack()
    if self.historyIndex > 1 then
        self.historyIndex = self.historyIndex - 1
        self.currentDir   = self.history[self.historyIndex]
        self:refreshDirectory()
        self.selectedItem = nil
    end
end

-- 改变当前目录
function file_view:changeDirectory(path)
    self.currentDir = path
    self:refreshDirectory()
    self.selectedItem               = nil
    self.scroll                     = 0

    -- 添加历史记录
    self.historyIndex               = self.historyIndex + 1
    self.history[self.historyIndex] = path
end

-- 检查坐标是否在窗口内
function file_view:isInWindow(x, y)
    return x >= self.x and x <= self.x + self.width and
        y >= self.y and y <= self.y + self.height
end

function file_view:on_click(id, x, y, dx, dy, istouch, pre)
    -- body
    --self:destroy()
    print(self:get_local_Position(x, y))
end

return file_view;
