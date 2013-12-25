use strict;
use SQL::Maker;

my $sqlm = SQL::Maker->new( driver => 'mysql' );
{
	my ( $query, @bind ) = $sqlm->select('table_hoge', ['foo'], { '' => \ ' aaabbb', foo => 3 } );
	print "$query\n";
}
{
	my ( $query, @bind ) = $sqlm->select('table_hoge', ['foo'], { foo => 3 }, { for_update => 0 } );
	print "$query\n";
}

