<?php

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    file_put_contents ("../clog/clock.log", time()."UA: ".$_SERVER['HTTP_USER_AGENT']." POST_DATA: '".file_get_contents("php://input")."'\n", FILE_APPEND );
    header('Content-Type: application/octet-stream');
    if( strncmp( $_SERVER['HTTP_USER_AGENT'], "PlusCart/v", 10 ) != 0)
        header('Access-Control-Allow-Origin: *'); // CORS header for javatari and other web emulators
    header('Content-Length: 4' ); //
    $h = 24 - intval(date("G"));
    $m = 60 - intval(date("i"));
    $s = 60 - intval(date("s"));
    echo chr(3).chr($h).chr($m).chr($s); // First byte ist Content-Length of the rest..
}else if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { // CORS Options request also only for web emulators
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Headers: PlusStore-UUID');
}else{
    echo "Wrong Request Method!\r\n";
}
?>