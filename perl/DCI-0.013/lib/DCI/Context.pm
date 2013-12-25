package DCI::Context;
use strict;
use warnings;

use Carp();

sub import {
    my $class = shift;
    my $caller = caller;

    $class->before_import( $class, $caller, \@_ )
        if $class->can( 'before_import' );

    $class->dci_export_to( $caller, @_ );

    $class->after_import_import( $class, $caller, @_ )
        if $class->can( 'after_import' );
}

sub dci_export_to {
    my $class = shift;
    my ( $caller, @export_list ) = @_;

    my %exports = $class->dci_meta->dci_exports;
    @export_list = keys %exports unless @export_list;

    for my $name ( @export_list ) {
        my $sub = $exports{ $name } || Carp::croak "$class does not export '$name'";
        $class->dci_meta->inject( $caller, $name => $sub );
    }
}

sub new {
    my $class = shift;
    my %args = @_;

    my $self = bless {}, $class;

    my %roles = map {( $_ => 1 )} $class->dci_meta->roles;
    my %maybe = map {( $_ => 1 )} $class->dci_meta->maybe_roles;
    for my $arg ( keys %args ) {
        Carp::croak( "$class has no role '$arg' to fill" )
            unless $roles{$arg} || $maybe{$arg};

        delete $roles{$arg};

        # The method takes care of applying the cast.
        $self->$arg( $args{$arg} );
    }

    # Ensure all roles are filled.
    Carp::croak( "No objects provided for roles: " . join( ", ", keys %roles ))
        if keys %roles;

    return $self;
}

1;

__END__

=head1 NAME

DCI::Context - Base class for context packages.

=head1 DESCRIPTION

All Context classes inherit from this class.  This class provides several key
methods.

=head1 SYNOPSIS

See L<DCI> or L<DCI::Meta::Context>, you should probably not directly subclass
this yourself.

=head1 METHODS

=over 4

=item $class->new( $ROLE => $OBJECT, ... )

Creates a new instance of your context with the specified role to object
mapping.

=item $class->dci_export_to( $PACKAGE )

Exports sugar methods to the specified package.

=item $class->import( @IMPORT_LIST )

Used automatically when someone imports your class C<use Your::Context>.

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
