if SERVER then return end

local armorMat = model.newMaterial("armor", "VertexLitGeneric")
local matrix = Matrix()
matrix:setScale(Vector(0.25, 0.25, 0))
armorMat:setMatrix("$basetexturetransform", matrix)
armorMat:setInt("$realwidth", 256)
armorMat:setInt("$realheight", 256)
armorMat:setTextureURL("$basetexture", "https://raw.githubusercontent.com/AstricUnion/BMod/refs/heads/main/textures/armor.jpg")

local armor = model.newMesh("armor", "https://raw.githubusercontent.com/AstricUnion/BMod/refs/heads/main/mesh/armor.obj")
armor:load()
