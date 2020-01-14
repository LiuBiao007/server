local types = [[
.mail {
    id 0 : string               # 邮件ID
    type 1 : integer            # 邮件类型(0:消息邮件  1:奖励邮件)
    senderId 2 : string         # 发送者ID(0:表示系统邮件)
    senderName 3 : string       # 发送者名
    receiverId 4 : string       # 接收者ID
    state 5 : integer           # 是否已读(0:未读 1:已读 2:已领取)
    sourceType 6 : integer      # 邮件来源类型(0:玩家 1:后台 2:竞技场 3:夺宝 4:军团 5:好友)
    title 7 : string            # 邮件标题
    content 8 : string          # 邮件内容
    createTime 9 : integer      # 邮件创建时间
    attaches 10 : string        # 附件(奖励结构)
}

]]
local c2s = [[

sendMsgMail %d {                # 发送消息邮件
    request {
        receiverId 0 : string   # 接收者ID
        title 1 : string        # 邮件标题
        content 2 : string      # 邮件内容
    }
    response {
        errorcode 0 : integer
    }
}

sendSystemMail %d {             # 发送系统邮件
    request {
        senderName 0 : string   # 发送者名
        receiverId 1 : string   # 接收者ID
        title 2 : string        # 邮件标题
        content 3 : string      # 邮件内容
        attaches 4 : string     # 邮件附件(奖励结构)
    }
    response {
        errorcode 0 : integer
    }
}

readMail %d {                   # 阅读邮件
    request {
        mailId 0 : string       # 邮件ID
    }
    response {
        errorcode 0 : integer
        mailId 1 : string       # 邮件ID
    }
}

takeMailBonuses %d {            # 领取邮件附件
    request {
        mailId 0 : string       # 邮件ID
    }
    response {
        errorcode 0 : integer
        mailId 1 : string       # 邮件ID
        bonusesResult 2 : bonusesResult # 领取邮件附件的奖励结果
    }
}

deleteMail %d {                 # 删除邮件
    request {
        mailId 0 : string       # 邮件ID
    }
    response {
        errorcode 0 : integer
        mailId 1 : string       # 邮件ID
    }
}

viewmails %d { #分页查看邮件
    request {
    page 0:integer #页的索引 每页20个
}
    response {
    errorcode 0: integer
    mails 1: *mail
    page 2:integer
}
}
]]

local s2c = [[

insertMail %d {                 # 邮件插入事件
    request {
        mail 0 : mail           # 邮件数据
    }
}

unreadmailchanged %d { #未读邮件数量变化
    request {
        unreadMails 0: integer
}
}
]]

return {
    types = types,
    c2s = c2s,
    s2c = s2c,
}