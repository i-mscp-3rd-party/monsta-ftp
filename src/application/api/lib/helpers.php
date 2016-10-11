<?php
    require_once(dirname(__FILE__) . "/../constants.php");

    if(!MONSTA_DEBUG)
        includeMonstaConfig();

    function monstaGetTempDirectory() {
        // a more robust way of getting the temp directory

        $configTempDir = defined("MONSTA_TEMP_DIRECTORY") ? MONSTA_TEMP_DIRECTORY : "";

        if($configTempDir != "")
            return $configTempDir;

        return ini_get('upload_tmp_dir') ? ini_get('upload_tmp_dir') : sys_get_temp_dir();
    }

    function generateRandomString($length) {
        $characters = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
        $charactersLength = strlen($characters);
        $randomString = '';
        for ($i = 0; $i < $length; $i++)
            $randomString .= $characters[rand(0, $charactersLength - 1)];

        return $randomString;
    }