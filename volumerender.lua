VolumeRender = class('VolumeRender')

local vertexcode = [[
    uniform float slice;
    varying vec3 vTexCoord;

    vec4 position( mat4 transform_projection, vec4 vertex_position )
    {
        vTexCoord = vec3(vertex_position.xy, slice) + vec3(0.05,0.05,0.05);
        return transform_projection * vec4(vertex_position.xy, slice, 1);
    }
]]

local pixelcode = [[
    uniform VolumeImage volumetex;
    uniform float slice;
    varying vec3 vTexCoord;

    vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
    {
        vec4 texcolor = Texel(volumetex, vTexCoord);
        vec4 c = texcolor * color;
        return vec4(2*vTexCoord.z * c.r, (1-vTexCoord.z*2)*c.g, 0, c.a);
    }
]]

local debugshader = love.graphics.newShader(pixelcode, vertexcode)

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

function VolumeRender:renderVolume(volumeimage, x, y)
    love.graphics.setShader(debugshader)
    debugshader:send('volumetex', volumeimage)
    local depth = volumeimage:getDepth()
    local step = 0.1
    love.graphics.setColor(1,1,1,math.pow(step, step))
    for i = 1, depth, step do
        debugshader:send('slice', (i-1) / (depth-1))
        love.graphics.draw(mesh, x, y)
    end
    love.graphics.setShader()
end