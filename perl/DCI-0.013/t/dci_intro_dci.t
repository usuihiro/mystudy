package Test::DCI::Intro::Example;
use strict;
use warnings;

use Fennec;

use lib 'lib', 't/lib';
use Example::Number;
use Example::Integer;
use Example::Float;
use Example::Fraction;

{
    ##############
    package Example::Math::AddOld;
    use strict;
    use warnings;

    use DCI qw/Context/;

    # Allow import of a shortcut 'add' function that builds and runs the context.
    sugar add_old => (
        method  => 'add',
        ordered => [ qw/left right/ ],
    );

    # No need to wrap these in a cast, use them as is.
    casting qw/ left right /;

    sub add {
        my $self = shift;

        $self->left->set_value(
            $self->left->get_value + $self->right->get_value
        );
    }

    ##############
    package Example::Math::Number;
    use strict;
    use warnings;

    # Automatically delegate methods in the core class, we want them all.
    use DCI Cast => qw/ -auto_delegate /;

    our @PRECISION_ORDER = qw/ Example::Fraction Example::Float Example::Integer /;
    our @COMPLEX_TYPES = qw/ Example::Fraction /;

    sub is_complex {
        my $self = shift;
        return grep { $self->isa( $_ ) } @COMPLEX_TYPES;
    }

    sub precision_weight {
        my $self = shift;
        my $type = $self->dci_core_type;

        # Wow! a valid use of a C style for loop in Perl!
        for( my $idx = 0; $idx < @PRECISION_ORDER; $idx++ ) {
            return $idx if $PRECISION_ORDER[$idx] eq $type;
        }

        die "$type has no known weight, add it to \@" . __PACKAGE__ . "::PRECISION_ORDER."
    }

    sub most_precise {
        my $self = shift;
        my ( @others ) = @_;

        # Find the most precise
        my ($out) = sort {
            $a->precision_weight <=> $b->precision_weight
        } $self, @others;

        return $out;
    }

    ##############
    package Example::Math::Convert;
    use strict;
    use warnings;

    use DCI qw/Context/;
    use Carp qw/croak/;

    # Export 'convert' as sugar (See usage in Example::Math::Add)
    sugar convert => (
        method  => 'convert',
        ordered => [qw/ item type /],
    );

    cast item => 'Example::Math::Number',
         type => 'Example::Math::Number';

    sub convert {
        my $self = shift;

        my $type = $self->type->dci_core;

        # No conversion, just copy
        return $type->new( $self->item->get_value )
            if $self->item->isa( $type );

        # Conversion from a non-complex to a non-complex
        # or between complex and non-complex simply uses the evaluated result.
        return $self->type->new( $self->item->evaluate )
            unless $self->item->is_complex && $self->type->is_complex;

        # If complex to complex
        # Currently no such condition
        croak "'$self' cannot convert '" . $self->item->dci_core ."' to '" . $self->type->dci_core . "'\n";
    }


    ##############
    package Example::Math::AddNew;
    use strict;
    use warnings;
    use Carp qw/croak/;

    use DCI qw/Context/;
    # This would be: use Example::Convert qw/ convert /;
    Example::Math::Convert->import( 'convert' );

    sugar add_new => (
        method  => 'add',
        ordered => [ qw/left right/ ],
    );

    cast left  => 'Example::Math::Number',
         right => 'Example::Math::Number';

    sub add {
        my $self = shift;

        # Get the most precise operand
        my $precision_item = $self->left->most_precise( $self->right );

        # Do basic addition unless we have a complex type
        return $self->left->set_value(
            $self->left->get_value + $self->right->get_value
        ) unless $precision_item->is_complex;

        return $self->add_fractions()
            if $precision_item->isa( 'Example::Fraction' );

        croak "I don't know how to add '" . $self->precision_item->dci_core_type . "'";
    }

    sub add_fractions {
        my $self = shift;

        my $left  = convert( $self->left,  'Example::Fraction' );
        my $right = convert( $self->right, 'Example::Fraction' );

        my ( $numA, $denA ) = @{$left->get_value };
        my ( $numB, $denB ) = @{$right->get_value};

        my $den = $denA;
        unless( $denA == $denB ) {
            $numA *= $denB;
            $numB *= $denA;
            $den = $denA * $denB;
        }

        my $num = $numA + $numB;

        my $answer = Example::Fraction->new([ $num, $den ]);

        # If the left operand is not complex evaluate the fraction.
        return $self->left->set_value( $answer->evaluate )
            unless $self->left->is_complex;

        # If left operand is a fraction we simply use the value.
        return $self->left->set_value( $answer->get_value )
            if $self->left->isa( 'Example::Fraction' );

        # If left operand is complex, but not fraction we must convert it.
        return $self->left->set_value(
            convert( $answer, $self->left->dci_core_type )
        );
    }
}

Example::Math::AddNew->import( 'add_new' );
Example::Math::AddOld->import( 'add_old' );

# Fennec saves the day! This runs the test method for both cases, one case uses
# the legacy add, the other uses the new one.
cases legacy_and_new => sub {
    case legacy_add => sub {
        no warnings 'redefine';
        *add = \&add_old;
    };

    case new_add => sub {
        no warnings 'redefine';
        *add = \&add_new;
    };

    tests dci_no_fractions => sub {
        my $intA = Example::Integer->new( 1 );
        add( $intA, Example::Integer->new( 1 ));
        is( $intA->get_value, 2, "1 + 1 = 2" );

        my $floatA = Example::Float->new( 1.5 );
        add( $floatA, Example::Float->new( 1.2 ));
        is( $floatA->get_value, 2.7, "1.5 + 1.2 = 2.7" );

        add( $intA, $floatA );
        is( $intA->get_value, 4, "int( 2.7 + 2 ) = 4" );

        add( $floatA, $intA );
        is( $floatA->get_value, 6.7, "2.7 + 4 = 6.7" );
    };
};

tests fractions => sub {
    {
        no warnings 'redefine';
        *add = \&add_new;
    }

    my $frac = Example::Fraction->new([ 1, 2 ]);
    is( $frac->render, "1/2", "rendered fraction" );

    add( $frac, Example::Fraction->new([ 1, 3 ]));
    is( $frac->render, "5/6", "1/2 + 1/3 = 5/6" );

    add( $frac, Example::Integer->new( 3 ));
    is( $frac->render, "23/6", "3 + 5/6 = 23/6" );

    add( $frac, Example::Float->new( 1.5 ));
    is( $frac->render, "16/3", "23/6 + 1.5 = 16/3" );

    my $int = Example::Integer->new( 1 );
    add( $int, $frac );
    is( $int->get_value, 6, "int( 1 + 16/3 ) = 6" );
};
