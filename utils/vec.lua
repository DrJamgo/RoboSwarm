function vec2(x, y)
  return {x=x or 0, y=y or 0}
end

function vec2_add(v1, v2)
  return {x=v1.x+v2.x, y=v1.y+v2.y}
end

function vec2_sub(v1, v2)
  return {x=v1.x-v2.x, y=v1.y-v2.y}
end

function vec2_mul(v, s)
  return {x=v.x*s, y=v.y*s}
end

function vec2_dist(v1, v2)
  local diff = vec2_sub(v1, v2)
  return math.sqrt(diff.x*diff.x + diff.y*diff.y)
end

-- returns normalized vector and un-normalized length
function vec2_norm(v, l)
  local l = l or 1
  local length = math.sqrt(v.x*v.x + v.y*v.y)
  local vec = vec2_mul(v, ((length > 0) and (l / length)) or 1)
  return vec, length
end

function vec2_dot(v1, v2)
  return v2.x*v2.x + v1.y*v2.y
end

function vec2_proj(v, u)
  local _, u_len = vec2_norm(u)
  if u_len == 0 then
    return v
  end
  local a = vec2_dot(v,u) / (u_len*u_len)
  return {x=u.x * a, y=u.y * a}
end