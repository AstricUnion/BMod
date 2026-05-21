if SERVER then return end

local armorMat = model.newMaterial("armor", "VertexLitGeneric")
local mat = Matrix()
mat:setScale(Vector(1, 1, 1))
armorMat:setMatrix("$basetexturetransform", mat)
armorMat:setInt("$realwidth", 1024)
armorMat:setInt("$realheight", 1024)
armorMat:setTextureURL("$basetexture", "https://www.dropbox.com/scl/fi/o9w9ow1zbsdzn3tuw0uv9/armor.jpg?rlkey=ib70iluie9l8sidob35h4i1e0&st=yxcdi2u8&dl=1")

local armor = model.newMesh("armor", "https://raw.githubusercontent.com/AstricUnion/BMod/refs/heads/main/mesh/armor.obj")
armor:setMaterial("armor")
armor:load()
