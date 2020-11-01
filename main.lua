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

Game = {}

function love.load()
  Game.map = STI('iso_16x16.lua')
  Game.heightmap = HeightMap(Game.map)
  Game.body = Body(Game.heightmap)
end

function love.update(dt)
  Game.map:update(dt)
  Game.heightmap:update(dt)
  Game.body:update(dt)
end

function love.draw()
  love.graphics.clear(0.1,0.1,0.3,1)
  Game.map:draw(200,0,2,2)
  love.graphics.replaceTransform(love.math.newTransform(200,0,0,2,2))

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

  Game.heightmap:draw()
  Game.body:draw()
end

function love.keypressed( key, scancode, isrepeat )
  Game.count[key] = (Game.count[key] or 0) + 1
end