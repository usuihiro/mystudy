#!/bin/env perl
package Test::OOP2;
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

    sub has_left_hand { 1 }
    sub has_right_hand { 1 }

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

        my ( $handA, $handB );
        if ( $self->has_right_hand && $friend->has_right_hand ) {
            $handA = $self->right_hand;
            $handB = $friend->right_hand;
        }
        elsif ( $self->has_left_hand && $friend->has_left_hand ) {
            $handA = $self->left_hand;
            $handB = $friend->left_hand;
        }
        else {
            die "Not enough hands to shake";
        }
        return "$handA shake $handB";
    }

    package Person::Veteran;
    use strict;
    use warnings;

    our @ISA = ( 'Person' );

    sub right_hand { die shift->name . " lost their hand in the war" }

    sub has_left_hand { 1 }
    sub has_right_hand { 0 }
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
    is( $bob->handshake( $joe ), "Bob-left_hand shake Joe-left_hand", "Shook hands" );
};

1;
