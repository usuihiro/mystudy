#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'DCI',
    license     => 'perl',
    dist_author => 'Chad Granum <exodist7@gmail.com>',
    create_readme => 1,
    requires => {
        'Carp'              => 0,
        'Scalar::Util'      => 0,
        'Exporter::Declare' => 0.105,
    },
    build_requires => {
        'Fennec' => '1.012',
    },
    meta_merge => {
        resources => {
            repository  => 'http://github.com/exodist/DCI',
            bugtracker  => 'http://github.com/exodist/DCI/issues',
        },
    }
);

$build->create_build_script;
