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
