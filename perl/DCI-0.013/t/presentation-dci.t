#!/bin/env perl
package Test::DCI2;
use strict;
use warnings;

use Fennec;

{
    package ORM::Base;
    use strict;
    use warnings;

    sub new {
        my $class = shift;
        my %params = @_;
        return bless \%params, $class;
    }

    sub param {
        my $self = shift;
        my $param = shift;
        ( $self->{ $param } ) = @_ if @_;
        return $self->{ $param };
    }

    #####
    package Person;
    use strict;
    use warnings;
    our @ISA = ( 'ORM::Base' );

    sub left_hand { shift->param('name') . "-left_hand" }
    sub right_hand { shift->param('name') . "-right_hand" }

    #####
    package Handshake;
    use strict;
    use warnings;
    use Carp qw/croak/;
    use DCI qw/Context/;

    sugar handshake => (
        method  => 'handshake',
        ordered => [qw/ personA personB /],
    );

    casting qw/personA personB/;

    sub handshake {
        my $self = shift;

        my $handA = $self->personA->right_hand;
        my $handB = $self->personB->right_hand;

        return "$handA shake $handB";
    }
}

Handshake->import( 'handshake' );

tests phase_1 => sub {
    my $bob = Person->new( name => 'Bob' );
    my $joe = Person->new( name => 'Joe' );
    is( handshake( $bob, $joe ), "Bob-right_hand shake Joe-right_hand", "Shook hands" );
    is( handshake( $joe, $bob ), "Joe-right_hand shake Bob-right_hand", "Shook hands" );
};

1;
