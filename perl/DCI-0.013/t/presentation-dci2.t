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
    package Person::Veteran;
    use strict;
    use warnings;
    our @ISA = ( 'ORM::Base' );

    sub left_hand { shift->param('name') . "-tattooed_left_hand" }

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
        my $hand_method = $self->hand_method;

        my $handA = $self->personA->$hand_method;
        my $handB = $self->personB->$hand_method;

        return "$handA shake $handB";
    }

    sub hand_method {
        my $self = shift;

        for my $method ( qw/right_hand left_hand/ ) {
            return $method
                if $self->personA->can( $method )
                && $self->personB->can( $method )
        }

        croak "No common hand";
    }
}

Handshake->import( 'handshake' );

tests phase_1 => sub {
    my $bob = Person->new( name => 'Bob' );
    my $joe = Person->new( name => 'Joe' );
    is( handshake( $bob, $joe ), "Bob-right_hand shake Joe-right_hand", "Shook hands" );
    is( handshake( $joe, $bob ), "Joe-right_hand shake Bob-right_hand", "Shook hands" );
};

tests phase_2 => sub {
    my $bob = Person->new( name => 'Bob' );
    my $joe = Person::Veteran->new( name => 'Joe' );
    is( handshake( $joe, $bob ), "Joe-tattooed_left_hand shake Bob-left_hand", "Shook hands" );
    is( handshake( $bob, $joe ), "Bob-left_hand shake Joe-tattooed_left_hand", "Shook hands" );
};

1;
