use 5.16.1;
use Plack::Request;

my $app = sub {
	my $env = shift;
	my $req = Plack::Request->new( $env );
	
	return [200, ['Content-Type', 'text/plain'], [ $req->param('post_data') ] ];
};

$app;
