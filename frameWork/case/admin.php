<?php
function json_decode_ex($json_str, $cmd = ""){
	echo $json_str;
    if($ret = json_decode($json_str, true)){
        return $ret;
    }else{

        return null;
    }  
}


$socket = socket_create(AF_INET, SOCK_STREAM, SOL_TCP);
if(!empty($socket)){

	$address = "127.0.0.1";
	$port = 7000;
    $r = socket_connect($socket, $address, $port);
 
    if(!empty($r)){
        //$input = 'dynamicActivityInsert 1009999 <B>dan来临<C>0XFF1493 icon.jpg 双11来临，你要这铁棒有何用？福利高潮48H，右手永不为奴! 双11来临，你要这铁棒有何用？福利高潮48H，右手永不为奴。 1 1 2020-01-03&nbsp;19:10:00 2020-01-03&nbsp;23:59:59 1-7 00:00-23:59 1000004 {"isTop":1}';
        //$input = "dynamicActivitySortIndex 1009999,3";
        //$input = "debug agent agent_001";
        $input = "sendSystemMail kakakak 0000271503F2000100000009 xxxxaaaa aaaaaaaaaa";
        $input .= "\n";

        socket_write($socket, $input, strlen($input));
        $out = '';
        do {
            $out .= socket_read($socket, 1024);
            if(stripos($out, "\n")){
                break;
            }
            sleep(1);
        }while(true);
        socket_close($socket);
        return json_decode_ex($out, $cmd);
    }
}
socket_close($socket);