local fieldObject = require "objects.fieldObject"

local mail = class("mail", fieldObject)

function mail:init()

	self.dbname = "mail"
	mail.__father.init(self, self.dbname)
	return self
end	

function mail:delete()

	if self.man:getMailById(self.id) then
		mail.__father.delete(self)
		self.man:detachMail(self)
		mylog.info("in mail delete mail----2 ", self)
	end	
end	

function mail:needDelete()

    if (self.type == 0 and self.state == 1) or 
       (self.type == 1 and self.state == 2) then

       if not self.__predelete then return true end
    end   
    return false
end	

function mail:setPreDelete()

	self.__predelete = true
end	

return mail