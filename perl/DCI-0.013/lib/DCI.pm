package DCI;
use strict;
use warnings;

our $VERSION = "0.013";
use Carp qw/croak/;

sub import {
    my $class = shift;
    my ( $type, @args ) = @_;
    my $caller = caller;

    my $meta;

    for ( "DCI::Meta::$type", $type ) {
        my $good = eval "require $_; 1";
        my $error = $@;

        $meta = $_ if $good;
        last if $meta;

        # Rethrow error that is not can't locate
        die "Error loading $_: $error" if $error !~ m/Can't locate/;
    }

    croak "'Neither DCI::Meta::$type' nor '$type' appear to be 'DCI::Meta' packages"
        unless $meta
            && $meta->isa( 'DCI::Meta' );

    $meta->new( $caller );
    $meta->export_to( $caller => @args );
}

1;

__END__

=pod

=head1 NAME

DCI - Collection of utilities for writing perl code that fits the DCI
methodology.

=head1 DESCRIPTION

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

=head1 MORE ABOUT DCI

Look at L<DCI::Introduction> for a complete introduction into DCI concepts.

=head1 SYNOPSIS

This synopsis is very basic, see individual modules for better module-specific
examples. Also see L<DCI::Introduction> if you do not yet understand DCI
concepts.

=head2 DUMB DATA CLASS

    package Test::Data;
    use strict;
    use warnings;

    sub new {
        my $class = shift;
        my ( $value ) = @_;
        return bless( \$value, $class );
    }

    sub get_text { ${ $_[0] } }

    sub set_text { 
        my $self = shift;
        my ( $new_val ) = @_;
        $$self = $new_val;
    }

    1;

=head2 TRIVIAL CAST CLASS (ROLE)

    package Test::Cast;
    use strict;
    use warnings;

    use DCI qw/Cast/;

    # Delegate the text() method to the 'core'
    delegate qw/text/;

    # Restrict core to being a Test::Data object.
    require_core qw/Test::Data/;

    # Generate some accessors which keep state in the Cast, but do not interfer
    # with the Core object.
    accessors qw/cache/;

    # Add a method to our cast
    sub render {
        my $self = shift;

        my $cached = $self->cache;

        # text() is delgated to the underlying 'core'
        $cached = $self->cache(
            "The text is: '" . $self->text() . "'\n"
        ) unless $cached;

        return $cached;
    }

    1;

=head2 A CONTEXT

    package Test::Context;
    use strict;
    use warnings;

    use DCI qw/Context/;
    use Test::Cast;

    # Declare some required member objects
    cast first => 'Test::Cast',
         last  => 'Test::Cast';

    # export a function named 'quick_render' that constructs the object from
    # arguments, and returns the result of running the 'render()' method on the
    # created object.
    sugar quick_render => (
        method  => 'render',
        ordered => [qw/ first last /]
    );

    # A sugar export that takes named arguments.
    sugar parametric_render => 'render';

    # Method we use to kick-off the encapsulated task of the Context.
    sub render { shift->first->render }

    1;

=head2 PUTTING IT ALL TOGETHER

    use Test::More;

    use Test::Context qw/quick_render/;

    is(
        quick_render( "String A", "String B" ),
        "The text is: 'String A'\nThe text is: 'String B'",
        "Rendered first and last strings using quick sugar"
    );

    is(
        parametric_render(
            first => "String A",
            last  => "String B",
        ),
        "The text is: 'String A'\nThe text is: 'String B'",
        "Rendered first and last strings using named parameters"
    );

    my $it = Test::Context->new(
        first => "String A",
        last  => "String B",
    );

    is(
        $it->render,
        "The text is: 'String A'\nThe text is: 'String B'",
        "Rendered first and last strings from onbject instance"
    );

    1;

=head1 OBJECT TYPES

=head2 CONTEXT

=head3 SUGAR FUNCTIONS

See L<DCI::Meta::Context> which actually exports the sugar.

=head3 METHODS

See L<DCI::Context> the base class for all Casts.

=head2 CAST

=head3 SUGAR FUNCTIONS

See L<DCI::Meta::Cast> which actually exports the sugar.

=head3 METHODS

See L<DCI::Cast> the base class for all Casts.

=head1 API STABILITY

Versions below 0.011 were a prototype, the API was subject to flux. For 0.011
the API has been completely re-written using the lessons learned from the old
API.

B<As of 0.011, the API can be considered stable.> This means that changes which
break backwards compatibility will be few and far between.

=head1 SEE ALSO

=over 4

=item L<DCI::Meta::Context>

Meta class for contexts

=item L<DCI::Meta::Cast>

Meta class for casts

=item L<DCI::Context>

Base class for contexts

=item L<DCI::Cast>

Base class for casts

=back

=head1 ACHNOWLEDGEMENTS

The DCI concept was created by Trygve Reenskaug, (inventor of MVC) and James
Coplien.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2011 Chad Granum

DCI is free software; Standard perl licence.

DCI is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the license for more details.

=cut
