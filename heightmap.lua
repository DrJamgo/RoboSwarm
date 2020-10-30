
HeightMap = class('HeightMap')

local scale = {1,1,1/16}

function HeightMap:initialize(map)
    self.map = map
    self.imagedata = love.image.newImageData(map.width, map.height)
    self:refresh()
end

function HeightMap:refresh()
    local map = self.map
    local volumelayers = {}
    for _,layer in ipairs(map.layers) do
        local volumelayer = love.image.newImageData(map.width, map.height)
        for y, row in pairs(layer.data) do
            for x, tileinstance in pairs(row) do
                local type = tileinstance.type
                local h = ((layer.properties.z or 0) + (((type == 'full') and 1) or ((type == 'half' and 0.5)) or 0))
                local z = h * scale[3]
                self.imagedata:setPixel(x-1,y-1,z,z,z,1)
                volumelayer:setPixel(x-1,y-1,h,h,h,1)
            end
        end
        table.insert(volumelayers, volumelayer)
    end
    self.image = love.graphics.newImage(self.imagedata)
    self.image:setFilter('nearest', 'nearest')
    self.volumeimage = love.graphics.newVolumeImage(volumelayers, {linear=true})
    self.volumeimage:setFilter('nearest', 'nearest')
end

local vertexcode = [[
    uniform float slice;
    varying vec3 vTexCoord;

    vec4 position( mat4 transform_projection, vec4 vertex_position )
    {
        vTexCoord = vec3(vertex_position.xy, 0);
        return transform_projection * vec4(vertex_position.xy, slice, 1);
    }
]]

local pixelcode = [[
    uniform VolumeImage volumetex;
    uniform float slice;
    varying vec3 vTexCoord;

    vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
    {
        vec4 texcolor = Texel(volumetex, vec3(texture_coords,slice));
        return texcolor * color;
    }
]]

local vertices = {
    { 0, 0 , -- position of the vertex
      0, 0 },
    { 1, 0 ,
      1, 0 },
    { 1, 1 ,
      1, 1 },
    { 0, 1 ,
      0, 1 }
}

local mesh = love.graphics.newMesh(vertices, 'fan')
local debugshader = love.graphics.newShader(pixelcode, vertexcode)

function HeightMap:draw()
    love.graphics.push()
    love.graphics.scale(3)
    --love.graphics.draw(self.image, self.map.width/2, self.map.height/2, math.pi / 4, 1,1,self.map.width/2, self.map.height/2)
    love.graphics.setShader(debugshader)
    love.graphics.setColor(1,1,1,0.5)
    debugshader:send('volumetex', self.volumeimage)
    local depth = self.volumeimage:getDepth()
    for i = 1, depth do
        debugshader:send('slice', (i-1) / depth)
        love.graphics.draw(mesh)
    end
    love.graphics.setShader()
    love.graphics.setColor(1,1,1)
    love.graphics.pop()
end