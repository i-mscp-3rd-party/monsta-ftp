<?php

    require_once(dirname(__FILE__) . '/Exceptions.php');

    class LicenseReader {
        private $keyPairSuite;

        public function __construct($keyPairSuite) {
            $this->keyPairSuite = $keyPairSuite;
        }

        public function readLicense($licensePath) {
            if(!file_exists($licensePath))
                return null;

            $encodedData = $this->extractEncodedDataFromLicense(file_get_contents($licensePath));

            try{
                $rawLicenseData = $this->keyPairSuite->base64DecodeAndDecrypt($encodedData);
            } catch (KeyPairException $e) {
                throw new InvalidLicenseException("Unable to read the license file at '$licensePath'.",
                    LocalizableExceptionDefinition::$LICENSE_READ_FAILED_ERROR, array('path' => $licensePath));
            }

            return json_decode($rawLicenseData, true);
        }

        public function extractEncodedDataFromLicense($licenseData) {
            $licenseLines = explode("\n", $licenseData);
            $encodedData = "";

            foreach ($licenseLines as $line) {
                if (trim($line) == "")
                    continue;

                if(strlen($line) > 2 && substr($line, 0, 1) == "=" && substr($line, -1, 1) == "=")
                    continue;

                $encodedData .= $line;
            }

            return $encodedData;
        }
    }