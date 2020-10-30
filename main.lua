--
-- Copyright DrJamgo@hotmail.com 2020
--
love.filesystem.setRequirePath("?.lua;?/init.lua;lua/?.lua;lua/?/init.lua")

require 'utils/middleclass'
require 'heightmap'
require 'body'

local STI = require 'sti/sti'

-- handle vscode and zerobrain debuggers
if arg[#arg] == "-debug" then
  if pcall(require, "lldebugger") then require("lldebugger").start() end
  if pcall(require, "mobdebug") then require("mobdebug").start() end
end

Game = {}

function love.load()
  Game.map = STI('iso_16x16.lua')
  Game.heightmap = HeightMap(Game.map)
end

function love.update(dt)
  Game.map:update(dt)
end

function love.draw()
  love.graphics.clear(0.1,0.1,0.1,1.0)
  Game.map:draw(40,0,3,3)
  love.graphics.replaceTransform(love.math.newTransform(40,0,0,3,3))

  -- DEBUG DRAWING
  local transform = love.math.newTransform(0,0,math.pi/4,100,100)
  local matrix = {transform:getMatrix()}
  matrix[4] = 150
  matrix[8] = 0
  matrix[6] = matrix[6] / 1.4
  matrix[5] = matrix[5] / 1.4
  matrix[7] = -50
  
  transform:setMatrix(unpack(matrix))
  love.graphics.replaceTransform(transform)

  Game.heightmap:draw()
end

function love.keypressed( key, scancode, isrepeat )
  Game.count[key] = (Game.count[key] or 0) + 1
end