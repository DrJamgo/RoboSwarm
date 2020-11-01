
HeightMap = class('HeightMap', VolumeRender)

local scale = {1,1,1/16}

function HeightMap:initialize(map)
    self.map = map
    self:refresh()
end

function HeightMap:update(dt)
    self:refresh()
end

function HeightMap:getDimensions()
    return self.volume:getWidth(), self.volume:getHeight(), self.volume:getDepth()
end

function HeightMap:refresh()
    local map = self.map

    self.volume = self.volume or love.graphics.newCanvas(map.width, map.height, 8, {type='volume'})
    --self.volume:setFilter('nearest', 'nearest')
    
    love.graphics.replaceTransform(love.math.newTransform())
    local maxz = 0
    for _,layer in ipairs(map.layers) do
        local imagedata = love.image.newImageData(map.width, map.height)
        for y, row in pairs(layer.data) do
            for x, tileinstance in pairs(row) do
                local type = tileinstance.type
                local h = ((layer.properties.z or 0) + (((type == 'full') and 1) or ((type == 'half' and 0.5)) or 0))
                local z = h * scale[3]
                imagedata:setPixel(x-1,y-1,z,z,z,1)
            end
        end
        local image = love.graphics.newImage(imagedata)
        image:setFilter('nearest', 'nearest')
        maxz = math.max(maxz, _)
        love.graphics.setCanvas(self.volume, _)
        love.graphics.clear(0,0,0,0)
        love.graphics.draw(image)
    end

    for i=maxz+1, self.volume:getDepth() do
        love.graphics.setCanvas(self.volume, i)
        love.graphics.clear(0,0,0,0)
    end
    love.graphics.setCanvas()
end

function HeightMap:draw()
    love.graphics.push()
    --love.graphics.draw(self.image, self.map.width/2, self.map.height/2, math.pi / 4, 1,1,self.map.width/2, self.map.height/2)
    love.graphics.scale(1,1)
    self:renderVolume(self.volume, 0, 0)
    love.graphics.pop()
end