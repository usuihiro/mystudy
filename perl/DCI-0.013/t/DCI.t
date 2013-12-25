package Test::DCI;
use strict;
use warnings;

use Fennec;

our $CLASS;
BEGIN {
    $CLASS = 'DCI';
    require_ok( $CLASS );
}

{
    package DCI::Test::Cast;
    use strict;
    use warnings;

    use DCI qw/Cast/;
}
{
    package DCI::Test::Context;
    use strict;
    use warnings;

    use DCI qw/Context/;
}

tests Cast => sub {
    isa_ok( 'DCI::Test::Cast', 'DCI::Cast' );
    can_ok( 'DCI::Test::Cast', qw/dci_meta dci_state delegate require_core accessors/ );
};

tests Context => sub {
    isa_ok( 'DCI::Test::Context', 'DCI::Context' );
    can_ok( 'DCI::Test::Context', qw/dci_meta sugar cast casting maybe_cast maybe_casting/ );
};

1;
