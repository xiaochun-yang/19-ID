#!/bin/csh -f


set forever = 1
while ($forever == 1)
set str = `ps -ef | grep linux/MyAuthServer`
set pid = `echo $str | awk '{print $2}'`
echo `ps -o "pid,size,args" -p $pid` | awk '{print " pid=" $4 " size=" $5 " args=" $6}'
sleep 1
end
