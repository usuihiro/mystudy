package Test::OOP::Intro::Example;
use strict;
use warnings;

use Fennec;
use Scalar::Util qw/blessed/;

use lib 'lib', 't/lib';
use Example::Number;
use Example::Integer;
use Example::Float;
use Example::Fraction;

{
    package Example::Number;
    use strict;
    use warnings;

    # sub add is defined by specific use-cases in the tests below.

    #############
    package Example::Fraction;
    use strict;
    use warnings;

    sub add {
        my $self = shift;
        my ( $other ) = @_;

        $other = __PACKAGE__->new( $other->evaluate )
            unless $other->isa( __PACKAGE__ );

        my ( $numA, $denA ) = @{ $self->get_value };
        my ( $numB, $denB ) = @{ $other->get_value };

        my $new_den = $denA;

        if ( $denA != $denB ) {
            $new_den = $denA * $denB;
            $numA *= $denB;
            $numB *= $denA;
        }

        $self->set_value([ $numA + $numB, $new_den ]);
    }
}

sub add_old {
    my $self = shift;
    my ( $other ) = @_;
    $self->set_value( $self->get_value + $other->get_value );
}

sub add_new {
    my $self = shift;
    my ( $other ) = @_;
    if ( $other->can( 'add' ) != __PACKAGE__->can( 'add_new' )) {
        my $temp = blessed( $other )->new( $self->evaluate );
        $temp->add( $other );
        return $self->set_value( $temp->evaluate );
    }
    $self->set_value( $self->get_value + $other->get_value );
}

# Fennec saves the day! This runs the test method for both cases, one case uses
# the legacy add, the other uses the new one.
cases legacy_and_new => sub {
    case legacy_add => sub {
        no warnings 'redefine';
        *Example::Number::add = \&add_old;
    };

    case new_add => sub {
        no warnings 'redefine';
        *Example::Number::add = \&add_new;
    };

    tests oop_original => sub {
        my $intA = Example::Integer->new( 1 );
        $intA->add( Example::Integer->new( 1 ));
        is( $intA->get_value, 2, "1 + 1 = 2" );

        my $floatA = Example::Float->new( 1.5 );
        $floatA->add( Example::Float->new( 1.2 ));
        is( $floatA->get_value, 2.7, "1.5 + 1.2 = 2.7" );

        $intA->add( $floatA );
        is( $intA->get_value, 4, "int( 2.7 + 2 ) = 4" );

        $floatA->add( $intA );
        is( $floatA->get_value, 6.7, "2.7 + 4 = 6.7" );
    };
};

tests oop_fraction => sub {
    {
        no warnings 'redefine';
        *Example::Number::add = \&add_new;
    }

    my $frac = Example::Fraction->new([ 1, 2 ]);
    is( $frac->render, "1/2", "rendered fraction" );

    $frac->add( Example::Fraction->new([ 1, 3 ]));
    is( $frac->render, "5/6", "1/2 + 1/3 = 5/6" );

    $frac->add( Example::Integer->new( 3 ));
    is( $frac->render, "23/6", "3 + 5/6 = 23/6" );

    $frac->add( Example::Float->new( 1.5 ));
    is( $frac->render, "16/3", "23/6 + 1.5 = 16/3" );

    my $int = Example::Integer->new( 1 );
    $int->add( $frac );
    is( $int->get_value, 6, "int( 1 + 16/3 ) = 6" );
};

1;
