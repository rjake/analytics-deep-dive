function Header(el)
  if (el.attr.classes:find("advanced")) then
    el.attr.attributes["visibility"] = "hidden"
    return el
  end
end
