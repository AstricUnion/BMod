if SERVER then return end

local armorMat = model.newMaterial("armor", "VertexLitGeneric")
local mat = Matrix()
mat:setScale(Vector(0.75, 0.75, 0.75))
armorMat:setMatrix("$basetexturetransform", mat)
armorMat:setInt("$realwidth", 1024)
armorMat:setInt("$realheight", 1024)
armorMat:setTextureURL("$basetexture", "https://raw.githubusercontent.com/AstricUnion/BMod/refs/heads/main/textures/armor.jpg")

local armor = model.newMesh("armor", "https://raw.githubusercontent.com/AstricUnion/BMod/refs/heads/main/mesh/armor.obj")
armor:setMaterial("armor")
armor:load()
