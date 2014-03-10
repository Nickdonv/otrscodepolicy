# --
# TidyAll/Plugin/OTRS/XML/Lint.pm - code quality plugin
# Copyright (C) 2001-2014 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package TidyAll::Plugin::OTRS::XML::Lint;

use strict;
use warnings;

use Capture::Tiny qw(capture_merged);
use base qw(TidyAll::Plugin::OTRS::Base);

sub _build_cmd {    ## no critic
    return 'xmllint --noout --nonet'
}

sub validate_file {    ## no critic
    my ( $Self, $Filename ) = @_;

    return if $Self->IsPluginDisabled( Filename => $Filename );

    my $Command = sprintf( "%s %s %s", $Self->cmd(), $Self->argv(), $Filename );
    my ( $Output, @Result ) = capture_merged { system($Command) };

    # if execution failed, warn about installing package
    if ( $Result[0] == -1 ) {
        print STDERR "'xmllint' is not installed.\n";
        print STDERR
            "You can install this using 'apt-get install libxml2-utils' package on Debian-based systems.\n\n";
    }

    if ( @Result && $Result[0] ) {
        die __PACKAGE__ . "\n$Output\n";    # non-zero exit code
    }
}

1;