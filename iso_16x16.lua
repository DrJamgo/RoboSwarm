return {
  version = "1.2",
  luaversion = "5.1",
  tiledversion = "1.2.4",
  orientation = "isometric",
  renderorder = "right-down",
  width = 12,
  height = 12,
  tilewidth = 16,
  tileheight = 16,
  nextlayerid = 23,
  nextobjectid = 1,
  properties = {},
  tilesets = {
    {
      name = "iso_16x24",
      firstgid = 1,
      filename = "iso_16x24.tsx",
      tilewidth = 16,
      tileheight = 24,
      spacing = 0,
      margin = 0,
      columns = 8,
      image = "iso_16x24.png",
      imagewidth = 128,
      imageheight = 192,
      tileoffset = {
        x = 0,
        y = 0
      },
      grid = {
        orientation = "orthogonal",
        width = 16,
        height = 24
      },
      properties = {},
      terrains = {},
      tilecount = 64,
      tiles = {
        {
          id = 5,
          type = "half"
        },
        {
          id = 10,
          type = "full"
        },
        {
          id = 13,
          type = "empty"
        }
      }
    }
  },
  layers = {
    {
      type = "tilelayer",
      id = 18,
      name = "Tile Layer 1",
      x = 0,
      y = 0,
      width = 12,
      height = 12,
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      properties = {
        ["z"] = 0
      },
      encoding = "lua",
      data = {
        11, 11, 11, 11, 11, 11, 11, 11, 14, 14, 14, 14,
        11, 14, 11, 11, 11, 11, 11, 11, 14, 14, 14, 14,
        11, 11, 11, 11, 11, 11, 14, 14, 14, 14, 14, 14,
        11, 11, 11, 11, 14, 14, 14, 14, 14, 14, 14, 14,
        11, 11, 11, 14, 14, 14, 14, 14, 14, 14, 14, 14,
        11, 11, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
        11, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
        14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
        14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
        14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
        14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
        14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14
      }
    },
    {
      type = "tilelayer",
      id = 21,
      name = "Tile Layer 2",
      x = 0,
      y = 0,
      width = 12,
      height = 12,
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = -8,
      properties = {
        ["z"] = 1
      },
      encoding = "lua",
      data = {
        0, 11, 11, 11, 11, 11, 0, 0, 0, 0, 0, 0,
        11, 11, 11, 11, 11, 11, 11, 0, 0, 0, 0, 0,
        11, 11, 11, 11, 11, 0, 0, 0, 0, 0, 0, 0,
        11, 11, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        11, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
      }
    },
    {
      type = "tilelayer",
      id = 22,
      name = "Tile Layer 3",
      x = 0,
      y = 0,
      width = 12,
      height = 12,
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = -16,
      properties = {
        ["z"] = 2
      },
      encoding = "lua",
      data = {
        0, 11, 11, 0, 11, 0, 0, 0, 0, 0, 0, 0,
        11, 11, 11, 11, 11, 0, 0, 0, 0, 0, 0, 0,
        11, 11, 11, 11, 0, 0, 0, 0, 0, 0, 0, 0,
        11, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
      }
    }
  }
}
