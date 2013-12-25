package DCI::Test::Context;
use strict;
use warnings;

use Fennec;

BEGIN { require_ok 'DCI::Meta::Context' }

{
    package Test::Data;
    use strict;
    use warnings;

    sub new {
        my $class = shift;
        my ( $value ) = @_;
        return bless( \$value, $class );
    }

    sub text { ${ $_[0] } }

    ########
    package Test::Context::First;
    use strict;
    use warnings;

    use DCI::Meta::Cast;

    delegate qw/text/;
    require_core qw/Test::Data/;

    sub render {
        my $self = shift;
        return join(
            " ",
            $self->text,
            ( map { $_->text } @{ $self->dci_context->middle } ),
            $self->dci_context->last->render_with_punctiation
        );
    }

    ########
    package Test::Context::Last;
    use strict;
    use warnings;

    use DCI::Meta::Cast;

    delegate qw/text/;
    require_core qw/Test::Data/;

    sub render_with_punctiation {
        my $self = shift;
        return $self->text . $self->dci_context->punctuation->render;
    }

    ########
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

    # Optional roles
    maybe_casting qw/tail_a tail_b/;
    maybe_cast tail_c => 'Test::Context::First',
               nothing => {
                   delegate => 'text',
                   render => sub { shift->text },
               };


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

    sub render { shift->first->render }
}

Test::Context->import();

tests no_sugar => sub {
    my $sentance = Test::Context->new(
        first => Test::Data->new( "Foo" ),
        middle => [map { Test::Data->new($_) } qw/ bar baz boo /],
        last => Test::Data->new( "end" ),
        punctuation => Test::Data->new( "!" ),
    );

    ok( $sentance, "Built sentance" );
    isa_ok( $sentance, 'DCI::Context' );
    can_ok( $sentance, qw/first middle last punctuation render/ );

    is( $sentance->render, "Foo bar baz boo end!", "rendered sentance" );
};

tests sugar => sub {
    my $first  = Test::Data->new( "Foo" );
    my $middle = [map { Test::Data->new($_) } qw/ bar baz boo /];
    my $last   = Test::Data->new( "end" );
    my $punctuation = Test::Data->new( "!" );

    is(
        render_ordered( $first, $middle, $last, $punctuation ),
        "Foo bar baz boo end!",
        "rendered sentance with ordered sugar"
    );

    is(
        render_custom_ordered( $first, $middle, $last, $punctuation ),
        "Foo bar baz boo end!",
        "rendered sentance with ordered sugar and custom method"
    );

    is(
        render_named(
            first       => $first,
            middle      => $middle,
            last        => $last,
            punctuation => $punctuation,
        ),
        "Foo bar baz boo end!",
        "rendered sentance with named sugar"
    );

    is(
        render_custom_named(
            first       => $first,
            middle      => $middle,
            last        => $last,
            punctuation => $punctuation,
        ),
        "Foo bar baz boo end!",
        "rendered sentance with named sugar"
    );

    is(
        render_mixed( $first, $middle, $last, punctuation => $punctuation ),
        "Foo bar baz boo end!",
        "rendered sentance with mixed sugar"
    );
};
