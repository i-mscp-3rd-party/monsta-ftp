=head1 NAME

 Package::WebFtpClients::MonstaFTP::Handler - i-MSCP MonstaFTP package handler

=cut

# i-MSCP - internet Multi Server Control Panel
# Copyright (C) 2010-2019 Laurent Declercq <l.declercq@nuxwin.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

package Package::WebFtpClients::MonstaFTP::Handler;

use strict;
use warnings;
use File::Spec;
use File::Temp;
use iMSCP::Boolean;
use iMSCP::Cwd '$CWD';
use iMSCP::Debug 'error';
use iMSCP::Dir;
use iMSCP::EventManager;
use iMSCP::Execute 'execute';
use iMSCP::File;
use iMSCP::TemplateParser qw/ getBloc replaceBloc process /;
use JSON;
use parent 'Common::Object';

=head1 DESCRIPTION

 i-MSCP MonstaFTP package handler.

=head1 PUBLIC METHODS

=over 4

=item preinstall( )

 Pre-installation tasks

 Return int 0 on success, other on failure

=cut

sub preinstall
{
    my ( $self ) = @_;

    $self->{'events'}->register(
        'afterFrontEndBuildConfFile', \&afterFrontEndBuildConfFile
    );
}

=item install( )

 Installation tasks

 Return int 0 on success, other on failure

=cut

sub install
{
    my ( $self ) = @_;

    local $CWD = $::imscpConfig{'GUI_ROOT_DIR'};

    my $rs = $self->_buildConfigFiles();
    $rs ||= $self->_buildHttpdConfigFile();
    $rs ||= $self->_applyPatches();
}

=item postinstall( )

 Post-installation tasks

 Return int 0 on success, other on failure

=cut

sub postinstall
{
    local $CWD = $::imscpConfig{'GUI_ROOT_DIR'};

    if ( -l "$CWD/public/tools/monstaftp" ) {
        my $rs = iMSCP::File->new(
            filename => "$CWD/public/tools/monstaftp"
        )->delFile();
        return $rs if $rs;
    }

    unless ( symlink( File::Spec->abs2rel(
        "$CWD/vendor/imscp/monsta-ftp/mftp", "$CWD/public/tools"
    ),
        "$CWD/public/tools/monstaftp"
    ) ) {
        error( sprintf(
            "Couldn't create symlink for MonstaFTP Web-based FTP client"
        ));
        return 1;
    }

    0;
}

=item uninstall( )

 Uninstallation tasks

 Return int 0 on success, other on failure

=cut

sub uninstall
{
    local $CWD = $::imscpConfig{'GUI_ROOT_DIR'};

    if ( -l "$CWD/public/tools/monstaftp" ) {
        my $rs = iMSCP::File->new(
            filename => "$CWD/public/tools/monstaftp"
        )->delFile();
        return $rs if $rs;
    }

    if ( -f '/etc/nginx/imscp_monstaftp.conf' ) {
        my $rs = iMSCP::File->new(
            filename => '/etc/nginx/imscp_monstaftp.conf'
        )->delFile();
        return $rs if $rs;
    }

    0;
}

=back

=head1 EVENT LISTENERS

=over 4

=item afterFrontEndBuildConfFile( )

 Event listener that injects Httpd configuration for MonstaFTP into the i-MSCP
 control panel Nginx vhost files

 Return int 0 on success, other on failure

=cut

sub afterFrontEndBuildConfFile
{
    my ( $tplContent, $tplName ) = @_;

    return 0 unless grep (
        $_ eq $tplName, '00_master.nginx', '00_master_ssl.nginx'
    );

    ${ $tplContent } = replaceBloc(
        "# SECTION custom BEGIN.\n",
        "# SECTION custom END.\n",
        "    # SECTION custom BEGIN.\n"
            . getBloc(
                "# SECTION custom BEGIN.\n",
                "# SECTION custom END.\n",
                ${ $tplContent }
            )
            . "    include imscp_monstaftp.conf;\n"
            . "    # SECTION custom END.\n",
        ${ $tplContent }
    );

    0;
}

=back

=head1 PRIVATE METHODS

=over 4

=item _init( )

 Initialize instance

 Return Package::WebFtpClients::MonstaFTP::Handler

=cut

sub _init
{
    my ( $self ) = @_;

    $self->{'events'} = iMSCP::EventManager->getInstance();
    $self;
}

=item _buildConfigFiles( )

 Build PhpMyadminConfiguration files 

 Return int 0 on success, other on failure
  
=cut

sub _buildConfigFiles
{
    my ( $self ) = @_;

    my $rs = eval {
        # Main configuration file

        my $data = {
            TIMEZONE => ::setupGetQuestion( 'TIMEZONE' ),
            TMP_DIR  => "$::imscpConfig{'GUI_ROOT_DIR'}/data/tmp"
        };

        my $rs = $self->{'events'}->trigger(
            'onLoadTemplate', 'monstaftp', 'config.php', \my $cfgTpl, $data
        );
        return $rs if $rs;

        unless ( defined $cfgTpl ) {
            $cfgTpl = iMSCP::File->new(
                filename => './vendor/imscp/monsta-ftp/src/config.php'
            )->get();
            return 1 unless defined $cfgTpl;
        }

        $cfgTpl = process( $data, $cfgTpl );

        my $file = iMSCP::File->new(
            filename => './vendor/imscp/monsta-ftp/mftp/settings/config.php'
        );
        $file->set( $cfgTpl );
        $rs = $file->save();
        return $rs if $rs;

        # settings.json configuration file

        $data = {
            showDotFiles            => JSON::true,
            language                => 'en_us',
            editNewFilesImmediately => JSON::true,
            editableFileExtensions  => 'txt,htm,html,php,asp,aspx,js,css,xhtml,cfm,pl,py,c,cpp,rb,java,xml,json',
            hideProUpgradeMessages  => JSON::true,
            disableMasterLogin      => JSON::true,
            connectionRestrictions  => {
                types => [
                    'ftp'
                ],
                ftp   => {
                    host             => '127.0.0.1',
                    port             => 21,
                    # Enable passive mode excepted if the FTP daemon is vsftpd
                    # vsftpd doesn't allows to operate on a per IP basic (IP masquerading)
                    passive          => $::imscpConfig{'FTPD_SERVER'} eq 'vsftpd'
                        ? JSON::false
                        : JSON::true,
                    ssl              => ::setupGetQuestion( 'SERVICES_SSL_ENABLED' ) eq 'yes'
                        ? JSON::true
                        : JSON::false,
                    initialDirectory => '/'
                }
            }
        };

        undef $cfgTpl;
        $rs = $self->{'events'}->trigger(
            'onLoadTemplate', 'monstaftp', 'settings.json', \$cfgTpl, $data
        );
        return $rs if $rs;

        $file = iMSCP::File->new(
            filename => './vendor/imscp/monsta-ftp/mftp/settings/settings.json'
        );
        $file->set( $cfgTpl || JSON
            ->new()
            ->utf8( TRUE )
            ->pretty( TRUE )
            ->encode( $data )
        );
        $rs = $file->save();
    };
    if ( $@ ) {
        error( $@ );
        return 1;
    }

    $rs;
}

=item _buildHttpdConfigFile( )

 Build httpd configuration file for MonstaFTP 

 Return int 0 on success, other on failure

=cut

sub _buildHttpdConfigFile
{
    my $rs = iMSCP::File->new(
        filename => "$CWD/vendor/imscp/monsta-ftp/src/nginx.conf"
    )->copyFile( '/etc/nginx/imscp_monstaftp.conf' );
    return $rs if $rs;

    my $file = iMSCP::File->new(
        filename => '/etc/nginx/imscp_monstaftp.conf'
    );
    return 1 unless defined( my $fileC = $file->getAsRef());

    ${ $fileC } = process( { GUI_ROOT_DIR => $CWD }, ${ $fileC } );

    $file->save();
}

=item _applyPatches( )

 Apply patches on MonstaFTP sources
 
 Return int 0 on success, other on failure

=cut

sub _applyPatches
{
    return 0 if -f './vendor/imscp/monsta-ftp/src/patches/.patched';

    local $CWD = './vendor/imscp/monsta-ftp';

    for my $patch (
        iMSCP::Dir->new( dirname => './src/patches' )->getFiles()
    ) {
        my $rs = execute(
            [
                '/usr/bin/git',
                'apply', '--verbose', '-p0', "./src/patches/$patch"
            ],
            \my $stdout,
            \my $stderr
        );
        debug( $stdout ) if length $stdout;
        error( $stderr || 'Unknown error' ) if $rs;
        return $rs if $rs;
    }

    iMSCP::File->new( filename => './src/patches/.patched' )->save();
}

=back

=head1 AUTHOR

 Laurent Declercq <l.declercq@nuxwin.com>

=cut

1;
__END__
