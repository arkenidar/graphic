
function sign(x)
  if x == 0 then
    return 0
  elseif x > 0 then
    return 1
  else
    return -1
  end
end

function side(px, p1, p2)
  return sign((p2.x - p1.x) * (px.y - p1.y) - (p2.y - p1.y) * (px.x - p1.x))
end

function ring_index(index, size)
  if index <= size then
    if index < 1 then
      return index+size
    else
      return index
    end
  else
    return index-size
  end
end

-- x,y: a given point, polygon: a polygon (list of points)
function in_convex_polygon(x, y, polygon)

  -- minimum of 3 vertices
  -- minimo 3 vertici oppure considerato punto esterno.
  if #polygon < 3 then return false end

  local point = {x=x,y=y}
  for i = 1, #polygon do
    local i1,i2
    i1 = ring_index(i, #polygon)
    i2 = ring_index(i + 1, #polygon)
    if side(point, polygon[i1], polygon[i2]) > 0 then
      return false
    end
  end

  return true

end
