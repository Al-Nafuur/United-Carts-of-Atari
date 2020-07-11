<?php

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $options = array('cache_dir' => 'combat');
    $cache = new FileCache($options);
    $active_users = $cache->get( "active_combat_users"  );
    $isWebEmulator =  (strpos( $device_id, " WE") !== false );
    if(!$active_users)
        $active_users = array();

    $post_data = file_get_contents("php://input");
    $post_data_len = strlen($post_data);

    $PlusStoreId = $_SERVER['HTTP_PLUSSTORE_ID'];

    header('Content-Type: application/octet-stream');
    if( $isWebEmulator)
        header('Access-Control-Allow-Origin: *');

    if($post_data_len == 2){ // login / start request
        if(! array_key_exists($PlusStoreId, $active_users ) ){ // new user !!
            if(empty ($active_users ) || count($active_users) % 2 == 0 ){ // even amount of users.. new game
                $active_users[$PlusStoreId] = ["isMaster" => 1, "gameActive" => 0, "M_SWCHA" => 240, "S_SWCHA" => 15, "INPT4" => 128, "INPT5" => 128    ];
            }else{ // odd ammount -> a opponent is waiting
                $opponent = array_key_last($active_users);
                $active_users[$PlusStoreId] = ["isMaster" => 0, "gameActive" => 1, "opponent" => $opponent ];
                $active_users[$opponent]["gameActive"] = 1;
                $active_users[$opponent]["opponent"] = $PlusStoreId;
            }
            echo chr(3).chr(255).chr(128).chr(128); // First byte ist Content-Length of the rest..
        }else if( $active_users[$PlusStoreId]["gameActive"] == 0  ){ // game inactive !!
            echo chr(3).chr(255).chr(128).chr(128); // First byte ist Content-Length of the rest..
        }else{
            if($active_users[$PlusStoreId]["isMaster"] == 1){
                $master =& $active_users[$PlusStoreId];
                $master["M_SWCHA"] = (ord(substr($post_data, 0)) & 0xF0);
                $master["INPT4"] = ord(substr($post_data, 1));
            }else{
                $master =& $active_users[$active_users[$PlusStoreId]["opponent"]];
                $master["S_SWCHA"] = ( ord(substr($post_data, 0)) >> 4 );
                $master["INPT5"] = ord(substr($post_data, 1));
            }
            $SWCHA = (int)($master["M_SWCHA"] | $master["S_SWCHA"]);
            echo chr(3).chr( $SWCHA ).chr($master["INPT4"]).chr($master["INPT5"]);
        }
        $cache->save( "active_combat_users" , $active_users, 1800 ); // cache for 30 minutes
    }
}else if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Headers: PlusStore-ID,Content-Type');
}else{
    echo "Wrong Request Method!\r\n";
}




/**
 * FileCache
 *
 * http://github.com/inouet/file-cache/
 *
 * A simple PHP class for caching data in the filesystem.
 *
 * License
 *   This software is released under the MIT License, see LICENSE.txt.
 *
 * @package FileCache
 * @author  Taiji Inoue <inudog@gmail.com>
 * 
 * added base_cache_dir and mkdir if cache_dir does not exist
 * by Wolfgang Stubig <w.stubig@firmaplus.de>
 * 
 */

class FileCache
{
    
    /**
     * The root cache directory.
     * @var string
     */
    private $base_cache_dir = __DIR__ . '/cache';
    private $cache_dir = '';

    /**
     * Creates a FileCache object
     *
     * @param array $options
     */
    public function __construct(array $options = array())
    {
        $available_options = array('cache_dir');
        foreach ($available_options as $name) {
            if (isset($options[$name])) {
                $this->$name = $options[$name];
            }
        }
        $dir = $this->getCacheDirectory();
        if (!is_dir($dir)) {
            mkdir($dir, 0755, true);
        }
    }

    /**
     * Fetches an entry from the cache.
     *
     * @param string $id
     */
    public function get($id)
    {
        $file_name = $this->getFileName($id);

        if (!is_file($file_name) || !is_readable($file_name)) {
            return false;
        }

        $lines    = file($file_name);
        $lifetime = array_shift($lines);
        $lifetime = (int) trim($lifetime);

        if ($lifetime !== 0 && $lifetime < time()) {
            @unlink($file_name);
            return false;
        }
        $serialized = join('', $lines);
        $data       = unserialize($serialized);
        return $data;
    }

    /**
     * Deletes a cache entry.
     *
     * @param string $id
     *
     * @return bool
     */
    public function delete($id)
    {
        $file_name = $this->getFileName($id);
        return unlink($file_name);
    }

    /**
     * Puts data into the cache.
     *
     * @param string $id
     * @param mixed  $data
     * @param int    $lifetime
     *
     * @return bool
     */
    public function save($id, $data, $lifetime = 3600)
    {
        $dir = $this->getDirectory($id);
        if (!is_dir($dir)) {
            if (!mkdir($dir, 0755, true)) {
                return false;
            }
        }
        $file_name  = $this->getFileName($id);
        $lifetime   = time() + $lifetime;
        $serialized = serialize($data);
        $result     = file_put_contents($file_name, $lifetime . PHP_EOL . $serialized);
        if ($result === false) {
            return false;
        }
        return true;
    }

    //------------------------------------------------
    // PRIVATE METHODS
    //------------------------------------------------

    /**
     * Fetches a directory to store the cache data
     *
     * @param string $id
     *
     * @return string
     */
    protected function getDirectory($id)
    {
        $hash = sha1($id, false);
        $dirs = array(
            $this->getCacheDirectory(),
            substr($hash, 0, 2),
            substr($hash, 2, 2)
        );
        return join(DIRECTORY_SEPARATOR, $dirs);
    }

    /**
     * Fetches a base directory to store the cache data
     *
     * @return string
     */
    protected function getCacheDirectory()
    {
        return $this->base_cache_dir . DIRECTORY_SEPARATOR . $this->cache_dir;
    }

    /**
     * Fetches a file path of the cache data
     *
     * @param string $id
     *
     * @return string
     */
    protected function getFileName($id)
    {
        $directory = $this->getDirectory($id);
        $hash      = sha1($id, false);
        $file      = $directory . DIRECTORY_SEPARATOR . $hash . '.cache';
        return $file;
    }
}

?>