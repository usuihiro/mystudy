package DCI::Meta::Context;
use strict;
use warnings;

use base 'DCI::Meta';

use Carp qw/croak confess/;
use Scalar::Util qw/blessed/;
use Exporter::Declare qw/export_to default_export import/;
require DCI::Context;

default_export cast    => sub { caller->dci_meta->cast( @_ )   };
default_export casting => sub { caller->dci_meta->casting( @_ )};
default_export sugar   => sub { caller->dci_meta->sugar( @_ )  };

default_export maybe_cast    => sub { caller->dci_meta->maybe_cast( @_ )   };
default_export maybe_casting => sub { caller->dci_meta->maybe_casting( @_ )};

sub base { 'DCI::Context' };

sub init {
    my $self = shift;
    %$self = (
        %$self,
        roles => {},
        maybe => {},
        sugar => {},
    );
}

sub roles       { keys %{ shift->{roles}}};
sub maybe_roles { keys %{ shift->{maybe}}};

sub get_role_cast {
    my $self = shift;
    my ( $role ) = @_;
    return $self->{roles}->{ $role }
        || $self->{maybe}->{ $role };
}

sub _add_role_method {
    my $self = shift;
    my ( $name, $cast ) = @_;
    my $target = $self->target;

    $self->inject( $target, $name => sub {
        my $context = shift;
        croak "Cannot call '$name' on unblessed '$context'"
            unless blessed( $context );

        if ( @_ ) {
            my ($val, @extra) = @_;
            croak "Extra arguments provided to '$name'"
                if @extra;

            $context->{$name} = $self->_normalize_core(
                $context, $cast, $val
            );
        }

        return $context->{$name};
    });
}

sub _normalize_core {
    my $self = shift;
    my ( $context, $cast, $val ) = @_;

    # No restrictions on core
    return $val unless defined $cast;

    # Val meets restrictions
    return $val if blessed $val && $val->isa( $cast );

    # Val can be wrapped used in cast
    return $cast->dci_new( $val, $context )
        if eval { $cast->isa( 'DCI::Cast' )};

    croak "'$val' is not a '$cast', and '$cast' is not a Cast type";
}

sub cast {
    my $self = shift;
    $self->_cast( $self->{roles}, @_ );
}

sub maybe_cast {
    my $self = shift;
    $self->_cast( $self->{maybe}, @_ );
}

sub _cast {
    my $self = shift;
    my ( $store, %roles ) = @_;
    for my $role ( keys %roles ) {
        croak "role $role already defined for '" . $self->target . "'"
            if $store->{$role};

        my $cast = $roles{$role};

        if ( $cast && !blessed( $cast ) && ref $cast eq 'HASH' ) {
            $cast = DCI::Meta::Cast->anonymous( %$cast );
        }

        $store->{$role} = $cast;
        $self->_add_role_method( $role, $cast );
    }
}

sub casting {
    my $self = shift;
    $self->_cast( $self->{roles}, map {( $_ => undef )} @_ );
}

sub maybe_casting {
    my $self = shift;
    $self->_cast( $self->{maybe}, map {( $_ => undef )} @_ );
}

sub sugar {
    my $self = shift;

    croak "sugar() called without args" unless @_;

    my ( $name, @args ) = @_;
    my %params = @args > 1 ? @args : ( method => @args );

    my $method = $params{method} || croak "No method specified for sugar";
    my $ordered = $params{ordered} || [];
    my $target = $self->target;

    $self->{sugar}->{$name} = sub {
        $target->new(
            (map {( $_ => shift( @_ ) )} @$ordered),
            @_,
        )->$method;
    }
}

sub dci_exports {
    my $self = shift;
    return %{ $self->{sugar} }
}

1;

__END__

=head1 NAME

DCI::Meta::Context - Primary Interface, and metadata object for Context classes.

=head1 DESCRIPTION

This is the Meta object for building Context objects.

=head1 SYNOPSIS

    package Test::Context;
    use strict;
    use warnings;

    use DCI::Meta::Context;

    # roles to fill that have no cast type
    casting qw/middle/;

    # roles to fill with existing casts
    cast first => 'Test::Context::First',
         last  => 'Test::Context::Last';

    # create a cast on the fly
    cast punctuation => {
        delegate => 'text',
        render => sub { shift->text },
    };

    # Optional roles (Not used later in this example)
    maybe_casting qw/tail_a tail_b/;
    maybe_cast tail_c => 'Test::Context::First',
               nothing => {
                   delegate => 'text',
                   render => sub { shift->text },
               };

    #############
    # These are various examples of exporting 'sugar' methods that help people
    # to use your Context.
    #############

    sugar render_named => 'render';
    sugar render_custom_named => sub { shift->render };

    sugar render_ordered => (
        method  => 'render',
        ordered => [qw/first middle last punctuation/],
    );

    sugar render_custom_ordered => (
        ordered => [qw/first middle last punctuation/],
        method => sub { shift->render },
    );

    sugar render_mixed => (
        method  => 'render',
        ordered => [qw/first middle last/]
    );

    # You can define any methods you would like on the context. All roles can
    # be accessed via method which shares the roles name.
    sub render {
        my $self = shift;
        join( ", ",
            $self->first->render,
            $self->middle,
            $self->last->render,
        );
    }

=head1 EXPORTS

All exports are optional. This class uses L<Exporter::Declare> for exporting,
which means you can use any L<Exporter::Declare> feature such as export
renaming.

=over 4

=item cast( $ROLE => $CAST_TYPE, ... )

Defines required roles that must be provided when building an instance of the
context. A cast package name must be provided for each role, or undef can be
used for no type. When the cast is built the role will be wrapped in the cast
type automatically.

=item casting( @ROLES )

Define required roles that do not need to be cast into anything.

=item maybe_cast( $ROLE => $CAST_TYPE, ... )

Same as C<cast()> except roles are optional at construction.

=item maybe_casting( @ROLES )

Same as C<casting()> except roles are optional at construction.

=item sugar( $EXPORT_NAME, $METHOD_NAME )

=item sugar( $EXPORT_NAME, %CONFIG )

Creates an export that will build an instance of your context and then call the
specified method. You can also specify an order of arguments so that users do
not need to provide role => actor mappings.

    sugar render_named => 'render';

    # How it is used
    render_named(
        first       => $first,
        middle      => $middle,
        last        => $last,
        punctuation => $punctuation,
    ),

    sugar render_ordered => (
        method  => 'render',
        ordered => [qw/first middle last punctuation/],
    );

    # How it is used
    render_ordered( $first, $middle, $last, $punctuation ),

=back

=head1 METHODS

Also see L<DCI::Meta> for more methods.

=over 4

=item $context = $class->new( $target )

Create a new instance of L<DCI::Meta::Context>.

=item $package = $context->target()

Target Context package for this instance.

=item @role_names = $context->roles()

List of required roles.

=item @role_names = $context->maybe_roles()

List of optional roles.

=item %EXPORTS = $context->dci_exports()

Get a map of export_name => sub containing all sugar methods.

=item $cast_class = $context->get_role_cast( $ROLE_NAME )

Get the cast type for a specific role.

=item $context->cast( $ROLE_NAME, $CAST_TYPE, ... )

=item $context->maybe_cast( $ROLE_NAME, $CAST_TYPE, ... )

=item $context->casting( @CAST_LIST )

=item $context->maybe_casting( @CAST_LIST )

See the C<cast()>, C<maybe_cast()>, C<casting()>, and C<maybe_casting> exports
above.

=item $context->sugar( $SUGAR_NAME => $METHOD )

=item $context->sugar( $SUGAR_NAME, %PARAMS )

Add a sugar method to the class (See the C<sugar()> export).

=back

=head2 PRIVATE METHODS

Do not use these.

=over 4

=item _normalize_core

=item _add_role_method

=item _cast

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
