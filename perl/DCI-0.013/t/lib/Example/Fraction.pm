package Example::Fraction;
use strict;
use warnings;
use Carp qw/croak/;
our @ISA = ( 'Example::Number' );

sub render {
    my $self = shift;
    my ( $num, $den ) = @{ $self->get_value };
    return "$num/$den";
}

sub normalize {
    my $class_or_self = shift;
    my ( $in ) = @_;

    if ( my $ref = ref $in ) {
        return $class_or_self->reduce( $in ) if $ref eq 'ARRAY';
        croak "Cannot turn value '$in' into a fraction.";
    }

    # If there is no decimal we have a whole number
    return $class_or_self->reduce([ $in, 1 ])
        unless $in =~ m/\./;

    return $class_or_self->reduce(
        $class_or_self->convert_from_decimal( $in )
    );
}

sub convert_from_decimal {
    my $class_or_self = shift;
    my ( $in ) = @_;

    my $whole = int( $in );

    # Strip off everything up to the decimal, also stringifies $in
    $in -= $whole;
    $in =~ s/^.*\.//;

    # Numerator is integer from of everything after decimal
    my $num = int( $in );

    # Denominator is 1 followed by a 0 for each digit after the decimal.
    $in =~ s/\d/0/g;
    my $den = int("1$in");

    # Add the whole portion back in.
    $num += $whole * $den;

    return [ $num, $den ];
}

sub reduce {
    my $class_or_self = shift;
    my ( $in ) = @_;

    croak "'$in' is not an array"
        unless ref $in && ref $in eq 'ARRAY';

    my ( $num, $den ) = @$in;

    my $gcd = $class_or_self->gcd( $num, $den );
    if ( $gcd > 1 ) {
        $num /= $gcd;
        $den /= $gcd;
    }

    return [ $num, $den ];
}

sub gcd {
    my $class_or_self = shift;

    my ($num, $den) = @_;

    ($num,$den) = ($den,$num)
        if $num > $den;

    ($num, $den) = ($den % $num, $num)
        while $num;

    return $den;
}

sub evaluate {
    my $self = shift;
    my ($num, $den) = @{ $self->get_value };
    return $num / $den;
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
