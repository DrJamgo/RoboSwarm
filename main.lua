--
-- Copyright DrJamgo@hotmail.com 2020
--
love.filesystem.setRequirePath("?.lua;?/init.lua;lua/?.lua;lua/?/init.lua")

require 'utils/middleclass'

local STI = require 'sti/sti'

-- handle vscode and zerobrain debuggers
if arg[#arg] == "-debug" then
  if pcall(require, "lldebugger") then require("lldebugger").start() end
  if pcall(require, "mobdebug") then require("mobdebug").start() end
end

Game = {}

function love.load()
  Game.map = STI('map01.lua')
end

function love.update(dt)
  Game.map:update(dt)
end

function love.draw()
  Game.map:draw(0,0,2,2)

  love.graphics.replaceTransform(love.math.newTransform(0,0,0,2,2))
end

function love.keypressed( key, scancode, isrepeat )
  Game.count[key] = (Game.count[key] or 0) + 1
end