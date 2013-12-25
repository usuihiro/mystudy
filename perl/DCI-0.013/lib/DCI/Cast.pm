package DCI::Cast;
use strict;
use warnings;

use Carp();
use Scalar::Util();

sub dci_new {
    my $class = shift;
    my ( $direct_core, $context, %state ) = @_;

    Carp::croak( "You must provide a core object" )
        unless $direct_core;

    Carp::croak( "You must provide a context" )
        unless $context;

    my $direct_core_type = Scalar::Util::blessed( $direct_core )
                        || Scalar::Util::reftype( $direct_core );

    my @allowed_cores = $class->dci_meta->allowed_cores;
    if ( @allowed_cores && !(grep { $direct_core->isa( $_ ) } @allowed_cores )) {
        Carp::croak "Invalid core '$direct_core_type' is not one of: "
            . join( ', ', @allowed_cores )
    }

    my $true_core = $direct_core;
    $true_core = $true_core->dci_core
        if Scalar::Util::blessed($true_core)
        && $true_core->isa( __PACKAGE__ );

    my $true_core_type = Scalar::Util::blessed( $true_core )
                      || Scalar::Util::reftype( $true_core );

    return bless {
        'state'          => \%state,
        true_core        => $true_core,
        direct_core      => $direct_core,
        context          => $context,
        true_core_type   => $true_core_type,
        direct_core_type => $direct_core_type,
        context_type     => Scalar::Util::blessed( $context )
                         || Scalar::Util::reftype( $context ),
    }, $class;
}

sub dci_meta {
    my $self_or_class = shift;
    my $class = Scalar::Util::blessed( $self_or_class )
             || $self_or_class;

    require DCI::Meta::Cast;
    DCI::Meta::Cast->new( $class );
}

sub dci_state { shift->{'state'} }

sub dci_context      { shift->{context}      }
sub dci_context_type { shift->{context_type} }

sub dci_core      { shift->dci_true_core      }
sub dci_core_type { shift->dci_true_core_type }

sub dci_true_core      { shift->{true_core}      }
sub dci_true_core_type { shift->{true_core_type} }

sub dci_direct_core      { shift->{direct_core}      }
sub dci_direct_core_type { shift->{direct_core_type} }

sub dci_debug {
    my $self = shift;

    my $out_start = "";
    my $out_end = "";
    my ( $type, $core_type, $core );
    do {
        my $one    = $core || $self;
        $type      = Scalar::Util::blessed($one);
        $core      = $one->dci_direct_core;
        $core_type = $one->dci_direct_core_type;

        $out_start = "$out_start$type( ";
        $out_end = ")$out_end";
    } while $core_type && $core_type->isa( __PACKAGE__ );

    return "$out_start$core $out_end";
}

sub isa {
    my $self = shift;

    return $self->SUPER::isa( @_ )
        unless Scalar::Util::blessed( $self );

    my $core = $self->dci_core;
    return $self->SUPER::isa( @_ ) || $core->isa( @_ );
}

1;

__END__

=head1 NAME

DCI::Cast - Base class for Cast classes.

=head1 DESCRIPTION

All Cast classes (Roles in typical DCI terminology) inherit from this class.
This class provides several key methods.

=head1 SYNOPSIS

See the docs for L<DCI> or L<DCI::Meta::Cast>, using this base directly is not
recommended.

=head1 METHODS

=head2 METHODS TO KEEP IN MIND

These methods need to be kept in mind. If you choose to override them you could
break functionality.

=over 4

=item $class_or_self->isa( $TYPE )

C<isa()> has been overriden so that it first calls isa() on the Cast class,
then if that returns false, calls isa on the core object. You probably do not
want to override this.

=back

=head2 PUBLIC METHODS

=over 4

=item $class->dci_new( $CORE, $CONTEXT, %STATE )

Create a new instance of the cast around the $CORE object with the specified
context and state.

=item $class->dci_meta()

Get the metadata object (Which is an instance of L<DCI::Meta::Cast>.)

=item $cast->dci_core()

Alias for C<dci_true_core>.

=item $cast->dci_core_type()

Alias for C<dci_true_core_type>,

=item $cast->dci_true_core()

Returns the core object around which the cast was constructed. When Casts are
nested, the inner-most core object will be returned. See C<dci_direct_core> if
this is not what you want.

=item $cast->dci_true_core_type()

Returns the type of the inner-most core object. Will return the package to
which the object has been blessed, or the ref type if it is not blessed.

=item $cast->dci_direct_core()

Get the direct core, even if it is itself a cast object.

=item $cast->dci_direct_core_type()

Returns the type of the core object. Will return the package to which the
object has been blessed, or the ref type if it is not blessed.

=item $cast->dci_context()

Get the context object with which the cast object was constructed.

=item $cast->dci_context_type()

Get the type of the context object. Will return the package to which the object
has been blessed, or the ref type if it is not blessed.

=item $cast->dci_state()

Get the state hash associated with this cast instance.

=item $cast->dci_debug()

Returns a string detailing the structure of a nested cast

Example: C<"Test::Cast( Test::Cast( Test::Core=HASH(0x1f29f28) ))">

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
