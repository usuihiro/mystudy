use 5.16.1;
use Data::Dump qw(dd);
use User;
use Class::Inspector;

$\="\n";
my $user = User->new({ user_id => 12345 });
print $user->is_premium();
dd($user->profile());

my $methods = $user->meta();
dd ( $methods );


