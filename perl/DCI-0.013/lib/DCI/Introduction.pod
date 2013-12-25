package DCI::Introduction;
use strict;
use warnings;

1;

__END__

=pod

=head1 NAME

DCI - Collection of utilities for writing perl code that fits the DCI
methodology.

=head1 INTRODUCTION TO DCI

The DCI concept was created by Trygve Reenskaug, (inventor of MVC) and James
Coplien.


DCI Stands for Data, Context, Interactions. It was created to solve the problem
of unpredictable emergent behavior in networks of interacting objects. This
problem shows itself in complex OOP projects, most commonly in projects with
deep polymorphism. This is a problem that Procedural/Imperative Programming
does not have.

DCI does not replace OOP, instead it augments it with lessons learned from
looking back at Procedural Programming. It defines a way to encapsulate use
cases into a single place. This provides an advantage to the programmer by
reducing the number of interactions that need to be tracked. Another advantage
is the reduction of side-effects between contexts.

Another way to look at it is that a DCI implementation is much more
maintainable as a project matures. Changes to requirements and additional
features cause clean OOP project to degrade into spaghetti. DCI on the other
hand maintains code clarity under changing requirements.

=head2 TERMINOLOGY

=over 4

=item Data

Refers to "what the system is."  These objects represent well defined objects
that should rarely change. They should encapsulate only basic CRUD methods. A
common example would be a C<BankAccount> object.

=item Context

A context implements one or more use cases. A use case can be a well defined
workflow in business logic, or an algorithm. A common example would be a
transfer between bank accounts. The context defines what objects are required,
such as a C<DestinationAccount>, an C<OriginAccount>, and a transfer amount.
The context also provides a point of entry to kick off the task and see it to
completion.

=item Interactions

Refers to "what the system does."  Typically implemented by defining roles that
take part in a context. Examples roles within an C<FundTransfer> context would
be C<DestinationAccount> and C<OriginAccount>. Roles delegate CRUD operations
to the data objects. A role would only encapsulate methods applicable to that
role.

B<To elaborate>, a C<DestinationAccount> would implement a C<deposit()> method,
but has no need of a C<withdrawal()> method. An C<OriginAccount> would
implement a C<withdrawal()> method, but has no need of a C<deposit()> method.

=back

=head1 COMPLETE EXAMPLE

Here we will implement the same thing in both DCI and OOP. We will start off
with a set of requirements and code that implements them in each architecture.
This example mimics a real world situation in which a new feature is added
years after the original requirements were implemented.

You may notice that the DCI version is longer than the OOP version. DCI does
not claim to reduce code in the offset. DCI is in fact longer at the beginning,
but does offer code saving in the form of avoiding costly refactors. DCI is
intended to be more future-proof, allowing new features and requirements to be
added with less overhead.

At the end of the example we will present a few new-feature exercises, thinking
through these exercises will bring home the benefit of the DCI system.

=head2 PHASE 1: INITIAL REQUIREMENTS

We will be implementing a number system that has a base number type, an integer
type, and a float type. We will also implement addition of two numbers. Note
that most of the code is common between the OOP and DCI versions.

You can see these implementations in action in the C<t/dci_intro_oop.t> and
C<t/dci_intro_dci.t> tests. The common code is found in C<t/lib/> which is used
by both tests.

=head3 COMMON CODE

This code is common to both the DCI and OOP versions. Each section below will
simply list additional code for each object, and additional objects.

The number class:

    package Example::Number;
    use strict;
    use warnings;
    use Carp qw/croak/;

    sub normalize { die "override this" }

    sub new {
        my $class = shift;
        croak "Too many arguments" if @_ > 1;
        my $value = $class->normalize( @_ );
        return bless( \$value, $class );
    }

    sub get_value {
        my $self = shift;
        return $$self;
    }

    sub set_value {
        my $self = shift;
        $$self = $self->normalize( @_ );
    }

    sub evaluate {
        my $self = shift;
        return $self->get_value;
    }

    1;

The integer class:

    package Example::Integer;
    use strict;
    use warnings;
    our @ISA = ( 'Example::Number' );

    sub normalize {
        my $class_or_self = shift;
        my ( $value ) = @_;
        return int( $value );
    }

    1;

The float class:

    package Example::Float;
    use strict;
    use warnings;
    our @ISA = ( 'Example::Number' );

    sub normalize {
        my $class_or_self = shift;
        my ( $value ) = @_;
        # No change necessary
        return $value;
    }

    1;

=head3 OOP VERSION

Only additional code is shown, reference the common code above.

The number class:

    package Example::Number;
    ...
    sub add {
        my $self = shift;
        my ( $other ) = @_;
        $self->set_value( $self->get_value + $other->get_value );
    }

Tests to demonstrate it:

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

=head3 DCI VERSION

Only additional code is shown, reference the common code above.

    package Example::Math::Add;
    use strict;
    use warnings;

    use DCI qw/Context/;

    # Allow import of a shortcut 'add' function that builds and runs the context.
    sugar add => (
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

Tests to demonstrate it:

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

=head2 PHASE 2: A NEW FEATURE

We will be adding a new number type, a fraction. This feature request comes
years later and there are thousands of lines of code that use the existing
Integer and Float classes, refactoring is not an option. We need to work in the
new Fraction class without braking anything old.

=head3 OOP CHANGES

There are some important considerations:

=over 4

=item Adding fractions and other numbers is tricky.

Fractions are essentially a division that has not happened yet. In many cases a
fraction, or rational number, cannot be represented completely in decimal form.
For instance 1/3 = 0.3333-> on to infinity. When dealing with fractions it is
important to do all the arithmetic before converting the fraction to decimal
form.

=item Faction addition belongs in the fraction class.

This is encapsulation, the base class should not implement logic specific to a
single subclass.

=item How do we add a fraction to a non-fraction?

We either need to convert the fraction to a float before adding, or we need to
convert the left operand into the more precise fraction type, and then add. The
first could potentially lose precision, and is not the ideal option.

=back

We need to add the fraction class:

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

We also need to modify the base class so that fractions work when added to
other numbers. We will do this in a way that does not care if the subclass is a
fraction, or some other type of complex number.

B<Note:> This is the 'correct' way to do this. Though in most projects,
specially with time constraints, this would likely just be a conditional
looking for the fraction type. Conditioning on fraction type is not ideal
should we need to add new complex types later. The DCI version will not have
this problem.

    package Example::Number;
    use Scalar::Util qw/blessed/;
    ...
    sub add {
        my $self = shift;
        my ( $other ) = @_;

        # If the $other object overrides add
        if ( $other->can( 'add' ) != __PACKAGE__->can( 'add' )) {
            my $temp = blessed( $other )->new( $self->evaluate );
            $temp->add( $other );
            return $self->set_value( $temp->evaluate );
        }

        $self->set_value( $self->get_value + $other->get_value );
    }

Tests (Note, old tests will all still pass):

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

=head3 DCI CHANGES

The DCI changes may seem quite long, however it should be noted that a lot of
this has to do with the overhead of writing new modules as opposed to adding
code to existing ones. Another reason for this is because DCI practically
forces us to write this in a way that leaves the code maintainable. If we want
to add new complex types after this it will be trivial.

First we need to update the context, it is presented here in its entirety so
that you do not need to look back at the old version.

    package Example::Math::Add;
    use strict;
    use warnings;
    use Carp qw/croak/;

    use DCI qw/Context/;
    # This would be: use Example::Convert qw/ convert /;
    Example::Math::Convert->import( 'convert' );

    sugar add => (
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

Now we need to add a cast class for numbers used in Math contexts. In DCI this
would normally be called a 'role' but we use the term 'cast' to avoid conflict
with Moose and many other projects which use the term 'role'.

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

We will add another Context called 'Convert', this will be used any time we
need to convert between number types.

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
        croak "'$self' cannot convert '"
            . $self->item->dci_core ."' to '"
            . $self->type->dci_core
            . "'\n";
    }

Tests (Note, old tests still pass)

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

=head2 THOUGHT EXERCISES

These are exercises for you to think about. If you think about how to solve
these problems using both the OOP version and the DCI version you will see
where DCI benefits. These added features or requirements could cause an OOP
project to quickly degrade. DCI on the other hand already solved most of them
when the fraction type was added.

=head3 OOP

How hard would it be to add another complex type? It may initially seem easy,
but consider the C<add()> method. How would it handle 2 complex types used in
an addition? Currently it would use the add method from the operand on the
left after converting the operand on the right. What if the left operand is
a less precise type?

What if you also had a multiply method, or other complex operations?

Does your system depend on the most accurate math, or will converting things to
less precise types still provide an acceptable result?

How would you add a precision to your types to ensure things are always
converted to the most precise type?

How would you add another complex type with precision between existing ones?

=head3 DCI

Lets say you did not separate conversion into a context of its own. Now you
want to implement a subtract() use-case. This use case also needs conversion,
how much code needs to change? The answer is simple, move the conversion logic
into a context, and use it in both use-cases, nothing else need change.

How hard is it to add a new complex type? What needs to change? The answer is
that you need to add the class to the Example::Math::Number Cast variables for
precision and complex types. You also need to implement logic in the Conversion
context to convert between fraction and your new type. Lastly you need to
implement logic int he Add context which adds two of your new type together.

When adding the fraction type you may not have had the foresight to implement
the precision sorting. Instead you simply check if it is a primitive float/int,
or a fraction. How hard would it be to refactor it to use the precision system
we have now?

Look back at the thought exercises for the OOP version, how difficult or easy
are they in DCI? How many of them are even an issue in DCI?

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2011 Chad Granum

DCI is free software; Standard perl licence.

DCI is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the license for more details.

=head1 ACHNOWLEDGEMENTS

The DCI concept was created by Trygve Reenskaug, (inventor of MVC) and James
Coplien.

=cut
