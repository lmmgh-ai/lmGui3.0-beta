function dump(a_obj)
  local getIndent, quoteStr, wrapKey, wrapVal, dumpObj
  getIndent = function(level)
    return string.rep("\t", level)
  end
  quoteStr = function(str)
    return '"' .. string.gsub(str, '"', '\\"') .. '"'
  end
   wrapKey = function(val)
    if type(val) == "number" then
      return "[" .. val .. "]"
     elseif type(val) == "string" then
      return "[" .. quoteStr(val) .. "]"
     else
      return "[" .. tostring(val) .. "]"
    end
  end
  wrapVal = function(val, level)
    if type(val) == "table" then
      return dumpObj(val, level)
     elseif type(val) == "number" then
      return val
     elseif type(val) == "string" then
      return quoteStr(val)
     else
      return tostring(val)
    end
  end
  dumpObj = function(obj, level)
    if type(obj) ~= "table" then
      return wrapVal(obj)
    end
    level = level + 1
    local tokens = {}
    tokens[#tokens + 1] = "{"
  for k, v in pairs(obj) do
      tokens[#tokens + 1] =
      getIndent(level) ..
      wrapKey(k) .. " = " .. wrapVal(v, level) .. ","
    end
    tokens[#tokens + 1] = getIndent(level - 1) .. "}"
    return table.concat(tokens, "\n")
  end
  return dumpObj(a_obj, 0)
end


 function dump2(t, options)
    -- 默认配置 
    options = options or {}
    local max_depth = options.max_depth  or 100  -- 递归深度限制
    local indent_str = options.indent  or "  "   -- 缩进字符 
    local newline = options.pretty  and "\n" or "" -- 美化模式换行
    
    -- 记录已处理表的字典 (table -> id)
    local seen = {}
    local id_counter = 1  -- 表唯一ID计数器 
    
    -- 递归序列化核心函数 
    local function _serialize(obj, depth, current_indent)
        -- 深度超限保护 
        if depth > max_depth then 
            return "'<max_depth exceeded>'"
        end 
        
        local t_type = type(obj)
        
        -- 基础类型处理 
        if t_type == "nil" then 
            return "nil"
        elseif t_type == "boolean" or t_type == "number" then
            return tostring(obj)
        elseif t_type == "string" then
            return string.format("%q",  obj)  -- 自动转义特殊字符
        end 
        
        -- 非表类型处理 (函数/userdata/线程等)
        if t_type ~= "table" then
            return string.format("'<%s:  %s>'", t_type, tostring(obj))
        end
        
        -- 循环引用检测 
        if seen[obj] then 
            return string.format("'<cycle_ref:%d>'",  seen[obj])
        end 
        
        -- 为新表注册ID
        seen[obj] = id_counter 
        id_counter = id_counter + 1 
        
        local next_indent = current_indent .. indent_str
        local parts = {"{"}
        
        -- 标记表ID (调试用)
        if options.show_id  then 
            table.insert(parts,  "--[[id:"..seen[obj].."]]")
            if options.pretty  then table.insert(parts,  newline) end
        end 
        
        -- 序列化数组部分 (连续整数索引)
        local array_index = 1
        while obj[array_index] ~= nil do
            local elem = _serialize(obj[array_index], depth + 1, next_indent)
            local line = current_indent..indent_str..elem..","
            if options.pretty  then line = line .. newline end
            table.insert(parts,  line)
            array_index = array_index + 1
        end 
        
        -- 序列化键值对部分 
        for key, value in pairs(obj) do
            -- 跳过已处理的数组元素 
            if type(key) ~= "number" or key < 1 or key >= array_index or math.floor(key)  ~= key then 
                local serialized_key 
                local serialized_val = _serialize(value, depth + 1, next_indent)
                
                -- 优化合法Lua标识符的显示 
                if type(key) == "string" and string.match(key,  "^[%a_][%w_]*$") then 
                    serialized_key = key
                else 
                    serialized_key = "[".._serialize(key, depth + 1, next_indent).."]"
                end
                
                local line = current_indent..indent_str..serialized_key.." = "..serialized_val..","
                if options.pretty  then line = line .. newline end
                table.insert(parts,  line)
            end 
        end
        
        table.insert(parts,  current_indent .. "}")
        return table.concat(parts,  options.pretty  and newline or " ")
    end
    
    return _serialize(t, 1, options.pretty  and "\n" or "")
end