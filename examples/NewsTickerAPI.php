<?php


if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $PlusStoreId = $_SERVER['HTTP_PLUSSTORE_ID'];
    $isWebEmulator =  (substr( $PlusStoreId, 7, 2 ) == "WE" );
    $post_data = file_get_contents("php://input");
    $post_data_len = strlen($post_data);
    $umlaute = array("ä",  "ö",  "ü",  "Ä",  "Ö",  "Ü",  "ß");
    $uml     = array("ae", "oe", "ue", "Ae", "Oe", "Ue", "ss");
    $find    = array(       "I",      "J",      "R",      "K",      "D",      "B",      "P",      "L",      "Z",      "F",      "G",      "S",      "Q",      "[",      "2",      "5",      "3",      "6",      "8",      "9",      "7",      "&",      "$",      "N",      "U",      "W",      "H",      "V",      "X",      "Y",      "'",      " ",      ".",      "O",      "A",      "M",      "0",      "4",      "/",     "\\",      "<",      ">",      "#",      "%",     "\"",      ",",      "(",      ")",      "*",      "^",      "_",      "-",      "=",      "]",      "?",      "@",      "C",      "E",      "{",      "}",      "1",      "T",      "|",      "!",      "+",      "~",      ":",      ";",      "`","PLUS_MINUS","SQUARE","DIVISION","°");
    $replace = array( chr(0x00),chr(0x04),chr(0x08),chr(0x0b),chr(0x0d),chr(0x11),chr(0x13),chr(0x16),chr(0x1a),chr(0x1e),chr(0x23),chr(0x27),chr(0x2b),chr(0x2f),chr(0x34),chr(0x36),chr(0x3a),chr(0x3e),chr(0x40),chr(0x42),chr(0x44),chr(0x48),chr(0x4c),chr(0x50),chr(0x51),chr(0x52),chr(0x53),chr(0x56),chr(0x58),chr(0x5b),chr(0x5e),chr(0x60),chr(0x61),chr(0x65),chr(0x69),chr(0x6a),chr(0x6b),chr(0x6d),chr(0x70),chr(0x73),chr(0x77),chr(0x79),chr(0x7e),chr(0x82),chr(0x86),chr(0x88),chr(0x8c),chr(0x91),chr(0x96),chr(0x98),chr(0x9a),chr(0x9c),chr(0xa0),chr(0xa5),chr(0xa9),chr(0xad),chr(0xb1),chr(0xb5),chr(0xb9),chr(0xbb),chr(0xbe),chr(0xc2),chr(0xc3),chr(0xc5),chr(0xc8),chr(0xcc),chr(0xd0),chr(0xd2),chr(0xd6),chr(0xdb),chr(0xde),chr(0xe3),chr(0xe7) );
    $payload = "";
    $row = 0;

    $post_array = [];
    for ( $pos=0; $pos < $post_data_len; $pos ++ ) {
        $post_array[] = ord(substr($post_data, $pos));
    }

    header('Content-Type: application/octet-stream');
    if( $isWebEmulator)
        header('Access-Control-Allow-Origin: *');

    $xml = simplexml_load_file( "https://none-public-API-url-here" );
 
    $page = $post_array[0];
    $startelem = $page * 4;
    $elements = count($xml->Grid->item);
    while($startelem > ($elements - 4) ){
        $startelem -= $elements;
    }
    $counter = 0;
    foreach($xml->Grid->item as $item){
      $counter++;
      if($counter > $startelem && $row < 5 && $item->attributes()["type"] == "TOITeaser"){
        $title = str_replace($umlaute, $uml, $item->Title->__toString() );
        $payload .= str_pad(substr( $title, 0, 36), 36); // Padding right with spaces
        $row++;
      }
    }
    
    // encode for VCS
    $payload2 = "";
    $strLen = strlen($payload);
    for ($i = 0; $i < $strLen; $i++){
        $payload2 .= in_array(strtoupper($payload[$i]), $find)?$replace[array_search(strtoupper($payload[$i]),  $find)]:chr(0xa9) ;
    }

    echo chr(strlen($payload2)).$payload2;
}else if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Headers: PlusStore-ID,Content-Type');
}else{
    echo "Wrong Request Method!\r\n";
}

?>