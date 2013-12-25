package DCI::Test::Cast;
use strict;
use warnings;

use Fennec;

BEGIN {
    require_ok 'DCI::Cast';
    require_ok 'DCI::Meta::Cast';
}

{
    package Test::CoreA;
    use strict;
    use warnings;
    use Scalar::Util qw/blessed/;

    sub new {
        my $class = shift;
        $class = blessed( $class ) || $class;
        return bless( {}, $class );
    }

    sub foo { 'foo' }
    sub bar { 'bar' }

    package Test::CoreB;
    use strict;
    use warnings;
    use Scalar::Util qw/blessed/;

    sub new {
        my $class = shift;
        $class = blessed( $class ) || $class;
        return bless( {}, $class );
    }

    sub foo { 'FOO' }
    sub bar { 'BAR' }

    package Test::Cast;
    use strict;
    use warnings;

    use DCI::Meta::Cast;

    delegate qw/foo bar new/;
    require_core qw/ Test::CoreA Test::CoreB Test::CoreC/;
    accessors qw/stateful_accessor/;

    sub use_delegates {
        my $self = shift;
        return $self->foo . $self->bar;
    }

    sub stateful_by_hand {
        my $self = shift;

        ($self->dci_state->{stateful_by_hand}) = @_ if @_;

        return $self->dci_state->{stateful_by_hand}
    }

    package Test::Cast::AutoDelegate;
    use strict;
    use warnings;

    use DCI::Meta::Cast '-auto_delegate';

    require_core qw/ Test::CoreA Test::CoreB Test::CoreC/;
    accessors qw/stateful_accessor/;

    sub use_delegates {
        my $self = shift;
        return $self->foo . $self->bar;
    }

    sub stateful_by_hand {
        my $self = shift;

        ($self->dci_state->{stateful_by_hand}) = @_ if @_;

        return $self->dci_state->{stateful_by_hand}
    }
}

cases dci_api => sub {
    my ( $context, $core, $cast, $type, $cast_type );

    case cast_of_class => sub {
        $context = {};
        $type = 'Test::CoreA';
        $core = $type;
        $cast_type = 'Test::Cast';
        $cast = $cast_type->dci_new(
            $core, $context,
            stateful_accessor => 1,
            stateful_by_hand => 2,
            x => 'y'
        );
    };

    case cast_of_inst => sub {
        $context = {};
        $type = 'Test::CoreB';
        $core = $type->new();
        $cast_type = 'Test::Cast';
        $cast = $cast_type->dci_new(
            $core, $context,
            stateful_accessor => 1,
            stateful_by_hand => 2,
            x => 'y'
        );
    };

    case autodelegate => sub {
        $context = {};
        $type = 'Test::CoreB';
        $core = $type->new();
        $cast_type = 'Test::Cast::AutoDelegate';
        $cast = $cast_type->dci_new(
            $core, $context,
            stateful_accessor => 1,
            stateful_by_hand => 2,
            x => 'y'
        );
    };

    tests basic_api => sub {
        can_ok( $cast, qw/ dci_state dci_meta dci_core dci_context dci_new / );
        ok( !$cast->can('import'), "No import() method on cast" );

        isa_ok( $cast, 'DCI::Cast' );
        isa_ok( $cast, $cast_type );
        isa_ok( $cast, $type );
        isa_ok( $cast->dci_meta, 'DCI::Meta::Cast' );

        is( $cast->dci_context, $context, "Got the context" );
        is( $cast->dci_core, $core, "Got the core" );

        like(
            $cast->dci_debug,
            qr/^$cast_type\( Test::Core(A|B)(=HASH\(0x[0-9a-f]+\))? \)$/i,
            "cast debug"
        );

        is_deeply(
            $cast->dci_state,
            {
                x => 'y',
                stateful_accessor => 1,
                stateful_by_hand  => 2,
            },
            "Created with State"
        );

        is( $cast->stateful_accessor, 1, "used stateful accessor" );
        is( $cast->stateful_by_hand, 2, "used stateful by hand" );

    };

    tests depth => sub {
        my $deep = $cast_type->dci_new( $cast, $context );
        is( $deep->dci_direct_core, $cast, "Cast around cast" );
        like(
            $deep->dci_debug,
            qr/^$cast_type\( $cast_type\( Test::Core(A|B)(=HASH\(0x[0-9a-f]+\))? \)\)$/i,
            "cast debug depth 2"
        );

        $deep = $cast_type->dci_new( $deep, $context );
        like(
            $deep->dci_debug,
            qr/^$cast_type\( $cast_type\( $cast_type\( Test::Core(A|B)(=HASH\(0x[0-9a-f]+\))? \)\)\)$/i,
            "cast debug depth 3"
        );

        like( $deep->foo, qr/foo/i, "delegate depth" );
    };

    tests delegation => sub {
        like( $cast->foo, qr/foo/i, "delegate foo()" );
        like( $cast->bar, qr/bar/i, "delegate bar()" );

        my $created = $cast->new();
        isa_ok( $created, $type, "Created instance of core item" );

        like( $cast->use_delegates, qr/foobar/i, "Used method that uses delegated methods" );
    };
};

tests restricted_core => sub {
    throws_ok {
        Test::Cast->dci_new( bless( {}, 'foo' ), {}, );
    } qr/Invalid core 'foo' is not one of: Test::CoreA, Test::CoreB, Test::CoreC/,
        "Restricted core";
};

tests delegate => sub {
    throws_ok {
        Test::Cast->new( bless( {}, 'Test::CoreC' ), {}, );
    } qr/method 'new\(\)' cannot be called on string 'Test::Cast'/,
        "Delegate called on class";

    throws_ok {
        Test::Cast->dci_new( bless( {}, 'Test::CoreC' ), {}, )->foo;
    } qr/method 'foo\(\)' is not implemented by core class 'Test::CoreC'/,
        "Core does not have method for delegation";
};

tests auto_meta => sub {
    {
        package Test::Cast::AutoMeta;
        use strict;
        use warnings;
        use vars qw/@ISA/;

        require DCI::Meta::Cast;
        push @ISA => 'DCI::Cast';
    }

    my $base_method = Test::Cast::AutoMeta->can( 'dci_meta' );
    isa_ok( Test::Cast::AutoMeta->dci_meta, 'DCI::Meta::Cast' );

    ok( $base_method != Test::Cast::AutoMeta->can( 'dci_meta' ), "Injected method" );
};


1;
