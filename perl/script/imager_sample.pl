use strict;
use Imager;

my $out_fname = $ARGV[0];

my $img = Imager->new(xsize=>320,ysize=>480,channels=>4);
my $blue = Imager::Color->new( 0, 0, 255 );
$img->box(color => $blue,
	xmin=>10, ymin=>30, xmax=>200, ymax=>300,
	filled=>1) or die $img->errstr;

my $green = Imager::Color->new( 0, 255, 0 );
$img->circle( color => $green, r => 40, x => 250, y => 250 );
$img->arc(color=>$blue, r=>20, x=>200, y=>100,
          d1=>10, d2=>20 );

$img->write( type => 'png', file => $out_fname ) or die $img->errstr;




