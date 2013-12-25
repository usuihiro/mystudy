package DCI::Meta;
use strict;
use warnings;

sub before_import {
    my $class = shift;
    my ( $importer ) = @_;
    return $class->new( $importer );
}

sub base { die "must override base()" }
sub target { shift->{target} }

sub make_subclass {
    my $self = shift;
    my ( $target ) = @_;
    no strict 'refs';
    push @{ "$target\::ISA" } => $self->base;
}

sub new {
    my $class = shift;
    my ( $target ) = @_;

    my $self = bless { target => $target }, $class;

    $self->make_subclass( $target );
    $self->inject( $target, 'dci_meta' => sub { $self });

    $self->init() if $self->can( 'init' );

    return $self;
}

sub inject {
    my $self = shift;
    my ( $target, $name, $sub ) = @_;
    no strict 'refs';
    *{ "$target\::$name" } = $sub;
}

1;

__END__

=head1 NAME

DCI::Meta - Base class for meta objects.

=head1 DESCRIPTION

Base class for meta objects. Do not use this class directly. Use
L<DCI::Meta::Cast> and L<DCI::Meta::Context> instead.

=head1 METHODS

=over 4

=item $meta->new( $target )

Creates a new instance of the meta object.

=item $meta->target()

Returns the target package of the meta object.

=item $meta->subclass()

Returns the name of the package which should be subclassed.

=item $meta->make_subclass( $target )

Turns $target into a subclass of $meta->subclass()

=item inject( $target, $name, $code )

Inject the $code as a new function named $name in the $target package.

=item before_import()

Used by L<Exporter::Declare> in subclasses.

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
