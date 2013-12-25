package DCI::Meta::Cast;
use strict;
use warnings;

use base 'DCI::Meta';
use Carp qw/croak/;
use Scalar::Util qw/blessed reftype/;
use Exporter::Declare qw/export_tag export default_export gen_export export_to import/;
require DCI::Cast;

our $ANONYMOUS_CLASS = "AAAAAAAAAA";
our $AUTOLOAD;

sub base { 'DCI::Cast' }
sub init { shift->{allowed_cores} = [] }
sub allowed_cores { @{shift->{allowed_cores}} }

sub require_core {
    my $self = shift;
    push @{$self->{allowed_cores}} => @_;
}

export_tag auto_delegate => qw/ AUTOLOAD can -default /;

default_export delegate => sub {
    caller->dci_meta->delegate( @_ )
};

default_export require_core => sub {
    caller->dci_meta->require_core( @_ );
};

default_export accessors => sub {
    caller->dci_meta->accessors( @_ );
};

export can => sub {
    my $self = shift;
    my ( $name ) = @_;

    my $existing = $self->SUPER::can( $name );
    return $existing if $existing;

    return unless blessed( $self );

    my $sub = $self->dci_true_core->can( $name );

    unless ( $sub ) {
        return if grep { m/^$name$/ } qw/DESTROY import unimport/;
        croak "Core object " . $self->dci_true_core . " has no method '$name()'";
    }

    $self->dci_meta->delegate( $name );

    $self->SUPER::can( $name );
};

gen_export AUTOLOAD => sub {
    my ( $exported_by, $import_class ) = @_;

    return sub {
        my ($self) = @_;
        my ( $package, $name ) = ( $AUTOLOAD =~ m/^(.+)::([^:]+)$/ );
        $AUTOLOAD = undef;
        my $sub = $self->can($name) || return;
        goto &$sub;
    };
};

sub accessors {
    my $self = shift;
    my $target = $self->target;

    for my $accessor ( @_ ) {
        croak "'$accessor()' already defined by '$target'"
            if $target->can( $accessor );

        $self->inject( $target, $accessor, sub {
            my $self = shift;

            croak "$accessor cannot be called on unblessed reference '$self'"
                unless blessed( $self );

            my $state = $self->dci_state();
            ($state->{$accessor}) = @_ if @_;
            return $state->{$accessor};
        });
    }
};

sub delegate {
    my $self = shift;
    my @methods = @_;
    my $target = $self->target;

    for my $method ( @methods ) {
        $self->inject( $target, $method => sub {
            my $cast = shift;

            croak "method '$method()' cannot be called on string '$cast'"
                unless blessed $cast;

            my $core = $cast->dci_core;
            my $sub = $core->can($method);

            unless( $sub ) {
                my $core_class = blessed( $core );
                croak "method '$method()' is not implemented by core class '$core_class'";
            }

            unshift @_ => $core;

            goto &$sub;
        });
    }
}

sub anonymous {
    my $class = shift;
    my %params = @_;

    my $package = __PACKAGE__ . "::__ANON__::" . $ANONYMOUS_CLASS++;
    my $file = "/$package.pm";
    $file =~ s|::|/|g;
    $INC{$file} ||= __FILE__;

    my $meta = $class->new( $package );

    for my $sugar ( grep { $class->can( $_ )} keys %params ) {
        my $item = delete $params{$sugar};
        my $type = reftype( $item );

        croak "'$sugar' accepts either a string, or an array of strings, not '$type'"
            if $type && $type ne 'ARRAY';

        $meta->$sugar( $type ? (@$item) : ($item) );
    }

    for my $method ( keys %params ) {
        my $sub = delete $params{$method};
        my $type = reftype( $sub );

        croak "value for '$method' must be a subref, '$method' is not a method on '$class'"
            unless $type && $type eq 'CODE';

        $meta->inject( $package, $method => $sub );
    }

    return $package;
}

1;

__END__

=head1 NAME

DCI::Meta::Cast - Metadata object for Cast classes.

=head1 DESCRIPTION

The meta object used to build a cast object.

=head1 SYNOPSIS

=head2 PRIMARY USAGE

    package Example::Cast::A;
    use strict;
    use warnings;

    # Automatically sets DCI::Cast as a base class.
    use DCI::Meta::Cast;

    # Creates methods that pass through to the core object.
    delegate qw/foo bar/;

    # Restrict what type of objects can be used to build the cast.
    require_core qw/ Test::CoreA Test::CoreB Test::CoreC/;

    # Generate some accessors for tracking state in the Cast without modifying
    # the core object.
    accessors qw/cast_state_a cast_state_b/;

    sub call_delegate_methods {
        my $self = shift;
        $self->foo();
        $self->bar();
        return 1;
    }

    sub unique_numeric_id {
        my $self = shift;
        my $state = $self->dci_state;
        return $state->{something}++
    }

    1;

=head2 AUTO-DELEGATE

This example uses C<-auto_delegate> to automatically delegate any methods not
defined by the Cast to the core class.

    package Example::Cast::N;
    use strict;
    use warnings;

    # Automatically sets DCI::Cast as a base class.
    use DCI::Meta::Cast '-auto_delegate';

    sub call_delegate_methods {
        my $self = shift;
        $self->foo();
        $self->bar();
        return 1;
    }

=head2 USE BY PROXY

This is essentially what DCI.pm does.

    require DCI::Meta::Cast;

    # Create the meta object and inject 'dci_meta()' into the taget class.
    my $meta = DCI::Meta::Cast->new( $target_class );

    # Export the sugar methods into the target class.
    DCI::Meta::Cast->export_to( $target_class );

=head1 EXPORTS

All exports are optional. This class uses L<Exporter::Declare> for exporting,
which means you can use any L<Exporter::Declare> feature such as export
renaming.

=head2 EXPORT GROUPS

=over 4

=item '-auto_delegate'

Brings in C<AUTOLOAD()>, C<can()>, and all default exports.

=item '-default'

Used when no arguments are provided. Brings in all exported fuctions except
C<AUTOLOAD()> and C<can()>.

=back

=head2 EXPORTED FUNCTIONS

=over 4

=item delegate( @METHODS )

Sets up delegation methods for the specified list of methods.

This is sugar, essentially:

    sub { caller()->dci_meta->delegate( @_ ) }

=item require_core( @CLASSES )

Restricts the cast so that it can only be built using core objects of the
specified type(s).

This is sugar, essentially:

    sub { caller()->dci_meta->require_core( @_ ) }

=item accessors( @ACCESSORS )

Create accessors that store state in a state object bound to the cast object.

This is sugar, essentially:

    sub { caller()->dci_meta->accessors( @_ ) }

=item AUTOLOAD()

B<Not exported by default.>

Auto-delegates all methods (requires C<can()>).

=item can()

B<Not exported by default.>

Does the heavy lifting of auto-delegation.

=back

=head1 METHODS

Also see the methods for L<DCI::Meta>

=over 4

=item $instance = $class->new( $TARGET_PACKAGE )

Create a new instance for the target package. Will turn the target into a
subclass of L<DCI::Cast>.

=item $package = $class->anonymous( %PARAMS )

Create a new Cast type without writing your own package (it is auto-generated).

    my $cast_package = DCI::Meta::Cast->anonymous(
        delegate => \@METHODS,
        require_core => \@PACKAGES,
        accessors => \@ACCESSORS,
        custom_method => sub { ... },
        ...
    );

    $cast_package->dci_new( $some_core );

=item $package = $self->target()

Return the target package name.

=item $self->allowed_cores()

Return a list of allowed cores.

=item $self->require_core( @CORES )

Add one or more allowed core types.

=item $self->delegate( @METHODS )

Create delegate methods.

=item $self->accessors( @ACCESSORS )

Create accessors.

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
