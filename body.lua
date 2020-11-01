Body = class('Body', VolumeRender)

local R = 9
local M = (R -1) / 2
local volumelayers = {}
for z=0,R-1 do
    local slice = love.image.newImageData(R,R)
    for y = 0,R-1 do
        for x = 0,R-1 do
            local dist = math.sqrt(math.pow(x-M,2) + math.pow(y-M,2) + math.pow(z-M,2))
            local a = 1 - math.pow(dist/M, 1)
            slice:setPixel(x,y,1,1,1,a+0.1)
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

local NUM_BODIES = 100
local BODIES_TEX_FORMAT = 'rgba16f'

function Body:initialize(map, heightmap)
    self.map = map
    self.heightmap = heightmap
    self.bodies = {}
    --
    --    | r | g | b | a |
    --    |---|---|---|---|
    --  0 | x | y | z | 1 |
    --
    self.bodiestex = love.graphics.newCanvas(NUM_BODIES, 1, {format=BODIES_TEX_FORMAT})
    self.bodiestex:setFilter('nearest', 'nearest')
    self.mesh = love.graphics.newMesh({{'VertexPosition', 'float', 3}}, vertices, 'fan')
    local wx,wy,wz = self.heightmap:getDimensions()
    self.dynamic = love.graphics.newCanvas(wx,wy,wz, {type='volume'})

    for i = 1, NUM_BODIES do
        self:addBody(math.random(wx-4)+2,math.random(wy-4)+2,math.random(wz-3)+3,2)
    end

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
        vec4 Body = vec4(Texel(bodiestex, vec2(Index,0)).xyz * worldscale, 2);
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

local volumeshader = love.graphics.newShader(pixelcode, vertexcode)
volumeshader:send('volumetex', volumeimage)


local updatevertexcode = [[
    vec4 position( mat4 transform_projection, vec4 vertex_position )
    {
        return transform_projection * vertex_position;
    }
]]

local updatepixelcode = [[
    uniform float dt;
    uniform VolumeImage staticVolume;
    uniform VolumeImage dynamicVolume;
    uniform vec3 worldscale;
    uniform vec4 cursor;

    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
    {
        vec4 Body = Texel(tex, texture_coords);
        vec3 vector = vec3(0,0,0);
        int count = 3*3*3-1;
        for(int z = -1; z <= 1; z+=1) {
            for(int y = -1; y <= 1; y+=1) {
                for(int x = -1; x <= 1; x+=1) {
                    if(x != 0 && y != 0 && z != 0) {
                        vec3 diff = vec3(x,y,z) * 0.5;
                        vec3 uvw = Body.xyz + diff / worldscale;
                        float s = Texel(staticVolume, uvw).a;
                        float d = Texel(dynamicVolume, uvw).a;
                        vector += diff * (s+d) / count;
                    }
                }
            }
        }
        float c = 0.5;
        vec3 target = cursor.xyz;
        vec3 diff = target - Body.xyz;
        Body.xyz += clamp(cursor.a * diff , vec3(-c,-c,-c), vec3(c,c,c)) * dt;
        Body.xyz += - vector * dt * 50;
        Body.z = Body.z - dt * 5 / worldscale.z;
        Body.xyz = clamp(Body.xyz, vec3(0,0,0), vec3(1,1,1));
        return Body;
    }
]]

local updateshader = love.graphics.newShader(updatepixelcode, updatevertexcode)

function Body:update(dt)
    love.graphics.replaceTransform(love.math.newTransform())

    local bodiesMesh = love.graphics.newMesh({{"Index", "float", 1}}, self.bodies, nil, "static")
    self.mesh:attachAttribute('Index', bodiesMesh, 'perinstance')

    --
    -- VOLUME STAGE
    --
    local depth = self.dynamic:getDepth()
    love.graphics.setShader(volumeshader)
    love.graphics.setColor(1,1,1,0.5)
    volumeshader:send('worldscale', {self.heightmap:getDimensions()})
    volumeshader:send('bodiestex', self.bodiestex)
    for i = 1, depth, 1 do
        volumeshader:send('uZ', i-1)
        love.graphics.setCanvas(self.dynamic, i)
        love.graphics.clear(0,0,0,0)
        love.graphics.drawInstanced(self.mesh, #self.bodies)
    end

    --
    -- UPDATE STAGE
    --
    local newBodiesTex = love.graphics.newCanvas(self.bodiestex:getWidth(), self.bodiestex:getHeight(), {format=BODIES_TEX_FORMAT})
    newBodiesTex:setFilter('nearest','nearest')
    love.graphics.setCanvas(newBodiesTex)
    love.graphics.setShader(updateshader)
    updateshader:send('dt', dt)
    updateshader:send('worldscale', {self.heightmap:getDimensions()})
    updateshader:send('staticVolume', self.heightmap.volume)
    updateshader:send('dynamicVolume', self.dynamic)
    updateshader:send('cursor', Game.cursor and {Game.cursor[1], Game.cursor[2],2/self.dynamic:getDepth(),1} or {0,0,0,0})
    love.graphics.draw(self.bodiestex)

    self.bodiestex = newBodiesTex

    --
    -- RESET
    --
    love.graphics.setColor(1,1,1,1)
    love.graphics.setShader()
    love.graphics.setCanvas()
end

function Body:drawDebug()
    love.graphics.push()
    love.graphics.replaceTransform(love.math.newTransform())
    love.graphics.draw(self.bodiestex,0,0,0,10,10)
    love.graphics.pop()
    self:renderVolume(self.dynamic)
    self:renderVolume(volumeimage,1,1)
end

function Body:draw()
    local data = self.bodiestex:newImageData(0,1,0,0,self.bodiestex:getDimensions())

    for i=0,#self.bodies-1 do
        local x,y,z = data:getPixel(i,0)
        local wx,wy,wz = self.heightmap:getDimensions()
        local X, Y = self.map:convertTileToPixel(x*wx, y*wy)
        love.graphics.circle('line', X, Y-z*16, 5)
        love.graphics.line(X,Y,X, Y-z*16)
    end
end

