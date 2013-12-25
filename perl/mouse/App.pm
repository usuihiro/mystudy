use 5.16.1;
package App {
	use Mouse;

	has app_key => ( is => 'ro', isa => 'Str', required => 1 );
	has platform => (
		is => 'rw', isa => 'App::Platform',
		handles => [qw(get_platform_name)]
	);
};

package App::Platform {
	use Mouse;

	sub platform {
		my $self = shift;
		my ( $pf ) = @_;
		if ( $pf eq 'I' ) {
			return App::iOS->new();
		} else {
			return App::Android->new();
		}
	}
}

package App::iOS {
	use parent -norequire, 'App::Platform';

	sub get_platform_name {
		my $self = shift;
		$self->app_key() . ' is iOS';
	}
};

package App::Android {
	use parent -norequire, 'App::Platform';

	sub get_platform_name {
		my $self = shift;
		$self->app_key() . ' is Android';
	}
}

package main {
	use Test::More;
	use Carp;
	$SIG{__DIE__} = \&Carp::confess;

	my $app = App->new({app_key => 'hogehoge'});
	ok !$app->can('get_platform_name');

	my $app = $app->platform( App::Platform->platform('I') );
	print $app->get_platform_name() . "\n";

	my $app2 = App->new({app_key => 'foo'});
	my $app2 = $app2->platform( App::Platform->platform('A') );
	ok !$app2->can('get_platform_name');

	print $app2->get_platform_name() . "\n";
};

