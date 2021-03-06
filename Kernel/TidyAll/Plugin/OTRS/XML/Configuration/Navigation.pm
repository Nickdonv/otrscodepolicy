# --
# Copyright (C) 2001-2017 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package TidyAll::Plugin::OTRS::XML::Configuration::Navigation;

use strict;
use warnings;

use parent qw(TidyAll::Plugin::OTRS::Base);

sub validate_source {    ## no critic
    my ( $Self, $Code ) = @_;

    return $Code if $Self->IsPluginDisabled( Code => $Code );
    return if $Self->IsFrameworkVersionLessThan( 6, 0 );

    my ( $Counter, $ErrorMessage );

    my $CurrentSettingName;

    LINE:
    for my $Line ( split /\n/, $Code ) {
        $Counter++;

        if ( $Line =~ m{<Setting\s+Name="(.*?)"}smx ) {
            $CurrentSettingName = $1;
        }
        my ($NavigationContent) = $Line =~ m{<Navigation>(.*?)</Navigation>}smx;

        next LINE if !$NavigationContent;

        my @Rules = (
            {
                Name                   => 'Valid toplevel entries',
                MatchSettingName       => qr{.*},
                MatchNavigationValue   => qr{.*},
                RequireNavigationMatch => qr{^(CloudService|Core|Daemon|GenericInterface|Frontend)(::|$)},
                ErrorMessage =>
                    'Invalid top level group found (only CloudService|Core|Daemon|GenericInterface|Frontend are allowed).',
            },
            {
                Name                   => 'Event handlers',
                MatchSettingName       => qr{::EventModule},
                MatchNavigationValue   => qr{.*},
                RequireNavigationMatch => qr{^Core::Event::},
                ErrorMessage           => "Event handler registrations should be grouped in 'Core::Event::*.",
            },
            {
                Name                 => 'Valid Frontend subgroups',
                MatchSettingName     => qr{.*},
                MatchNavigationValue => qr{^Frontend},                # no entries allowed in "Frontend" directly
                RequireNavigationMatch => qr{^Frontend::(Admin|Agent|Base|Customer|Public)(::|$)},
                ErrorMessage =>
                    'Invalid top Frontend subgroup found (only Admin|Agent|Base|Customer|Public are allowed).',
            },
            {
                Name                   => 'Main Loader config',
                MatchSettingName       => qr{^Loader::(Agent|Customer|Enabled)},
                MatchNavigationValue   => qr{.*},
                RequireNavigationMatch => qr{^Frontend::Base::Loader$},
                ErrorMessage           => "Main Loader settings should be grouped in 'Frontend::Base::Loader'.",
            },
            {
                Name                   => 'Loader config for Admin interface',
                MatchSettingName       => qr{^Loader::Module::Admin},
                MatchNavigationValue   => qr{.*},
                RequireNavigationMatch => qr{^Frontend::Admin::ModuleRegistration::Loader},
                ErrorMessage =>
                    "Loader config for Admin interface should be grouped in 'Frontend::Admin::ModuleRegistration::Loader'.",
            },
            {
                Name                   => 'Loader config for Agent interface',
                MatchSettingName       => qr{^Loader::Module::Agent},
                MatchNavigationValue   => qr{.*},
                RequireNavigationMatch => qr{^Frontend::Agent::ModuleRegistration::Loader},
                ErrorMessage =>
                    "Loader settings for Agent interface should be grouped in 'Frontend::Agent::ModuleRegistration::Loader'.",
            },
            {
                Name                   => 'Loader config for Customer interface',
                MatchSettingName       => qr{^Loader::Module::Customer},
                MatchNavigationValue   => qr{.*},
                RequireNavigationMatch => qr{^Frontend::Customer::ModuleRegistration::Loader},
                ErrorMessage =>
                    "Loader settings for Customer interface should be grouped in 'Frontend::Customer::ModuleRegistration::Loader'.",
            },
            {
                Name                   => 'Loader config for Public interface',
                MatchSettingName       => qr{^Loader::Module::Public},
                MatchNavigationValue   => qr{.*},
                RequireNavigationMatch => qr{^Frontend::Public::ModuleRegistration},
                ErrorMessage =>
                    "Loader settings for Public interface should be grouped in 'Frontend::Public::ModuleRegistration'.",
            },
            {
                Name                   => 'Frontend navigation config for Admin interface',
                MatchSettingName       => qr{^Frontend::Navigation###Admin},
                MatchNavigationValue   => qr{.*},
                RequireNavigationMatch => qr{^Frontend::Admin::ModuleRegistration::MainMenu},
                ErrorMessage =>
                    "Frontend navigation config for Admin interface should be grouped in 'Frontend::Admin::ModuleRegistration::MainMenu'.",
            },
            {
                Name                   => 'Frontend navigation config for Agent interface',
                MatchSettingName       => qr{^Frontend::Navigation###Agent},
                MatchNavigationValue   => qr{.*},
                RequireNavigationMatch => qr{^Frontend::Agent::ModuleRegistration::MainMenu},
                ErrorMessage =>
                    "Frontend navigation config for Agent interface should be grouped in 'Frontend::Agent::ModuleRegistration::MainMenu'.",
            },
            {
                Name                   => 'Frontend navigation config for Customer interface',
                MatchSettingName       => qr{^CustomerFrontend::Navigation###Customer},
                MatchNavigationValue   => qr{.*},
                RequireNavigationMatch => qr{^Frontend::Customer::ModuleRegistration::MainMenu},
                ErrorMessage =>
                    "Frontend navigation config for Customer interface should be grouped in 'Frontend::Customer::ModuleRegistration::MainMenu'.",
            },
            {
                Name                   => 'Frontend navigation config for Public interface',
                MatchSettingName       => qr{^PublicFrontend::(Module|Navigation)},
                MatchNavigationValue   => qr{.*},
                RequireNavigationMatch => qr{^Frontend::Public::ModuleRegistration},
                ErrorMessage =>
                    "Module registration config for Public interface should be grouped in 'Frontend::Public::ModuleRegistration'.",
            },
            {
                Name                   => 'Navigation module config',
                MatchSettingName       => qr{^Frontend::NavigationModule},
                MatchNavigationValue   => qr{.*},
                RequireNavigationMatch => qr{^Frontend::Admin::ModuleRegistration::AdminOverview},
                ErrorMessage =>
                    "Navigation module config should be grouped in 'Frontend::Admin::ModuleRegistration::AdminOverview'.",
            },
            {
                Name                   => 'Search router config for Admin interface',
                MatchSettingName       => qr{^Frontend::Search.*?###Admin},
                MatchNavigationValue   => qr{.*},
                RequireNavigationMatch => qr{^Frontend::Admin::ModuleRegistration::MainMenu::Search},
                ErrorMessage =>
                    "Search router config for Admin interface should be grouped in 'Frontend::Admin::ModuleRegistration::Search'.",
            },
            {
                Name                   => 'Search router config for Agent interface',
                MatchSettingName       => qr{^Frontend::Search.*?###Agent},
                MatchNavigationValue   => qr{.*},
                RequireNavigationMatch => qr{^Frontend::Agent::ModuleRegistration::MainMenu::Search},
                ErrorMessage =>
                    "Search router config for Agent interface should be grouped in 'Frontend::Agent::ModuleRegistration::Search'.",
            },
            {
                Name                   => 'Output filters',
                MatchSettingName       => qr{(Output::Filter|OutputFilter)},
                MatchNavigationValue   => qr{.*},
                RequireNavigationMatch => qr{^Frontend::Base::OutputFilter},
                ErrorMessage =>
                    "Output filter settings should be grouped in 'Frontend::Base::OutputFilter' or subgroups.",
            },
            {
                Name                   => 'Valid frontend views',
                MatchSettingName       => qr{.*},
                MatchNavigationValue   => qr{^Frontend::(Admin|Agent|Customer|Public)::(.+::)*View.+$},
                RequireNavigationMatch => qr{^Frontend::(Admin|Agent|Customer|Public)::View::.+$},
                ErrorMessage =>
                    "Screen specific seettings should be added in Frontend::(Admin|Agent|Customer|Public)::View.",
            },
        );

        RULE:
        for my $Rule (@Rules) {
            next RULE if $CurrentSettingName !~ $Rule->{MatchSettingName};
            next RULE if $NavigationContent !~ $Rule->{MatchNavigationValue};

            if ( $NavigationContent !~ $Rule->{RequireNavigationMatch} ) {
                $ErrorMessage
                    .= "Invalid navigation value found for setting $CurrentSettingName: $Rule->{ErrorMessage}\n";
                $ErrorMessage .= "Line $Counter: $Line\n";
            }
        }
    }

    if ($ErrorMessage) {
        die __PACKAGE__ . "\n" . <<EOF;
Problems were found in the navigation structure of the XML configuration:
$ErrorMessage
EOF
    }

    return;
}

1;
