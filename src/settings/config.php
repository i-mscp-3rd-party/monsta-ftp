<?php

    // Before changing these variables please view the README at
    // http://redirect.monstaftp.com/readme
    // Further settings are available in "settings.json"

    // GENERAL VARIABLES //

    $configPathSettings = dirname(__FILE__) . "/settings.json";
    $configTimeZone = "UTC";
    $configTempDir = "";
    $configMaxFileSize = "1024M";
    $configMaxExecutionTimeSeconds = 1800;

    // DEFINE THE VARIABLES //

    define("APPLICATION_SETTINGS_PATH", $configPathSettings);
    define("MONSTA_TEMP_DIRECTORY", $configTempDir);
    date_default_timezone_set($configTimeZone);
    ini_set('memory_limit', $configMaxFileSize);
    ini_set('max_execution_time', $configMaxExecutionTimeSeconds);

    $proConfigurationPath = dirname(__FILE__) . "/../license/config_pro.php";

    if(file_exists($proConfigurationPath))
        require_once($proConfigurationPath);
    else {
        define("AUTHENTICATION_FILE_PATH", "");
        define("MONSTA_LICENSE_PATH", "");
    }
