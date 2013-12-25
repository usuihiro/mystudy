#!/bin/env perl
package Test::OOP;
use strict;
use warnings;

use Fennec;

{
    package Person;
    use strict;
    use warnings;

    sub new {
        my $class = shift;
        my ( $name ) = @_;
        return bless { name => $name }, $class;
    }

    sub name { shift->{name} }

    sub left_hand {
        my $self = shift;
        return $self->name . "-left_hand";
    }

    sub right_hand {
        my $self = shift;
        return $self->name . "-right_hand";
    }

    sub handshake {
        my $self = shift;
        my ($friend) = @_;
        my $handA = $self->right_hand;
        my $handB = $friend->right_hand;
        return "$handA shake $handB";
    }

    package Person::Veteran;
    use strict;
    use warnings;

    our @ISA = ( 'Person' );

    sub right_hand { die shift->name . " lost their hand in the war" }

    sub handshake {
        my $self = shift;
        my ($friend) = @_;
        my $handA = $self->left_hand;
        my $handB = $friend->left_hand;
        return "$handA shake $handB";
    }
}

tests phase_1 => sub {
    my $bob = Person->new( 'Bob' );
    my $joe = Person->new( 'Joe' );
    is( $bob->handshake( $joe ), "Bob-right_hand shake Joe-right_hand", "Shook hands" );
    is( $joe->handshake( $bob ), "Joe-right_hand shake Bob-right_hand", "Shook hands" );
};

tests phase_2 => sub {
    my $bob = Person->new( 'Bob' );
    my $joe = Person::Veteran->new( 'Joe' );
    is( $joe->handshake( $bob ), "Joe-left_hand shake Bob-left_hand", "Shook hands" );

    # It is very easy to overlook writing this extra test. It is an interaction
    # that may not occur to a developer.
    throws_ok {
        is( $bob->handshake( $joe ), "Bob-right_hand shake Joe-right_hand", "Shook hands" );
    } qr/Joe lost their hand in the war/, "Expected exception for example";
};

1;
