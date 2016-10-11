<?php

// GENERAL VARIABLES //

$configPathSettings = dirname(__FILE__) . '/settings.json';
$configTimeZone = '{TIMEZONE}';
$configTempDir = '{TMP_PATH}';
$configMaxFileSize = '1024M';
$configMaxExecutionTimeSeconds = 1800;

// DEFINE THE VARIABLES //

define('APPLICATION_SETTINGS_PATH', $configPathSettings);
define('MONSTA_TEMP_DIRECTORY', $configTempDir);
define('AUTHENTICATION_FILE_PATH', '');
define('MONSTA_LICENSE_PATH', '');

date_default_timezone_set($configTimeZone);
ini_set('memory_limit', $configMaxFileSize);
ini_set('max_execution_time', $configMaxExecutionTimeSeconds);
