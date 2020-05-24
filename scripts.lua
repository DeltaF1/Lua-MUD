local function load_scripts(obj)
  if not obj.scripts then return end
  for i = 1, #obj.scripts do
    local k = obj.scripts[i]

    local script = require("scripts."..k)

    for k,v in pairs(script) do
      obj[k] = v
    end
  end
end

return load_scripts
