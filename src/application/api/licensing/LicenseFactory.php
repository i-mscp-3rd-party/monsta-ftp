<?php

    require_once(dirname(__FILE__) . '/MonstaLicenseV1.php');

    class LicenseFactory {
        public static function getMonstaLicenseV1($email, $purchaseDate, $expiryDate, $version){
            return new MonstaLicenseV1($email, $purchaseDate, $expiryDate, $version);
        }
    }