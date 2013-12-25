package Breakable;
 
use Mouse::Role;
 
has 'is_broken' => (
    is  => 'rw',
    isa => 'Bool',
);
 
sub break {
    my $self = shift;
 
    print "I broke\n";
 
    $self->is_broken(1);
}

package Engine;
use Mouse;

package Car;
 
use Mouse;
 
with 'Breakable';
 
has 'engine' => (
    is  => 'ro',
    isa => 'Engine',
);

my $car = Car->new( engine => Engine->new );

local $\ = "\n";
print $car->is_broken ? 'Busted' : 'Still working';
$car->break;
print $car->is_broken ? 'Busted' : 'Still working';

$car->does('Breakable'); # true


