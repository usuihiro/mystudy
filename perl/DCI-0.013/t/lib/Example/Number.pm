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

__END__

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2011 Chad Granum

DCI is free software; Standard perl licence.

DCI is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the license for more details.

=cut
