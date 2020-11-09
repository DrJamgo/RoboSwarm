
HeightMap = class('HeightMap', VolumeRender)

local scale = {1,1,1/16}

function HeightMap:initialize(map)
    self.map = map
    self:refresh()
end

function HeightMap:update(dt)
    --self:refresh()
end

function HeightMap:getDimensions()
    return self.volume:getWidth(), self.volume:getHeight(), self.volume:getDepth() / 2
end

function HeightMap:refresh()
    local map = self.map

    self.volume = self.volume or love.graphics.newCanvas(map.width, map.height, 16, {type='volume'})
    --self.volume:setFilter('nearest', 'nearest')
    self.volume:setWrap('clamp')
    
    love.graphics.replaceTransform(love.math.newTransform())
    local maxz = 0
    for i,layer in ipairs(map.layers) do
        local imagedataH = love.image.newImageData(map.width, map.height)
        local imagedataF = love.image.newImageData(map.width, map.height)
        for y, row in pairs(layer.data) do
            for x, tileinstance in pairs(row) do
                local type = tileinstance.type
                local h = (((type == 'full') and 1) or ((type == 'half' and 0.5)) or 0)
                local z = ((layer.properties.z or 0) + h) * scale[3]
                if h > 0.0 then
                    imagedataH:setPixel(x-1,y-1,1,1,1,1)
                end
                if h > 0.5 then
                    imagedataF:setPixel(x-1,y-1,1,1,1,1)
                end
            end
        end
        local imageH = love.graphics.newImage(imagedataH)
        imageH:setFilter('nearest', 'nearest')
        love.graphics.setCanvas(self.volume, i*2)
        love.graphics.clear(0,0,0,0)
        love.graphics.draw(imageH)

        local imageF = love.graphics.newImage(imagedataF)
        imageF:setFilter('nearest', 'nearest')
        love.graphics.setCanvas(self.volume, i*2+1)
        love.graphics.clear(0,0,0,0)
        love.graphics.draw(imageF)

        maxz = math.max(maxz, i*2)
    end

    for i=maxz+1, self.volume:getDepth() do
        love.graphics.setCanvas(self.volume, i)
        love.graphics.clear(0,0,0,0)
    end
    love.graphics.setCanvas()
end

function HeightMap:drawDebug()
    love.graphics.push()
    --love.graphics.draw(self.image, self.map.width/2, self.map.height/2, math.pi / 4, 1,1,self.map.width/2, self.map.height/2)
    love.graphics.scale(1,1)
    self:renderVolume(self.volume, 0, 0)
    love.graphics.pop()
end