
-- 配置(如果有关联的数据需要按顺序排放)
return  
{
    -- sharedata 表key
    {key = "player", parserFile = require "parser.playerParser", fileName = "PlayerConfig.xml"},         -- 角色数据
    {key = "items", parserFile = require "parser.itemsParser", fileName = "Items.xml"},         -- 角色数据
    {key = "activity",        parserFile = require "parser.activitiesParser",             fileName = "Activities.xml"}, -- 活动数据
}