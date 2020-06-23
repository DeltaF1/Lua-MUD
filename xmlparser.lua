local xml2lua = require "xml2lua"

local domHandler = require "xmlhandler.dom"
local treeHandler = require "xmlhandler.tree"

local function text2dom(text)
  local hand = domHandler:new()
  local parser = xml2lua.parser(hand)
  parser:parse(text)
  return hand.root
end

local function text2table(text)
  local hand = treeHandler:new()
  local parser = xml2lua.parser(hand)
  parser:parse(text)
  return hand.root
end

local function dom2table(dom)
  if dom._type == "TEXT" then
    return {text=dom._text}
  end
  
  local t = {}
  if #dom._children == 1 then
    t[dom._name] = dom2table(dom._children[1]) 
  else
    t[dom._name] = {}
    for i, child in ipairs(dom._children) do
      if child._type == "ELEMENT" then
        t[dom._name][child._name] = dom2table(child)[child._name]
        t[dom._name][child._name]._attr = child._attr 
      end
    end
  end
  return t
end

local function stripTags(text)
  local hand = {
    text = function (self, txt)
      self.txt = self.txt .. txt
    end,
    endtag = function() end,
    txt = "",
  }
  local parser = xml2lua.parser(hand)
  parser.options.stripWS = nil
  parser:parse(text)
  return hand.txt
end

local function wrapText(text, tagName, attrs)
  attrText = ""
  if attrs then
    for k,v in pairs(attrs) do
      attrText = attrText.." "..k.."="..'"'..tostring(v)..'"'
    end
  end
  return "<"..tagName..attrText..">"..text.."</"..tagName..">"
end

return {text2dom=text2dom, text2table=text2table, stripTags=stripTags, wrapText=wrapText, dom2table=dom2table}
