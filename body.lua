Body = class('Body', VolumeRender)

local R = 9
local M = (R -1) / 2
local volumelayers = {}
for z=0,R-1 do
    local slice = love.image.newImageData(R,R)
    for y = 0,R-1 do
        for x = 0,R-1 do
            local dist = math.sqrt(math.pow(x-M,2) + math.pow(y-M,2))
            local a = 1 - math.pow(dist/M, 10)
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

local NUM_BODIES = 1000
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
    self.bodiestex = love.graphics.newCanvas(NUM_BODIES, 2, {format=BODIES_TEX_FORMAT})
    self.bodiestex:setFilter('nearest', 'nearest')
    self.mesh = love.graphics.newMesh({{'VertexPosition', 'float', 3}}, vertices, 'fan')
    local wx,wy,wz = self.heightmap:getDimensions()
    self.dynamic = love.graphics.newCanvas(wx,wy,wz, {type='volume'})

    for i = 1, NUM_BODIES do
        self:addBody(math.random(wx-4)+2,
        math.random(wy-4)+2,
        math.random(wz-3)+3,
        1)--0.5+math.random()*2)
    end

    local bodiesMesh = love.graphics.newMesh({{"Index", "float", 1}}, self.bodies, nil, "static")
    self.mesh:attachAttribute('Index', bodiesMesh, 'perinstance')
end

function Body:_indexToUV(i)
    return (0.5 + i) * (1 / NUM_BODIES), 0.5
end

function Body:addBody(x,y,z,r)
    local wx,wy,wz = self.heightmap:getDimensions()
    local i = #self.bodies
    local u,v = self:_indexToUV(#self.bodies)
    self.bodiestex:renderTo(function()
        love.graphics.setColor(x/wx,y/wy,z/wz)
        love.graphics.points(i,1)
        love.graphics.setColor(r/wz,0,0)
        love.graphics.points(i,2)
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
        vec4 Body = Texel(bodiestex, vec2(Index,0.25)) * vec4(worldscale,1);
        vec4 Params = Texel(bodiestex, vec2(Index,0.75));
        vec3 pos = (vec3(vertex_position.xy, uZ) * Params.r * worldscale.z) + vec3(Body.xy, Body.z);
        vTexCoord = vec3(vertex_position.xy / 2.1, (uZ-Body.z)) + vec3(0.5,0.5,0.5);
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
        vec4 Body = Texel(tex, vec2(texture_coords.x, 0.25));
        vec4 Params = Texel(tex, vec2(texture_coords.x, 0.75));

        if(texture_coords.y < 0.5) {
            vec3 vector = vec3(0,0,0);
            float count = 0;
            float R = worldscale.z * Params.r * 0.25;
            for(int z = -1; z <= 1; z+=1) {
                for(int y = -1; y <= 1; y+=1) {
                    for(int x = -1; x <= 1; x+=1) {
                        if((x != 0 && y != 0 && z <= 0)) {
                            vec3 diff = vec3(x,y,z) * R;
                            vec3 uvw = Body.xyz + diff / worldscale;
                            float s = Texel(staticVolume, uvw).a;
                            float d = Texel(dynamicVolume, uvw).a;
                            float f = (length(diff) / R);
                            vector += diff * (s+d) * f;
                            count += f;
                        }
                    }
                }
            }
            vector = vector / count;
            // adjust z factor
            vector.z *= 2;

            float c = 8 / worldscale.x; // <-- SPEED
            vec3 target = cursor.xyz / worldscale;
            vec3 diff = target - Body.xyz;
            float f = dot(diff, -vector);

            if(f > -0.1) {
                vec3 probe0 = Body.xyz + vec3(normalize(diff.xy), 0.0) / worldscale * R;
                vec3 probe1 = Body.xyz + vec3(normalize(diff.xy), 1.0) / worldscale * R;
                float z1 = Texel(staticVolume, probe1).a;
                float z0 = Texel(staticVolume, probe0).a;
                if(z1 < z0) {
                    Body.z = Body.z + dt * 15 / worldscale.z;
                }
                else {
                    Body.xyz += clamp(cursor.a * normalize(diff), vec3(-c,-c,-c), vec3(c,c,c)) * dt;
                }
            }
            
            Body.xyz += - vector * dt * 25; // <- repulsion
            Body.z = Body.z - dt * 10 / worldscale.z;
            Body.xyz = clamp(Body.xyz, vec3(0,0,0), vec3(1,1,1));
            return Body;
        }
        else {
            return Params;
        }
    }
]]

local updateshader = love.graphics.newShader(updatepixelcode, updatevertexcode)

function Body:update(dt)
    love.graphics.replaceTransform(love.math.newTransform())

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
    love.graphics.setBlendMode('replace', 'premultiplied')
    updateshader:send('dt', dt)
    updateshader:send('worldscale', {self.heightmap:getDimensions()})
    updateshader:send('staticVolume', self.heightmap.volume)
    updateshader:send('dynamicVolume', self.dynamic)
    updateshader:send('cursor', Game.cursor and {Game.cursor[1], Game.cursor[2],4/self.dynamic:getDepth(),1} or {0,0,0,0})
    love.graphics.draw(self.bodiestex)

    self.bodiestex = newBodiesTex

    --
    -- RESET
    --
    love.graphics.setColor(1,1,1,1)
    love.graphics.setShader()
    love.graphics.setCanvas()
    love.graphics.setBlendMode('alpha')
end

function Body:drawDebug()
    love.graphics.push()
    love.graphics.replaceTransform(love.math.newTransform())
    --love.graphics.draw(self.bodiestex,0,0,0,10,10)
    love.graphics.pop()
    self:renderVolume(self.dynamic)
    --self:renderVolume(volumeimage,1,1)
end

local image = love.graphics.newImage('iso_16x24.png')
image:setFilter('nearest','nearest')
local quads = {
    love.graphics.newQuad(112,0,16,24, image:getDimensions()),
    love.graphics.newQuad(112,24,16,24, image:getDimensions()),
}

local spritePixelcode = [[
    varying vec2 vTexCoord;
    varying vec4 Body;
    uniform vec3 worldscale;
    uniform VolumeImage dynamicVolume;

    vec2 spiderQuadOffset = vec2(7.0/8.0, 1.0/8.0);
    vec2 spiderQuadScale = vec2(1.0/8.0, -1.0/12.0);

    vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
    {
        vec3 posInWorld = Body.xyz / worldscale;
        float shadow = 0.0;
        shadow += Texel(dynamicVolume, posInWorld + vec3(0,0,1) / worldscale).a;
        shadow += Texel(dynamicVolume, posInWorld + vec3(0,0,2) / worldscale).a;
        shadow += Texel(dynamicVolume, posInWorld + vec3(1,0,2) / worldscale).a;
        shadow += Texel(dynamicVolume, posInWorld + vec3(0,1,2) / worldscale).a;
        shadow += Texel(dynamicVolume, posInWorld + vec3(-1,0,2) / worldscale).a;
        shadow += Texel(dynamicVolume, posInWorld + vec3(0,-1,2) / worldscale).a;

        vec4 texcolor = Texel(tex, vTexCoord * spiderQuadScale + spiderQuadOffset);
        vec4 fragColor = texcolor * color;
        fragColor.rgb *= 1 - (shadow/2);
        if(fragColor.a == 0)
            discard;
        return fragColor;
    }
]]
 
local spriteVertexcode = [[
    attribute float Index;
    varying vec2 vTexCoord;
    uniform Image bodiestex;
    uniform vec3 worldscale;
    varying vec4 Body;

    vec4 position( mat4 transform_projection, vec4 vertex_position )
    {
        Body = Texel(bodiestex, vec2(Index,0.25)) * vec4(worldscale,1);
        vec4 Params = Texel(bodiestex, vec2(Index,0.75));
        vec3 pos = (vec3(vertex_position.x/2, -vertex_position.x/2, vertex_position.y*2) * Params.r * worldscale.z) + vec3(Body.xy, Body.z);
        vTexCoord = vertex_position.xy / 2 + vec2(0.5,0.5);

        return transform_projection * vec4(pos,1);
    }
]]
 
spriteShader = love.graphics.newShader(spritePixelcode, spriteVertexcode)

function Body:draw()
    love.graphics.setShader(spriteShader)
    spriteShader:send('worldscale', {self.heightmap:getDimensions()})
    spriteShader:send('bodiestex', self.bodiestex)
    spriteShader:send('dynamicVolume', self.dynamic)
    self.mesh:setTexture(image)
    love.graphics.setDepthMode('lequal', true)
    love.graphics.drawInstanced(self.mesh, #self.bodies)

    love.graphics.setDepthMode()
    love.graphics.setShader()
    local data = self.bodiestex:newImageData(0,1,0,0,self.bodiestex:getDimensions())

    --[[
    for i=0,#self.bodies-1 do
        local x,y,z = data:getPixel(i,0)
        local d = data:getPixel(i,1) 
        local wx,wy,wz = self.heightmap:getDimensions()
        local X, Y = self.map:convertTileToPixel(x*wx, y*wy)
        local frame = math.floor((i/0.1 + Game.time * 10) % 2) +1
        --love.graphics.draw(image, quads[frame], X, Y-z*16, 0, d*wz, d*wz, 8,16)
        --love.graphics.print(string.format('%d|%d|%d',x*wx,y*wy,z*wz), X, Y-z*16, 0, 0.5)
        --love.graphics.circle('line', X, Y, 5)
        --love.graphics.line(X,Y,X, Y-z*16)
    end
    ]]--

    love.graphics.setColor(1,1,1,0.7)
    love.graphics.print(tostring(NUM_BODIES)..'\nBodies', 0,0,0, 0.1,0.1)
end

