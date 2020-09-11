<?php

$active_user_id = $_SERVER['HTTP_PLUSSTORE_ID'];

if ($_SERVER['REQUEST_METHOD'] === 'POST' && $active_user_id) {
    $post_data = file_get_contents("php://input");
    $post_data_len = strlen($post_data);
    if($post_data_len > 1 ){  // clients must send at least 2 bytes payload
        $options = array('cache_dir' => 'combat');
        $cache = new FileCache($options);
        $active_user = $cache->get( $active_user_id );
        $isWebEmulator =  (strpos( $active_user_id, " WE") !== false );
    
        header('Content-Type: application/octet-stream');
        header('Content-Length: '.($post_data_len + 2));
        if( $isWebEmulator)
            header('Access-Control-Allow-Origin: *');

        if(!  $active_user  ){ // new user !!
            $waiting_user = $cache->get("waiting_user");
            // now check aktiv users
            if( $waiting_user ){                                                    //  an opponent is waiting 
                $cache->delete( "waiting_user");
                $active_user = ["isMaster" => 0, "gameActive" => 1, "opponent_id" => $waiting_user, "SWCHA" => 15, "INPT4" => 128 ];
                $master = $cache->get( $waiting_user );
                $master["gameActive"] = 1;
                $master["opponent_id"] = $active_user_id;
                $cache->save( $waiting_user, $master, 10 );                         // cache for 10 seconds !!
            }else{ // no user waiting -> new game
                $active_user = ["isMaster" => 1, "gameActive" => 0, "SWCHA" => 240, "INPT4" => 128  ];
                $cache->save( "waiting_user" , $active_user_id, 10 );               // cache waiting User for 10 seconds 
            }
            echo chr($post_data_len + 1).chr(255).chr(128).chr(128)
                 .substr($post_data, 2, ($post_data_len - 2));                      // First byte is Content-Length of the rest..
        }else if( $active_user["gameActive"] == 0  ){                               // game inactive user still waits for opponent !
            $cache->save( "waiting_user" , $active_user_id, 10 );                   // cache waiting User for 10 (more) seconds 
            echo chr($post_data_len + 1).chr(255).chr(128).chr(128)
                 .substr($post_data, 2, ($post_data_len - 2));                      // First byte is Content-Length of the rest..
        }else{
            $active_user["SWCHA"] = (ord($post_data[0]) & 0xF0);
            $active_user["INPT4"] = ord($post_data[1]);
            if($active_user["isMaster"] == 1){
                $master =& $active_user;
                $master["RAM"]  = substr($post_data, 2, ($post_data_len - 2) );
                $slave = $cache->get( $active_user["opponent_id"] );
                if(!$slave){                                                        // opponent is offline !
                    $waiting_user = $cache->get("waiting_user");
                    if($waiting_user){
                        $cache->delete( "waiting_user");
                        $active_user["opponent_id"] = $waiting_user;
                        $slave = $cache->get( $waiting_user );
                    }else{
                        $cache->save( "waiting_user" , $active_user_id, 10 );       // cache waiting User for 10 seconds 
                        $active_user["gameActive"] = 0;
                    }
                }
            }else{
                $slave =& $active_user;
                $master = $cache->get( $active_user["opponent_id"] );
                if(!$master){                                                        // opponent is offline !
                    $waiting_user = $cache->get("waiting_user");
                    if($waiting_user){
                        $cache->delete( "waiting_user");
                        $active_user["opponent_id"] = $waiting_user;
                        $master = $cache->get( $waiting_user );
                    }else{
                        $cache->save( "waiting_user" , $active_user_id, 10 );       // cache waiting User for 10 seconds 
                        $active_user["gameActive"] = 0;
                    }
                }
            }
            $SWCHA = (int)( ($master["SWCHA"] & 0xF0) | ($slave["SWCHA"]>> 4) );
            echo chr($post_data_len + 1).chr( $SWCHA ).chr($master["INPT4"]).chr($slave["INPT4"]).$master["RAM"];
        }
        $cache->save( $active_user_id , $active_user, 10 );                         // cache for 10 seconds !!
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