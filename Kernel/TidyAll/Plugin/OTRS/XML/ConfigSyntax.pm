# --
# Copyright (C) 2001-2017 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package TidyAll::Plugin::OTRS::XML::ConfigSyntax;

use strict;
use warnings;

use parent qw(TidyAll::Plugin::OTRS::Base);

use XML::Parser;

# This plugin does not transform any files. Following method is implemented only because it's executed before
#   validate_source and contains filename of the file. Filename is saved in $Self for later use.
sub transform_file {    ## no critic
    my ( $Self, $Filename ) = @_;

    # Store filename for later use.
    $Self->{Filename} = $Filename;

    return;
}

sub validate_source {    ## no critic
    my ( $Self, $Code ) = @_;

    return if $Self->IsPluginDisabled( Code => $Code );
    return if $Self->IsFrameworkVersionLessThan( 2, 4 );

    my $ErrorMessage;
    my $Counter;

    for my $Line ( split /\n/, $Code ) {
        $Counter++;

        # Check first XML line
        if ( $Counter == 1 ) {
            if (
                $Line !~ /^<\?xml.+\?>/
                || $Line !~ /version=["'']1.[01]["']/
                || $Line !~ /encoding=["'](?:iso-8859-1|utf-8)["']/i
                )
            {
                $ErrorMessage
                    .= "The first line of the file should have the content <?xml version=\"1.0\" encoding=\"utf-8\" ?>.\n";
                $ErrorMessage .= "Line $Counter: $Line\n";
            }
        }

        # Validate otrs_config tag
        if ( $Line =~ /^<otrs_config/ ) {

            if ( $Self->IsFrameworkVersionLessThan( 6, 0 ) ) {
                if (
                    $Line !~ /init="(Framework|Application|Config|Changes)"/
                    || $Line !~ /version="1.0"/
                    )
                {
                    $ErrorMessage
                        .= "The <otrs_config>-tag has missing or incorrect attributes. ExampleLine: <otrs_config version=\"1.0\" init=\"Application\">\n";
                    $ErrorMessage .= "Line $Counter: $Line\n";
                }
            }
            else {
                my $Version = '2.0';

                # TODO: Consider removing the exception below.
                #   Allow 1.0 version attribute for old-style files located outside XML folder.
                if ( $Self->{Filename} !~ qr{/Config/Files/XML/} ) {
                    $Version = '1.0';
                }

                if (
                    $Line !~ /init="(Framework|Application|Config|Changes)"/
                    || $Line !~ /version="$Version"/
                    )
                {
                    $ErrorMessage
                        .= "The <otrs_config>-tag has missing or incorrect attributes. ExampleLine: <otrs_config version=\"2.0\" init=\"Application\">\n";
                    $ErrorMessage .= "Line $Counter: $Line\n";
                }
            }
        }
    }

    if ($ErrorMessage) {
        die __PACKAGE__ . "\n$ErrorMessage";
    }
}

1;
