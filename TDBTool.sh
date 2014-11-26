#!/bin/bash

# Colors
ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"
COL_BLUE=$ESC_SEQ"34;01m"
COL_MAGENTA=$ESC_SEQ"35;01m"
COL_CYAN=$ESC_SEQ"36;01m"
COL_GRAY=$ESC_SEQ"30;01m"
COL_WHITE=$ESC_SEQ"37;01m"

# Undefine to not use $SUDO
SUDO=sudo

echo
printf '%b\n' " ______"
printf '%b\n' "/\\____ \\    ___   _ __    ___     ___  __   __  __"
printf '%b\n' "\\/___/\\ \\ /' <>\`\\/\\\`'__\\/' <>\`\\ /' _ \`' _\`\\/\\ \\/\\ \\ "
printf '%b\n' "    _\\ \\ \\/\\  ___\\ \\ \\/ /\\  ___\\/\\ \\/\\ \\/\\ \\ \\ \\_\\ \\ "
printf '%b\n' "   /\\ \\_\\ \\ \\ \\__/\\ \\_\\ \\ \\ \\__/\\ \\_\\ \\_\\ \\_\\/\`____ \\"
printf '%b\n' "   \\ \\_____\\/\`____/\\ \\_\\ \\/\`____/\\ \\_\\ \\_\\ \\_\\/___/> \\ "
printf '%b\n' "    \`/____/ \`/___/  \\/_/  \`/___/  \\/_/\\/_/\\/_/  /\\___/ "
printf '%b\n' "  http://jeremymeile.ch             M E I L E   \\/__/ "
echo
echo -e  $COL_GRAY'TRINITYCORE DATABASE TOOL '$COL_BLUE'[TDBtool]'$COL_RESET''
echo

if
    $SUDO -v
then
    echo
else
    exit
fi
MySQL_pw(){
echo -en $COL_WHITE' Please enter a new MySQL root password: '$COL_RESET
while true
    do
        read userPass
        if [ $userPass = "``" ]
        then
            continue
        else
            break
        fi
done
echo $userPass
}
Check_files(){
echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Initializing sql Files ...'
if
$SUDO /usr/bin/find -s /usr/local | /usr/bin/awk -F/ '{print $NF}' | /usr/bin/grep -e '\.sql' | /usr/bin/awk '{ printf "%s ", $0 }' | /usr/bin/sed '/^$/d' > /tmp/TDBtool_files
then
    if [ "`echo $(/bin/cat /tmp/TDBtool_files | /usr/bin/sed '/^$/d' | /usr/bin/sed -n '/characters_/p')`" != "" ]
    then
        if [ "`echo $(/bin/cat /tmp/TDBtool_files | /usr/bin/sed '/^$/d' | /usr/bin/sed -n '/world_/p')`" != "" ]
        then
            if [ "`echo $(/bin/cat /tmp/TDBtool_files | /usr/bin/sed '/^$/d' | /usr/bin/sed -n '/auth_/p')`" != "" ]
            then
                if [ "`echo $(/bin/cat /tmp/TDBtool_files | /usr/bin/sed '/^$/d' | /usr/bin/sed -n '/create_mysql.sql/p')`" != "" ]
                then
                    return 0
                else
                    return 1
                fi
            else
                return 1
            fi
        else
            return 1
        fi
    else
        return 1
    fi
else
    return 1
fi
rm /tmp/TDBtool_files
}
Check_MySQL(){
echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Initializing MySQL directory ...'
    if
    test -x /usr/local/mysql/support-files/mysql.server
    then
        if
        test -x /usr/local/mysql/bin/mysqld_safe
        then
            if
            test -x /usr/local/mysql/bin/mysql
            then
                if
                test -x /usr/local/mysql/bin/mysqldump
                then
                    echo -e $COL_GREEN' OK'$COL_RESET
                    return 0
                else
                    show_error
                    return 1
                fi
            else
            return 1
            fi
        else
        return 1
        fi
    else
    return 1
    fi
}
Check_DB(){
echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Initializing Database ...'
if [[ -d /usr/local/mysql/data ]]; then
    if
    pw=$($SUDO /bin/cat /usr/local/mysql/data/MYSQL_PASSWORD 2>/tmp/TDBtool_errorMSG)
    then
        if
        echo -e $COL_GREEN' OK'$COL_RESET
        $SUDO chown -R $USER /usr/local/*
        $SUDO chown -R mysql /usr/local/mysql/data
        MySQL_kill
        MySQL_restart
        then
            echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Testing Database ...'
            if
                result=$($SUDO /usr/local/mysql/bin/mysql -u root -p$pw update_info -e "SELECT * FROM world;" 2>/tmp/TDBtool_errorMSG)
            then
                echo -e $COL_GREEN' OK'$COL_RESET
                    echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Checking if a new Database is required ...'
                    if [ "`echo $result | /usr/bin/awk 'END{print}'`" != "" ]
                    then
                        echo -e $COL_GREEN' NO'$COL_RESET
                        return 0
                    else
                        echo -e $COL_GREEN' YES'$COL_RESET
                        return 1
                    fi
            else
                show_error
            fi
        else
            return 1
        fi
    else
        show_error
        Do_newDB
    fi
else
    echo -e $COL_RED' Not found'$COL_RESET
    Do_newDB
fi
}
Check_MySQL_user(){
echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Initializing _mysql user ...'
if
    K=$(/usr/bin/dscl . -list /Users UniqueID | /usr/bin/grep -e 'mysql' | /usr/bin/awk '{print $1}') 2>/tmp/TDBtool_errorMSG
then
    if [ "$K" = "_mysql" ]
    then
        echo -e $COL_GREEN' OK'$COL_RESET
        return 0
    else
        echo -e $COL_RED' NO _mysql user found'$COL_RESET
        Create_MySQL_user
    fi
else
    show_error
fi
}
Create_MySQL_user(){
echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Creating _mysql user and group ...'
if
    UserIDNUM=$(($(/usr/bin/dscl . -list /Users UniqueID | /usr/bin/awk '{print $2}' | /usr/bin/sort -ug | /usr/bin/tail -1)+1)) 2>/tmp/TDBtool_errorMSG
    GroupIDNUM=$(($(/usr/bin/dscl . -list /Groups PrimaryGroupID | /usr/bin/awk '{print $2}' | /usr/bin/sort -ug | /usr/bin/tail -1)+1)) 2>/tmp/TDBtool_errorMSG
then
    if
        $SUDO /usr/bin/dscl . create /Groups/_mysql > /dev/null 2>/tmp/TDBtool_errorMSG
        $SUDO /usr/bin/dscl . append /Groups/_mysql RecordName mysql > /dev/null 2>/tmp/TDBtool_errorMSG
        $SUDO /usr/bin/dscl . create /Groups/_mysql PrimaryGroupID $GroupIDNUM > /dev/null 2>/tmp/TDBtool_errorMSG
        $SUDO /usr/bin/dscl . create /Groups/_mysql RealName "MySQL Group" > /dev/null 2>/tmp/TDBtool_errorMSG
        $SUDO /usr/bin/dscl . create /Users/_mysql > /dev/null 2>/tmp/TDBtool_errorMSG
        $SUDO /usr/bin/dscl . append /Users/_mysql RecordName mysql > /dev/null 2>/tmp/TDBtool_errorMSG
        $SUDO /usr/bin/dscl . create /Users/_mysql RealName "MySQL User" > /dev/null 2>/tmp/TDBtool_errorMSG
        $SUDO /usr/bin/dscl . create /Users/_mysql UniqueID $UserIDNUM > /dev/null 2>/tmp/TDBtool_errorMSG
        $SUDO /usr/bin/dscl . create /Users/_mysql PrimaryGroupID $GroupIDNUM > /dev/null 2>/tmp/TDBtool_errorMSG
        $SUDO /usr/bin/dscl . create /Users/_mysql UserShell /usr/bin/false > /dev/null 2>/tmp/TDBtool_errorMSG
    then
        echo -e $COL_GREEN' OK'$COL_RESET
        return 0
    else
        show_error
    fi
else
    show_error
fi
}
MySQL_kill(){
if [ "`ps ax | /usr/bin/grep mysqld | /usr/bin/grep -v /usr/bin/grep | /usr/bin/awk '{ print $5 }' | /usr/bin/sed '/^$/d' | /usr/bin/grep mysqld`" != "" ]
    then
        echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Killing all active mysqld ...'
        if
        killall mysqld 2>/tmp/TDBtool_errorMSG
        $SUDO killall mysqld 2>/tmp/TDBtool_errorMSG
        then
            echo -e $COL_GREEN' OK'$COL_RESET
            return 0
        else
            show_error
        fi
fi
}
MySQL_stop(){
    echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Stopping MySQL ...'
    sleep 2
        if
        $SUDO /usr/local/mysql/support-files/mysql.server stop > /dev/null 2>/tmp/TDBtool_errorMSG
        then
            echo -e $COL_GREEN' OK'$COL_RESET
            return 0
        else
            show_error
        fi
    sleep 2
}

MySQL_start(){
    echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Starting MySQL ...'
    sleep 2
        if
        $SUDO /usr/local/mysql/support-files/mysql.server start > /dev/null 2>/tmp/TDBtool_errorMSG
        then
            echo -e $COL_GREEN' OK'$COL_RESET
            return 0
        else
            show_error
        fi
    sleep 2
}
MySQL_restart(){
    echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Restarting MySQL ...'
    sleep 2
        if
        $SUDO /usr/local/mysql/support-files/mysql.server restart > /dev/null 2>/tmp/TDBtool_errorMSG
        then
            echo -e $COL_GREEN' OK'$COL_RESET
            return 0
        else
            show_error
        fi
    sleep 2
}
Get_TDB(){
echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Looking for TrinityDB ...'
sleep 2
tdbfile=`$SUDO /usr/bin/find -s /usr/local/sql | /usr/bin/grep -e '\.sql' | /usr/bin/awk -F/ '{print $NF}' | /usr/bin/sed -n '/TDB_full/p' | /usr/bin/awk 'END{print}'`
if [ "$tdbfile" = "" ]
then
    echo -e $COL_RED' Not found'$COL_RESET
    echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Downloading latest TrinityDB ...'
        if
            if curl -s --head http://jeremymeile.ch/files/stuff/TDB_full_335.56_2014_09_21.7z | head -n 1 | grep "HTTP/1.[01] [23].." > /dev/null; then
                $SUDO chown -R $USER /usr/local/*
                $SUDO chown -R mysql /usr/local/mysql/data
                curl -s http://jeremymeile.ch/files/stuff/TDB_full_335.56_2014_09_21.7z > /usr/local/sql/base/tdb.7z 2>/tmp/TDBtool_errorMSG
            else
                echo -e $COL_RED' Could not download file'$COL_RESET
                show_error
            fi
        then
            echo -e $COL_GREEN' OK'$COL_RESET
                echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Extracting TrinityDB ...'
                if
                    cd /usr/local/sql/base; 7za x -y /usr/local/sql/base/tdb.7z > /dev/null 2>/tmp/TDBtool_errorMSG
                then
                    echo -e $COL_GREEN' OK'$COL_RESET
                    Get_TDB
                else
                    show_error
                fi
        else
            show_error
        fi
else
    echo -e ' "'$COL_MAGENTA$tdbfile$COL_RESET'"'$COL_GREEN' Found'$COL_RESET
fi
sleep 2
}
world_update(){
            if
                f=`$SUDO /usr/local/mysql/bin/mysql -u root -p$mysql_password update_info -e "SELECT * FROM world ORDER BY file DESC LIMIT 1;" | /usr/bin/sed '/^$/d' | /usr/bin/awk 'END{print}' 2>/tmp/TDBtool_errorMSG`
                    if [ "$f" = "file" ]; then
                        show_error
                    fi
                                            if [ "$(echo $f | /usr/bin/sed -n '/99_world_db/p')" = "" ]; then
                                                if [ "$(/usr/bin/find -d /usr/local/sql -name $f)" = "" ]; then
                                                    echo -e $COL_RED' failed'$COL_RESET
                                                    echo -e $COL_RED'    error '$COL_WHITE'Can not find '$f'. Maybe the file has been renamed in the past commits. Please check the "update_info" database with an SQL Editor and correct the file names.'$COL_RESET
                                                    return 1
                                                    echo
                                                fi
                                            fi
            then
                        file=$($SUDO /usr/bin/find -d /usr/local/sql | awk 'BEGIN {print "'$C'"} {print $0}' | /usr/bin/grep -e '\.sql' | /usr/bin/awk -F/ '{print $NF}' | /usr/bin/sed -n '/_world/p' | /usr/bin/sed -n '/201[0-9]\{1\}_[0-9][0-9]\{1\}_[0-9][0-9]/p' | /usr/bin/sort -n | /usr/bin/awk '/'$f'/{f=1;next}f' | /usr/bin/sed '/^$/d' | /usr/bin/head -1 2>/tmp/TDBtool_errorMSG)
                                if [ "$curvar" = "0" ]; then
                                    maxvar=$($SUDO /usr/bin/find -d /usr/local/sql | awk 'BEGIN {print "'$C'"} {print $0}' | /usr/bin/grep -e '\.sql' | /usr/bin/awk -F/ '{print $NF}' | /usr/bin/sed -n '/_world/p' | /usr/bin/sed -n '/201[0-9]\{1\}_[0-9][0-9]\{1\}_[0-9][0-9]/p' | /usr/bin/sort -n | /usr/bin/awk '/'$f'/{f=1;next}f' | /usr/bin/sed '/^$/d' | /usr/bin/wc -l | /usr/bin/sed 's/[^0-9]//g' 2>/tmp/TDBtool_errorMSG)
                                fi
                                        if [ "$file" = "" ]; then
                                            if [ "$first" = "0" ]; then
                                                echo -e $COL_GREEN' Up to date '$COL_RESET$COL_WHITE'['$f']'$COL_RESET
                                                return 0
                                            fi
                                        else
                                            if [ "$first" = "0" ]; then
                                                echo
                                                first='1'
                                            fi
                                            echo -ne '       --> '
                                            echo -ne $COL_MAGENTA $($SUDO /usr/bin/find -d /usr/local/sql -name $file | /usr/bin/awk -F/ '{print $NF}' | /usr/bin/head -1)$COL_RESET
                                            curvar=$[curvar+1]
                                            echo -ne ' ['$curvar'/'$maxvar']'
                                            echo -ne ' ...'
                                                if
                                                    $SUDO /usr/bin/find -d /usr/local/sql -name $file | /usr/bin/awk '{ print "source",$0 }' | $SUDO /usr/local/mysql/bin/mysql -u root -p$mysql_password world 2>/tmp/TDBtool_errorMSG
                                                then
                                                    echo -e $COL_GREEN' OK'$COL_RESET
                                                        B=$(/usr/bin/find -d /usr/local/sql -name $file | /usr/bin/awk -F/ '{print $NF}' | /usr/bin/head -1)
                                                            if
                                                                #$SUDO /usr/local/mysql/bin/mysql -u root -p$mysql_password update_info -e "DELETE FROM world;"
                                                                $SUDO /usr/local/mysql/bin/mysql -u root -p$mysql_password update_info -e "INSERT INTO world VALUES ('$B');"
                                                            then
                                                                world_update
                                                            else    
                                                                echo ' FAILED TO APPLY INFORMATION TO UPDATE_DB'
                                                                    RESTORE_DB
                                                                return 1
                                                            fi
                                                else
                                                    show_error
                                                    RESTORE_DB
                                                    return 1
                                                fi
                                        fi
            else
                show_error
            fi
}
auth_update(){
            if
                f=`$SUDO /usr/local/mysql/bin/mysql -u root -p$mysql_password update_info -e "SELECT * FROM auth ORDER BY file DESC LIMIT 1;" | /usr/bin/sed '/^$/d' | /usr/bin/awk 'END{print}' 2>/tmp/TDBtool_errorMSG`
                    if [ "$f" = "file" ]; then
                        show_error
                    fi
                                            if [ "$(echo $f | /usr/bin/sed -n '/99_world_db/p')" = "" ]; then
                                                if [ "$(/usr/bin/find -d /usr/local/sql -name $f)" = "" ]; then
                                                    echo -e $COL_RED' failed'$COL_RESET
                                                    echo -e $COL_RED'    error '$COL_WHITE'Can not find '$f'. Maybe the file has been renamed in the past commits. Please check the "update_info" database with an SQL Editor and correct the file names.'$COL_RESET
                                                    return 1
                                                    echo
                                                fi
                                            fi
            then
                        file=$($SUDO /usr/bin/find -d /usr/local/sql | awk 'BEGIN {print "'$C'"} {print $0}' | /usr/bin/grep -e '\.sql' | /usr/bin/awk -F/ '{print $NF}' | /usr/bin/sed -n '/_auth/p' | /usr/bin/sed -n '/201[0-9]\{1\}_[0-9][0-9]\{1\}_[0-9][0-9]/p' | /usr/bin/sort -n | /usr/bin/awk '/'$f'/{f=1;next}f' | /usr/bin/sed '/^$/d' | /usr/bin/head -1 2>/tmp/TDBtool_errorMSG)
                                if [ "$curvar" = "0" ]; then
                                    maxvar=$($SUDO /usr/bin/find -d /usr/local/sql | awk 'BEGIN {print "'$C'"} {print $0}' | /usr/bin/grep -e '\.sql' | /usr/bin/awk -F/ '{print $NF}' | /usr/bin/sed -n '/_auth/p' | /usr/bin/sed -n '/201[0-9]\{1\}_[0-9][0-9]\{1\}_[0-9][0-9]/p' | /usr/bin/sort -n | /usr/bin/awk '/'$f'/{f=1;next}f' | /usr/bin/sed '/^$/d' | /usr/bin/wc -l | /usr/bin/sed 's/[^0-9]//g' 2>/tmp/TDBtool_errorMSG)
                                fi
                                        if [ "$file" = "" ]; then
                                            if [ "$first" = "0" ]; then
                                                echo -e $COL_GREEN' Up to date '$COL_RESET$COL_WHITE'['$f']'$COL_RESET
                                                return 0
                                            fi
                                        else
                                            if [ "$first" = "0" ]; then
                                                echo
                                                first='1'
                                            fi
                                            echo -ne '       --> '
                                            echo -ne $COL_MAGENTA $($SUDO /usr/bin/find -d /usr/local/sql -name $file | /usr/bin/awk -F/ '{print $NF}' | /usr/bin/head -1)$COL_RESET
                                            curvar=$[curvar+1]
                                            echo -ne ' ['$curvar'/'$maxvar']'
                                            echo -ne ' ...'
                                                if
                                                    $SUDO /usr/bin/find -d /usr/local/sql -name $file | /usr/bin/awk '{ print "source",$0 }' | $SUDO /usr/local/mysql/bin/mysql -u root -p$mysql_password auth 2>/tmp/TDBtool_errorMSG
                                                then
                                                    echo -e $COL_GREEN' OK'$COL_RESET
                                                        B=$(/usr/bin/find -d /usr/local/sql -name $file | /usr/bin/awk -F/ '{print $NF}' | /usr/bin/head -1)
                                                            if
                                                                #$SUDO /usr/local/mysql/bin/mysql -u root -p$mysql_password update_info -e "DELETE FROM auth;"
                                                                $SUDO /usr/local/mysql/bin/mysql -u root -p$mysql_password update_info -e "INSERT INTO auth VALUES ('$B');"
                                                            then
                                                                auth_update
                                                            else    
                                                                echo ' FAILED TO APPLY INFORMATION TO UPDATE_DB'
                                                                    RESTORE_DB
                                                                return 1
                                                            fi
                                                else
                                                    show_error
                                                    RESTORE_DB
                                                    return 1
                                                fi
                                        fi
            else
                show_error
            fi
}
characters_update(){
            if
                f=`$SUDO /usr/local/mysql/bin/mysql -u root -p$mysql_password update_info -e "SELECT * FROM characters ORDER BY file DESC LIMIT 1;" | /usr/bin/sed '/^$/d' | /usr/bin/awk 'END{print}' 2>/tmp/TDBtool_errorMSG`
                    if [ "$f" = "file" ]; then
                        show_error
                    fi
                                            if [ "$(echo $f | /usr/bin/sed -n '/99_world_db/p')" = "" ]; then
                                                if [ "$(/usr/bin/find -d /usr/local/sql -name $f)" = "" ]; then
                                                    echo -e $COL_RED' failed'$COL_RESET
                                                    echo -e $COL_RED'    error '$COL_WHITE'Can not find '$f'. Maybe the file has been renamed in the past commits. Please check the "update_info" database with an SQL Editor and correct the file names.'$COL_RESET
                                                    return 1
                                                    echo
                                                fi
                                            fi
            then
                        file=$($SUDO /usr/bin/find -d /usr/local/sql | awk 'BEGIN {print "'$C'"} {print $0}' | /usr/bin/grep -e '\.sql' | /usr/bin/awk -F/ '{print $NF}' | /usr/bin/sed -n '/_characters/p' | /usr/bin/sed -n '/201[0-9]\{1\}_[0-9][0-9]\{1\}_[0-9][0-9]/p' | /usr/bin/sort -n | /usr/bin/awk '/'$f'/{f=1;next}f' | /usr/bin/sed '/^$/d' | /usr/bin/head -1 2>/tmp/TDBtool_errorMSG)
                                if [ "$curvar" = "0" ]; then
                                    maxvar=$($SUDO /usr/bin/find -d /usr/local/sql | awk 'BEGIN {print "'$C'"} {print $0}' | /usr/bin/grep -e '\.sql' | /usr/bin/awk -F/ '{print $NF}' | /usr/bin/sed -n '/_characters/p' | /usr/bin/sed -n '/201[0-9]\{1\}_[0-9][0-9]\{1\}_[0-9][0-9]/p' | /usr/bin/sort -n | /usr/bin/awk '/'$f'/{f=1;next}f' | /usr/bin/sed '/^$/d' | /usr/bin/wc -l | /usr/bin/sed 's/[^0-9]//g' 2>/tmp/TDBtool_errorMSG)
                                fi
                                        if [ "$file" = "" ]; then
                                            if [ "$first" = "0" ]; then
                                                echo -e $COL_GREEN' Up to date '$COL_RESET$COL_WHITE'['$f']'$COL_RESET
                                                return 0
                                            fi
                                        else
                                            if [ "$first" = "0" ]; then
                                                echo
                                                first='1'
                                            fi
                                            echo -ne '       --> '
                                            echo -ne $COL_MAGENTA $($SUDO /usr/bin/find -d /usr/local/sql -name $file | /usr/bin/awk -F/ '{print $NF}' | /usr/bin/head -1)$COL_RESET
                                            curvar=$[curvar+1]
                                            echo -ne ' ['$curvar'/'$maxvar']'
                                            echo -ne ' ...'
                                                if
                                                    $SUDO /usr/bin/find -d /usr/local/sql -name $file | /usr/bin/awk '{ print "source",$0 }' | $SUDO /usr/local/mysql/bin/mysql -u root -p$mysql_password characters 2>/tmp/TDBtool_errorMSG
                                                then
                                                    echo -e $COL_GREEN' OK'$COL_RESET
                                                        B=$(/usr/bin/find -d /usr/local/sql -name $file | /usr/bin/awk -F/ '{print $NF}' | /usr/bin/head -1)
                                                            if
                                                                #$SUDO /usr/local/mysql/bin/mysql -u root -p$mysql_password update_info -e "DELETE FROM characters;"
                                                                $SUDO /usr/local/mysql/bin/mysql -u root -p$mysql_password update_info -e "INSERT INTO characters VALUES ('$B');"
                                                            then
                                                                characters_update
                                                            else    
                                                                echo ' FAILED TO APPLY INFORMATION TO UPDATE_DB'
                                                                    RESTORE_DB
                                                                return 1
                                                            fi
                                                else
                                                    show_error
                                                    RESTORE_DB
                                                    return 1
                                                fi
                                        fi
            else
                show_error
            fi
}
DB_update(){
mysql_password=$($SUDO /bin/cat /usr/local/mysql/data/MYSQL_PASSWORD)
    echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Running world updates ...'
        if
            first='0'
            maxvar='0'
            curvar='0'
            world_update
        then
                echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Running auth updates ...'
            if
                first='0'
                maxvar='0'
                curvar='0'
                auth_update
            then
                echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Running characters updates ...'
                if
                    first='0'
                    maxvar='0'
                    curvar='0'
                    characters_update
                then
                    return 0
                fi
            return 1
            fi
        else
        return 1
        fi
}
RESTORE_DB(){
echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Looking for Backups ...'
bkfile=`$SUDO /usr/bin/find -s /usr/local | /usr/bin/awk -F/ '{print $NF}' | /usr/bin/sed -n '/TDB_backup/p' | /usr/bin/grep -e '\.7z' | /usr/bin/awk 'END{print}'`
if [ "$bkfile" = "" ]
then
    echo -e $COL_RED' No backups available'$COL_RESET
    MySQL_stop
    return 1
else
    echo -e ' "'$COL_MAGENTA$bkfile$COL_RESET'"'$COL_GREEN' Found'$COL_RESET
fi
f=`echo $bkfile | /usr/bin/awk '{gsub(".7z", "");print}'`
echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Extracting "'$COL_MAGENTA$f$COL_RESET'" ...'
    cd /usr/local/DB_backups
    if
        $SUDO 7za x -y $($SUDO /usr/bin/find -s /usr/local | /usr/bin/sed -n '/TDB_backup/p' | /usr/bin/grep -e '\.7z' | /usr/bin/awk 'END{print}') > /dev/null 2>/tmp/TDBtool_errorMSG
    then
        echo -e $COL_GREEN' OK'$COL_RESET
    else
        show_error
        return 1
    fi
MySQL_start
echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Restore Database from "'$COL_MAGENTA$f$COL_RESET'" ...'
    if
        $SUDO /usr/bin/find -s /usr/local | /usr/bin/awk '{ print "source",$0 }' | /usr/bin/sed -n '/TDB_backup/p' | /usr/bin/grep -e '\.sql' | /usr/bin/awk 'END{print}' | /usr/bin/awk '{gsub(".7z", "");print}' | $SUDO /usr/local/mysql/bin/mysql -u root -p$($SUDO /bin/cat /usr/local/mysql/data/MYSQL_PASSWORD) > /dev/null 2>/tmp/TDBtool_errorMSG
        then
        echo -e $COL_GREEN' OK'$COL_RESET
    else
        show_error
        RESTORE_DB
        return 1
    fi
MySQL_stop
echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Reload root password ...'
    if
        $SUDO cp /usr/local/DB_backups/MYSQL_PASSWORD /usr/local/mysql/data/MYSQL_PASSWORD > /dev/null 2>&1
        then
        echo -e $COL_GREEN' OK'$COL_RESET
        $SUDO rm -d -f -r /usr/local/DB_backups/MYSQL_PASSWORD > /dev/null 2>/tmp/TDBtool_errorMSG
    else
        show_error
        RESTORE_DB
        return 1
    fi
MySQL_start
echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Testing MySQL ...'
    if
        $SUDO /usr/local/mysql/bin/mysql -u root -p$($SUDO /bin/cat /usr/local/mysql/data/MYSQL_PASSWORD) world -e "SELECT * FROM item_template;" > /dev/null 2>/tmp/TDBtool_errorMSG
        then
        echo -e $COL_GREEN' OK'$COL_RESET
    else
        show_error
        RESTORE_DB
        return 1
    fi
MySQL_stop
}
Backup_DB(){
    MySQL_start
        echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Creating Database backup ...'
        backup_file=TDB_backup_$(/bin/date "+%Y-%m-%d-%H-%M-%S").sql
    if /bin/mkdir -p /usr/local/DB_backups > /dev/null 2>/tmp/TDBtool_errorMSG; then
        echo -n ''
        else
            echo -e $COL_RED'    error '$COL_WHITE$(/bin/cat /tmp/TDBtool_errorMSG)$COL_RESET
            MySQL_stop
            return 1
    fi
    if $SUDO /bin/test -f /usr/local/mysql/data/MYSQL_PASSWORD
        then
            if
            $SUDO /usr/local/mysql/bin/mysqldump -u root -p$($SUDO /bin/cat /usr/local/mysql/data/MYSQL_PASSWORD) --all-databases > /usr/local/DB_backups/$backup_file 2>/tmp/TDBtool_errorMSG
            then
                echo -e $COL_GREEN' OK'$COL_RESET
            else
                show_error
                rm -d -f -r /usr/local/DB_backups/$backup_file > /dev/null 2>/tmp/TDBtool_errorMSG
                return 1
            fi
    else
            echo
            echo '  MYSQL ROOT PW NOT FOUND! ENTER YOUR PASSWORD PLEASE.'
            if
            /usr/local/mysql/bin/mysqldump -u root -p --all-databases > /usr/local/DB_backups/$backup_file > /dev/null 2>/tmp/TDBtool_errorMSG
            then
                echo -e $COL_GREEN' OK'$COL_RESET
            else
                show_error
                rm -d -f -r /usr/local/DB_backups/$backup_file > /dev/null 2>/tmp/TDBtool_errorMSG
                return 1
            fi
    fi
    if
        /bin/test -f /usr/local/DB_backups/$backup_file
    then
        echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Compressing Database backup ...'
        if
        $SUDO 7za a -t7z -mx1 /usr/local/DB_backups/$backup_file.7z /usr/local/DB_backups/$backup_file /usr/local/mysql/data/MYSQL_PASSWORD > /dev/null 2>/tmp/TDBtool_errorMSG
        then
            echo -e $COL_GREEN' OK'$COL_RESET
        else
            show_error
        fi
    echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Cleaning ...'
    if
    rm -d -f -r /usr/local/DB_backups/$backup_file > /dev/null 2>/tmp/TDBtool_errorMSG
    then
        echo -e $COL_GREEN' OK'$COL_RESET
    else    
        show_error
    fi
    fi
}
realmlist_set_internal(){
Check_DB
MySQL_start
echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Getting internal ip address ...'
if
     INTERNAL=$(ipconfig getifaddr en1) > /dev/null 2>/tmp/TDBtool_errorMSG
then
    echo -e $COL_GREEN' OK'$COL_RESET
    echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Setting realmlist to "'$INTERNAL'" ...'
    if
        $SUDO /usr/local/mysql/bin/mysql -u root -p$($SUDO cat /usr/local/mysql/data/MYSQL_PASSWORD) auth -e "UPDATE realmlist SET address = '$INTERNAL';" > /dev/null 2>/tmp/TDBtool_errorMSG
    then
        echo -e $COL_GREEN' OK'$COL_RESET
    else
        show_error
    fi
else
    show_error
fi
MySQL_stop
exit
}
realmlist_set_external(){
Check_DB
MySQL_start
echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Getting external ip address ...'
if
     EXTERNAL=$(curl -s http://checkip.dyndns.org | grep -Eo '([0-9]*\.){3}[0-9]*') > /dev/null 2>/tmp/TDBtool_errorMSG
then
    echo -e $COL_GREEN' OK'$COL_RESET
    echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Setting realmlist to "'$EXTERNAL'" ...'
    if
        $SUDO /usr/local/mysql/bin/mysql -u root -p$($SUDO cat /usr/local/mysql/data/MYSQL_PASSWORD) auth -e "UPDATE realmlist SET address = '$EXTERNAL';" > /dev/null 2>/tmp/TDBtool_errorMSG
    then
        echo -e $COL_GREEN' OK'$COL_RESET
    else
        show_error
    fi
else
    show_error
fi
MySQL_stop
exit
}
Do_newDB(){
    echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Creating new Database ...'
    sleep 2
    $SUDO rm -d -f -r /usr/local/mysql/data
    $SUDO rm -d -f -r ~/my.cnf 
    $SUDO rm -d -f -r ~/etc/my.cnf 
    $SUDO rm -d -f -r ./my.cnf 
        if
        cd /usr/local/mysql ; $SUDO /usr/local/mysql/scripts/mysql_install_db --explicit_defaults_for_timestamp --no-defaults --cross-bootstrap --user=mysql --force --datadir=/usr/local/mysql/data > /dev/null 2>/tmp/TDBtool_errorMSG
        then
            echo -e $COL_GREEN' OK'$COL_RESET
        else
            show_error
        fi
MySQL_stop
MySQL_kill
MySQL_start
echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Generating MySQL root password ...'
pw_file=MYSQL_PASSWORD
    if
        myPW=$(openssl rand -base64 6 2>/tmp/TDBtool_errorMSG)
        echo $myPW > /tmp/MYSQL_PASSWORD 2>/tmp/TDBtool_errorMSG
        $SUDO cp /tmp/MYSQL_PASSWORD /usr/local/mysql/data/MYSQL_PASSWORD 2>/tmp/TDBtool_errorMSG
        rm -d -f -r /tmp/MYSQL_PASSWORD 2>/tmp/TDBtool_errorMSG
    then
        echo -e $COL_GREEN' OK'$COL_RESET
    else
        show_error
    fi
echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Drop "test" database ...'
    if
        /usr/local/mysql/bin/mysql -u root -e "DROP DATABASE IF EXISTS test;" > /dev/null 2>/tmp/TDBtool_errorMSG
    then
        echo -e $COL_GREEN' OK'$COL_RESET
    else
        show_error
    fi
echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Delete Unknown user ...'
    if
        /usr/local/mysql/bin/mysql -u root -e "DELETE FROM mysql.user WHERE User = '';" > /dev/null 2>/tmp/TDBtool_errorMSG
    then
        echo -e $COL_GREEN' OK'$COL_RESET
    else
        show_error
    fi
echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Set new root password ...'
    if
        $SUDO /usr/local/mysql/bin/mysql -u root -e "UPDATE mysql.user SET Password = PASSWORD('$($SUDO /bin/cat /usr/local/mysql/data/MYSQL_PASSWORD)') WHERE User = 'root';" > /dev/null 2>/tmp/TDBtool_errorMSG
    then
        echo -e $COL_GREEN' OK'$COL_RESET
    else
        show_error
        $SUDO rm -d -f -r /usr/local/mysql/data/MYSQL_PASSWORD
        exit 1
    fi
echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Flush privileges ...'
    if
        /usr/local/mysql/bin/mysql -u root -e "FLUSH PRIVILEGES;" > /dev/null 2>/tmp/TDBtool_errorMSG
    then
        echo -e $COL_GREEN' OK'$COL_RESET
        MySQL_restart
    else
        show_error
    fi
echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Creating update_info database ...'
    if
        $SUDO /usr/local/mysql/bin/mysql -u root -p$($SUDO /bin/cat /usr/local/mysql/data/MYSQL_PASSWORD) -e "CREATE DATABASE update_info DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;" > /dev/null 2>/tmp/TDBtool_errorMSG
    then
        echo -e $COL_GREEN' OK'$COL_RESET
    else
        show_error
    fi
echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Creating "world" table ...'
    if
        $SUDO /usr/local/mysql/bin/mysql -u root -p$($SUDO /bin/cat /usr/local/mysql/data/MYSQL_PASSWORD) update_info -e "CREATE TABLE world (file text);" > /dev/null 2>/tmp/TDBtool_errorMSG
    then
        echo -e $COL_GREEN' OK'$COL_RESET
    else
        show_error
    fi
echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Creating "auth" table ...'
    if
        $SUDO /usr/local/mysql/bin/mysql -u root -p$($SUDO /bin/cat /usr/local/mysql/data/MYSQL_PASSWORD) update_info -e "CREATE TABLE auth (file text);" > /dev/null 2>/tmp/TDBtool_errorMSG
    then
        echo -e $COL_GREEN' OK'$COL_RESET
    else
        show_error
    fi
echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Creating "character" table ...'
    if
        $SUDO /usr/local/mysql/bin/mysql -u root -p$($SUDO /bin/cat /usr/local/mysql/data/MYSQL_PASSWORD) update_info -e "CREATE TABLE characters (file text);" > /dev/null 2>/tmp/TDBtool_errorMSG
    then
        echo -e $COL_GREEN' OK'$COL_RESET
    else
        show_error
    fi
echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Running "'$COL_MAGENTA'create_mysql.sql'$COL_RESET'" ...'

    if
        $SUDO /usr/bin/find -s /usr/local/sql -name create_mysql.sql | /usr/bin/awk '{ print "source",$0 }' | /usr/bin/awk 'END{print}' | $SUDO /usr/local/mysql/bin/mysql -u root -p$($SUDO /bin/cat /usr/local/mysql/data/MYSQL_PASSWORD) > /dev/null 2>/tmp/TDBtool_errorMSG
    then
        echo -e $COL_GREEN' OK'$COL_RESET
    else
        show_error
        RESTORE_DB
        exit 1
    fi
}
Do_TDB(){
echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Running "'$COL_MAGENTA$tdbfile$COL_RESET'" ...'
    if
        /usr/local/mysql/bin/mysql -u root -e "DELETE * FROM world" > /dev/null 2>/tmp/TDBtool_errorMSG
        $SUDO /usr/bin/find -d /usr/local/sql -name $tdbfile | /usr/bin/awk '{ print "source",$0 }' | /usr/bin/awk 'END{print}' | $SUDO /usr/local/mysql/bin/mysql -u root -p$($SUDO /bin/cat /usr/local/mysql/data/MYSQL_PASSWORD) world 2>/tmp/TDBtool_errorMSG
    then
        echo -e $COL_GREEN' OK'$COL_RESET
        A=$(echo $tdbfile | /usr/bin/grep -o '\(201[0-9]\{1\}_[0-9]\{2\}_[0-9]\{2\}\)')
                    if [ "$A" = "" ]
                        then
                        echo -e $COL_RED' error: no tdbfile'$COL_RESET
                        return 1
                    fi
        echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Adding update info ...'
            if
                    B='_99_world_db.sql'
                    C=$A$B
                    $SUDO /usr/local/mysql/bin/mysql -u root -p$($SUDO /bin/cat /usr/local/mysql/data/MYSQL_PASSWORD) update_info -e "DELETE FROM world;"
                    $SUDO /usr/local/mysql/bin/mysql -u root -p$($SUDO /bin/cat /usr/local/mysql/data/MYSQL_PASSWORD) update_info -e "INSERT INTO world VALUES ('$C');"
            then
                    echo -e $COL_GREEN' OK'$COL_RESET
            else
                show_error
                RESTORE_DB
                exit 1
            fi
    else
            show_error
            RESTORE_DB
            exit 1
    fi
}
Do_characters_database(){
echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Running "'$COL_MAGENTA'characters_database.sql'$COL_RESET'" ...'
    if
        $SUDO /usr/bin/find -s /usr/local/sql -name characters_database.sql | /usr/bin/awk 'END{print}' | /usr/bin/awk '{ print "source",$0 }' | $SUDO /usr/local/mysql/bin/mysql -u root -p$($SUDO /bin/cat /usr/local/mysql/data/MYSQL_PASSWORD) characters > /dev/null 2>/tmp/TDBtool_errorMSG
    then
        echo -e $COL_GREEN' OK'$COL_RESET
            B=$(/usr/bin/find -d /usr/local/sql | /usr/bin/awk -F/ '{print $NF}' | /usr/bin/sed -n '/201[0-9]\{1\}_[0-9][0-9]\{1\}_[0-9][0-9]/p' | /usr/bin/grep -e '\.sql' | /usr/bin/sed -n '/_characters/p' | /usr/bin/sort -n | /usr/bin/sed '/^$/d' | /usr/bin/sed '$!d')
            echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Adding update info ...'
                    if
                        $SUDO /usr/local/mysql/bin/mysql -u root -p$($SUDO /bin/cat /usr/local/mysql/data/MYSQL_PASSWORD) update_info -e "DELETE FROM characters;"
                        $SUDO /usr/local/mysql/bin/mysql -u root -p$($SUDO /bin/cat /usr/local/mysql/data/MYSQL_PASSWORD) update_info -e "INSERT INTO characters VALUES ('$B');"
                    then
                        echo -e $COL_GREEN' OK'$COL_RESET
                    else
                        show_error
                        RESTORE_DB
                        exit 1
                    fi
                else
            show_error
            RESTORE_DB
            exit 1
    fi
}
Do_auth_database(){
echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Running "'$COL_MAGENTA'auth_database.sql'$COL_RESET'" ...'
    if
        $SUDO /usr/bin/find -s /usr/local/sql -name auth_database.sql | /usr/bin/awk 'END{print}' | /usr/bin/awk '{ print "source",$0 }' | $SUDO /usr/local/mysql/bin/mysql -u root -p$($SUDO /bin/cat /usr/local/mysql/data/MYSQL_PASSWORD) auth > /dev/null 2>/tmp/TDBtool_errorMSG
    then
        echo -e $COL_GREEN' OK'$COL_RESET
            B=$(/usr/bin/find -d /usr/local/sql | /usr/bin/awk -F/ '{print $NF}' | /usr/bin/sed -n '/201[0-9]\{1\}_[0-9][0-9]\{1\}_[0-9][0-9]/p' | /usr/bin/grep -e '\.sql' | /usr/bin/sed -n '/_auth/p' | /usr/bin/sort -n | /usr/bin/sed '/^$/d' | /usr/bin/sed '$!d')
            echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Adding update info ...'
                    if
                        $SUDO /usr/local/mysql/bin/mysql -u root -p$($SUDO /bin/cat /usr/local/mysql/data/MYSQL_PASSWORD) update_info -e "DELETE FROM auth;"
                        $SUDO /usr/local/mysql/bin/mysql -u root -p$($SUDO /bin/cat /usr/local/mysql/data/MYSQL_PASSWORD) update_info -e "INSERT INTO auth VALUES ('$B');"
                    then
                        echo -e $COL_GREEN' OK'$COL_RESET
                    else
                        show_error
                        RESTORE_DB
                        exit 1
                    fi
                else
                    show_error
                    RESTORE_DB
                    exit 1
    fi
}
Get7Zip(){
echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Downloading "'$COL_MAGENTA'7Zip (required for Backup compression)'$COL_RESET'" ...'
    if
        cd ~/Downloads > /dev/null 2>/tmp/TDBtool_errorMSG
        rm -d -f -r p7zip_9.20.1_src_all.tar.bz2 > /dev/null 2>/tmp/TDBtool_errorMSG
        curl -O -s 'http://optimate.dl.sourceforge.net/project/p7zip/p7zip/9.20.1/p7zip_9.20.1_src_all.tar.bz2' > /dev/null 2>/tmp/TDBtool_errorMSG
    then
        echo -e $COL_GREEN' OK'$COL_RESET
        echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Extracting 7Zip ...'
            if
                cd ~/Downloads > /dev/null 2>/tmp/TDBtool_errorMSG
                tar -xjf p7zip_9.20.1_src_all.tar.bz2 > /dev/null 2>/tmp/TDBtool_errorMSG
            then
                echo -e $COL_GREEN' OK'$COL_RESET
                echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Building 7Zip ...'
                    if
                        cd ~/Downloads/p7zip_9.20.1 > /dev/null 2>/tmp/TDBtool_errorMSG
                        mv makefile.macosx_64bits makefile.machine > /dev/null 2>/tmp/TDBtool_errorMSG
                        make -j $(sysctl -n hw.ncpu) > /dev/null 2>/tmp/TDBtool_errorMSG
                    then
                        echo -e $COL_GREEN' OK'$COL_RESET
                        echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Installing 7Zip ...'
                            if
                                $SUDO make install > /dev/null 2>/tmp/TDBtool_errorMSG
                            then
                                echo -e $COL_GREEN' OK'$COL_RESET
                                return 0
                            else
                                show_error
                                return 1
                            fi
                    else
                        show_error
                        return 1
                    fi  
            else
                show_error
                return 1
            fi
    else
        show_error
        return 1
    fi
}
Show_PW(){
if $SUDO /bin/cat /usr/local/mysql/data/MYSQL_PASSWORD > /dev/null 2>/tmp/TDBtool_errorMSG; then
    echo -e $COL_GREEN'#####################################################'$COL_RESET
    echo -ne $COL_GREEN'YOUR MYSQL ROOT PASSWORD IS: '$COL_RESET
    $SUDO /bin/cat /usr/local/mysql/data/MYSQL_PASSWORD
    echo -e $COL_GREEN'#####################################################'$COL_RESET
    exit 0
else
    echo -e $COL_RED' No root password set'$COL_RESET
        return 1
fi
}
show_error(){
    echo -e $COL_RED' failed'$COL_RESET
    echo -e $COL_RED'    error '$COL_WHITE$(/bin/cat /tmp/TDBtool_errorMSG)$COL_RESET
    rm -d -f -r /tmp/TDBtool_errorMSG
    return 1
    echo
}
SoftwareCheck(){
if
    Check_files
then
    echo -e $COL_GREEN' OK'$COL_RESET
else
    echo -e $COL_RED' error'$COL_RESET
    echo
    echo -e $COL_RED$'Some sql files missing!'$COL_RESET
    echo -e $COL_RED$'Make sure that /usr/local/sql/ exists.'$COL_RESET
    echo
    MySQL_stop
    exit 1
fi
echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Looking for 7z ...'
if
    7za > /dev/null 2>&1
    then
        echo -e $COL_GREEN' OK'$COL_RESET
    else
        echo -e $COL_GREEN' Not found'$COL_RESET
        Get7Zip
fi
echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Looking for headers ...'
if [[ -d /usr/include ]]
then
    echo -e $COL_GREEN' OK'$COL_RESET
else
    echo -e $COL_RED' Not found, running "xcode-select --install"'$COL_RESET
    xcode-select --install
    exit 1
fi
}
Main_menu(){
if [[ -d /usr/local/mysql/data ]]
then
echo -e '   Welcome to '$COL_BLUE'[TDBtool] '$COL_RESET' ...'
echo -e '    '$COL_GREEN'[Create a new Database]'$COL_RESET' To remove the existing database and create a new one, press key '$COL_BLUE'[n/N]'$COL_RESET
echo -e '    '$COL_GREEN'[Create a new World Database]'$COL_RESET' To remove the existing database and create a new one, press key '$COL_BLUE'[w/W]'$COL_RESET
echo -e '    '$COL_MAGENTA'[Update the database]'$COL_RESET' To check the database and apply all updates, press key '$COL_BLUE'[u/U]'$COL_RESET
echo -e '    '$COL_BLUE'[Backup the database]'$COL_RESET' To create a backup from the full database, press key '$COL_BLUE'[b/B]'$COL_RESET
echo -e '    '$COL_BLUE'[Restore the database]'$COL_RESET' To restore the full database from last backup, press key '$COL_BLUE'[b/B]'$COL_RESET
echo -e '    '$COL_YELLOW'[Internal IP]'$COL_RESET' To set realmlist to your internal ip address, press key '$COL_BLUE'[i/I]'$COL_RESET
echo -e '    '$COL_YELLOW'[External IP]'$COL_RESET' To set realmlist to your external ip address, press key '$COL_BLUE'[e/E]'$COL_RESET
echo -e '    '$COL_YELLOW'[MySQL Root PW]'$COL_RESET' To print out the MySQL root Password, press key '$COL_BLUE'[p/P]'$COL_RESET
echo -e '    '$COL_RED'[Exit the Script]'$COL_RESET' To exit the script, press key '$COL_BLUE'[q/Q]'$COL_RESET
    while true; do
        read -p 'To continue, make a choice and press enter: ' yn
        case $yn in
        [Nn]* ) Check_DB
                Backup_DB
                Do_newDB
                Get_TDB
                Do_TDB
                Do_characters_database
                Do_auth_database
                DB_update
                break ;;
        [Uu]* ) Check_DB
                Backup_DB
                DB_update
                break ;;
        [Ww]* ) Check_DB
                Backup_DB
                Get_TDB
                Do_TDB
                DB_update
                break ;;
        [Bb]* ) Check_DB
                Backup_DB
                break ;;
        [Rr]* ) Check_DB
                RESTORE_DB
                break ;;
        [Ii]* ) realmlist_set_internal
                break ;;
        [Ee]* ) realmlist_set_external
                break ;;
        [Pp]* ) Show_PW
                break ;;
        [Qq]* ) echo "OK. Bye!"
                exit ;;
        * ) ;;
        esac
    done
fi
}
SoftwareCheck
Check_MySQL_user
Check_DB
Main_menu
MySQL_restart
echo -ne $COL_BLUE'[TDBtool] '$COL_RESET'Optimizing all Databases ...'
if
$SUDO /usr/local/mysql/bin/mysqlcheck -u root -p$($SUDO /bin/cat /usr/local/mysql/data/MYSQL_PASSWORD) -o --all-databases > /dev/null 2>/tmp/TDBtool_errorMSG
then
echo -e $COL_GREEN' OK'$COL_RESET
else
show_error
fi
