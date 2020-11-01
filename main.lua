--
-- Copyright DrJamgo@hotmail.com 2020
--
love.filesystem.setRequirePath("?.lua;?/init.lua;lua/?.lua;lua/?/init.lua")

local STI = require 'sti/sti'

-- handle vscode and zerobrain debuggers
if arg[#arg] == "-debug" then
  if pcall(require, "lldebugger") then require("lldebugger").start() end
  if pcall(require, "mobdebug") then require("mobdebug").start() end
end


require 'utils/middleclass'
require 'volumerender'
require 'heightmap'
require 'body'

Game = {
  time = 0
}

function love.load()
  Game.map = STI('iso_16x16.lua')
  Game.heightmap = HeightMap(Game.map)
  Game.body = Body(Game.map, Game.heightmap)
end

function love.update(dt)
  Game.time = love.timer.getTime()
  Game.map:update(dt)
  Game.heightmap:update(dt)
  Game.body:update(dt)
end

local fps = 30
local time = love.timer.getTime()

function love.draw()
  love.graphics.clear(0.1,0.1,0.3,1)
  Game.map:draw(200,0,2,2)
  local maptransform = love.math.newTransform(400,0,0,2,2)
  love.graphics.replaceTransform(maptransform)
  Game.cursor = nil
  if love.mouse.isDown(1) then
    Game.cursor = {Game.map:convertPixelToTile(maptransform:inverseTransformPoint(love.mouse.getPosition()))}
  end
  Game.body:draw()

  love.graphics.replaceTransform(love.math.newTransform())

  local diff = love.timer.getTime() - time
  time = love.timer.getTime()
  local a = 0.1
  fps = (1-a) * fps + a * (1/diff)
  love.graphics.printf(string.format('FPS: %.1f', fps), love.graphics.getWidth() - 100, 0, 100, 'right')
  if Game.cursor then
    love.graphics.printf(string.format('Cursor: %.2f.%.2f', unpack(Game.cursor)), love.graphics.getWidth() - 100, 50, 100, 'right')
  end

  -- DEBUG DRAWING
  local transform = love.math.newTransform(0,0,math.pi/4,200,200)
  local matrix = {transform:getMatrix()}
  matrix[4] = 100
  matrix[8] = 100
  matrix[6] = matrix[6] 
  matrix[5] = matrix[5]
  matrix[7] = -100
  transform:setMatrix(unpack(matrix))
  love.graphics.replaceTransform(transform)
  Game.heightmap:drawDebug()
  Game.body:drawDebug()
end

function love.keypressed( key, scancode, isrepeat )
  Game.count[key] = (Game.count[key] or 0) + 1
end