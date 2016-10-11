<?php

    require_once(dirname(__FILE__) . '/ProPackageIDGenerator.php');

    class ProPackageBuilder {
        private $licenseData;
        private $proConfigPath;
        private $htaccessPath;

        public function __construct($licenseData, $proConfigPath, $htaccessPath) {
            $this->licenseData = $licenseData;
            $this->proConfigPath = $proConfigPath;
            $this->htaccessPath = $htaccessPath;
        }

        public function buildLicenseZip($archivePath, $salt, $emailAddress) {
            $packageIDGenerator = new ProPackageIDGenerator($salt);
            $proPackageID = $packageIDGenerator->idFromEmail($emailAddress);
            $archive = new ZipArchive();
            $archive->open($archivePath, ZipArchive::CREATE);
            $this->addIndexHtmlToZip($archive);
            $this->addHtaccessToZip($archive);
            $this->addEmptyProfileToZip($archive, $proPackageID);
            $this->addLicenseToZip($archive, $proPackageID);
            $this->addConfigToZip($archive, $proPackageID);
            $archive->close();
        }

        private function renderProConfig($proPackageID) {
            $rawContents = file_get_contents($this->proConfigPath);

            $profileLocalPath = $this->generateRelativeProfilePath($proPackageID);
            $licenseLocalPath = $this->generateRelativeLicensePath($proPackageID);

            return sprintf($rawContents, $profileLocalPath, $licenseLocalPath);
        }

        private function addIndexHtmlToZip($archive) {
            $archive->addFromString("license/index.html", "");
        }

        private function addHtaccessToZip($archive) {
            $archive->addFile($this->htaccessPath, "license/.htaccess");
        }

        private function generateRelativeProfilePath($proPackageID) {
            return sprintf("profiles-%s.bin", $proPackageID);
        }

        private function generateRelativeLicensePath($proPackageID) {
            return sprintf("license-%s.key", $proPackageID);
        }

        private function addEmptyProfileToZip($archive, $proPackageID) {
            $profileLocalPath = $this->generateRelativeProfilePath($proPackageID);
            $archive->addFromString("license/" . $profileLocalPath, "");
        }

        private function addLicenseToZip($archive, $proPackageID){
            $licenseLocalPath = $this->generateRelativeLicensePath($proPackageID);
            $archive->addFromString("license/" . $licenseLocalPath, $this->licenseData);
        }

        private function addConfigToZip($archive, $proPackageID) {
            $renderedConfig = $this->renderProConfig($proPackageID);
            $archive->addFromString("license/config_pro.php", $renderedConfig);
        }
    }