#!/bin/bash
## Service vars
UtilityName="[$(basename $0)]"
ScriptPath=$(readlink -f $0)
ScriptDir=$(dirname $ScriptPath)
ParserWorkDir="$ScriptDir"
ParseURLBase="https://stopgame.ru/blogs/new/all/all/page1"

### Telegram bot info 
if [ -f ${ParserWorkDir}/.TGToken ];
    then
    TGToken=$(cat ${ParserWorkDir}/.TGToken)
else
    echo "Укажи Telegram Token своего бота, который будет отправлять сообщения"
    echo "Как зарегистрировать совего бота: https://core.telegram.org/bots#6-botfather"
    read TGToken
    echo $TGToken > ${ParserWorkDir}/.TGToken
fi

### Recepient info
if [ -f ${ParserWorkDir}/.TGChatID ];
    then
    TGChatID="$(cat ${ParserWorkDir}/.TGChatID)"
else
    echo "Укажи Telegram Chat ID пользователей, которым будут отправляться сообщения"
    echo "Можешь узнать свой Chat ID, написав этому боту: http://t.me/userinfobot"
    read TGChatID
    echo $TGChatID > ${ParserWorkDir}/.TGChatID
fi

### Ensure data dir exists
if [ ! -d ${ParserWorkDir}/.data ];
        then
        mkdir ${ParserWorkDir}/.data
    fi

### Check if feed is new
### I dont want script spam you with all feed data on the first run
if [ -f ${ParserWorkDir}/.data/.CurrentPostList ]
    then
    CurrentFeedIsSilent="false"
    else
    CurrentFeedIsSilent="true"
fi

### Get Raw data. And do some parse magic
curl -s $ParseURLBase | grep '/blogs/topic/' | grep 'blog-title' | sed 's/<a href="/https\:\/\/stopgame.ru/g;s/" class="blog-title">/ /g;s/<\/a><br>//g'> ${ParserWorkDir}/.data/.CurrentParseResult

### Create all posts ID list:
cat ${ParserWorkDir}/.data/.CurrentParseResult | grep http | awk '{print$1}'  | awk -F '/' '{print $(NF)}' > ${ParserWorkDir}/.data/.CurrentPostList

### Inform about each new post
for CurrentPost in $(cat ${ParserWorkDir}/.data/.CurrentPostList);
do
    ### Cycle finding new posts
    if [ ! -f ${ParserWorkDir}/.data/${CurrentPost}.head ];
        then
        cat ${ParserWorkDir}/.data/.CurrentParseResult | grep $CurrentPost > ${ParserWorkDir}/.data/${CurrentPost}.head
        if [ $CurrentFeedIsSilent = "false" ]
            then
            for CurrentRecipient in $TGChatID;
                do
                curl -s -X POST https://api.telegram.org/bot$TGToken/sendMessage -d chat_id=${CurrentRecipient} -d text="Юля говорит, что тут новый пост: $(cat ${ParserWorkDir}/.data/${CurrentPost}.head)"
            done
        fi
    fi
done

### Inform if there was not any posts and now they are indexed
if [ $CurrentFeedIsSilent = "true" ]
    then
    for CurrentRecipient in $TGChatID;
        do
        curl -s -X POST https://api.telegram.org/bot$TGToken/sendMessage -d chat_id=${CurrentRecipient} -d text="Юля говорит, что лента успешно добавилась в список отслеживаемого"
    done
fi

