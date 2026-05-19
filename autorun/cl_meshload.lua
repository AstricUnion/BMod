if SERVER then return end

local armorMat = model.newMaterial("armor", "VertexLitGeneric")
armorMat:setInt("$realwidth", 1024)
armorMat:setInt("$realheight", 1024)
armorMat:setTextureURL("$basetexture", "https://raw.githubusercontent.com/AstricUnion/BMod/refs/heads/main/textures/armor.jpg")

local armor = model.newMesh("armor", "https://raw.githubusercontent.com/AstricUnion/BMod/refs/heads/main/mesh/armor.obj")
armor:setMaterial("armor")
armor:load()
