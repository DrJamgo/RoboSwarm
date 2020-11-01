Body = class('Body', VolumeRender)

local R = 9
local M = (R -1) / 2
local volumelayers = {}
for z=0,R-1 do
    local slice = love.image.newImageData(R,R)
    for y = 0,R-1 do
        for x = 0,R-1 do
            local dist = math.sqrt(math.pow(x-M,2) + math.pow(y-M,2) + math.pow(z-M,2))
            slice:setPixel(x,y,1,1,1,1-dist/M)
        end
    end
    table.insert(volumelayers, slice)
end
local volumeimage = love.graphics.newVolumeImage(volumelayers, {linear=true})
volumeimage:setFilter('linear', 'linear')
volumeimage:setWrap('clampzero')
local vertices = {
    {0,0,0},
    {1,1,0},
    {1,-1,0},
    {-1,-1,0},
    {-1,1,0},
    {1,1,0},
}

local NUM_BODIES = 10

function Body:initialize(heightmap)
    self.heightmap = heightmap
    self.bodies = {}
    --
    --    | r | g | b | a |
    --    |---|---|---|---|
    --  0 | x | y | z | 1 |
    --
    self.bodiestex = love.graphics.newCanvas(NUM_BODIES, 1)
    self.bodiestex:setFilter('nearest', 'nearest')
    self:addBody(3,6,1,2)
    self:addBody(6,6,1,2)
    self:addBody(9,6,1,3)
    self.mesh = love.graphics.newMesh({{'VertexPosition', 'float', 3}}, vertices, 'fan')
end

function Body:_indexToUV(i)
    return (0.5 + i) * (1 / NUM_BODIES), 0.5
end

function Body:addBody(x,y,z,r)
    local wx,wy,wz = self.heightmap:getDimensions()
    local i = #self.bodies
    local u,v = self:_indexToUV(#self.bodies)
    self.bodiestex:renderTo(function()
        love.graphics.setColor(x/wx,y/wy,z/wz, 1)
        love.graphics.points(i,0.5)
    end)
    table.insert(self.bodies, {u})
end

local vertexcode = [[
    attribute float Index;
    uniform float uZ;
    varying vec3 vTexCoord;
    uniform Image bodiestex;
    uniform vec3 worldscale;

    vec4 position( mat4 transform_projection, vec4 vertex_position )
    {
        vec4 Body = vec4(Texel(bodiestex, vec2(Index,0)).xyz * worldscale, 2.5);
        vec3 pos = (vec3(vertex_position.xy, uZ) * Body.w) + vec3(Body.xy, Body.z);
        vTexCoord = vec3(vertex_position.xy / 2.1, (uZ-Body.z)/(Body.w*0.9)) + vec3(0.5,0.5,0.5);
        return transform_projection * vec4(pos, 1);
    }
]]

local pixelcode = [[
    uniform VolumeImage volumetex;
    varying vec3 vTexCoord;

    vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
    {
        vec4 texcolor = Texel(volumetex, vTexCoord);
        vec4 c = texcolor * color;
        return c;
    }
]]

local shader = love.graphics.newShader(pixelcode, vertexcode)
shader:send('volumetex', volumeimage)

function Body:update(dt)
    love.graphics.replaceTransform(love.math.newTransform())

    local bodiesMesh = love.graphics.newMesh({{"Index", "float", 1}}, self.bodies, nil, "static")
    self.mesh:attachAttribute('Index', bodiesMesh, 'perinstance')

    --
    -- VOLUME STAGE
    --
    local volume = self.heightmap.volume
    local depth = volume:getDepth()
    love.graphics.setShader(shader)
    love.graphics.setColor(1,1,1,1)
    shader:send('worldscale', {self.heightmap:getDimensions()})
    shader:send('bodiestex', self.bodiestex)
    for i = 1, depth, 1 do
        shader:send('uZ', i-1)
        love.graphics.setCanvas(volume, i)
        love.graphics.drawInstanced(self.mesh, #self.bodies)
    end

    --
    -- UPDATE STAGE
    --



    --
    -- RESET
    --
    love.graphics.setColor(1,1,1,1)
    love.graphics.setShader()
    love.graphics.setCanvas()
end

function Body:draw()
    love.graphics.push()
    love.graphics.replaceTransform(love.math.newTransform())
    love.graphics.draw(self.bodiestex,0,0,0,10,10)
    love.graphics.pop()
    --self:renderVolume(volumeimage, 1, 1)
end

