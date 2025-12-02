debugger = nil

debugger = {
    data = {
        [1] = { color = { 0, 200, 255}, prefix = "[INFO]" },
        [2] = { color = { 255, 200, 0 }, prefix = "[WARNING]" },
        [3] = { color = { 255, 50, 50 }, prefix = "[ERROR]" }
    },

    prepareString = function(msg, level)
        local data = debugger.data[level]

        if not data then
            return msg
        end
        
        local r, g, b = unpack(data.color)
        
        return data.prefix .. " " .. msg, 0, r, g, b
    end
}