use 5.16.1;
# http://d.hatena.ne.jp/asakichy/20090512/1242115417

package UserComponent {
	sub operation {}
	sub addRole {}
	sub getRole {}
	sub hasRole {}
	sub removeRole {}
}

package User {
	our @ISA = qw(UserComponent);
	use Mouse;
	has roles => ( is => 'rw', isa => 'HashRef' );
	has user_id => ( is => 'ro', isa => 'Int', required => 1 );

	sub operation {} # なにを実装するんだろう？
	sub addRole {
		my $self = shift;
		my ( $classname, @args ) = @_;

		my $role = $classname->new( $self, @args );
		$self->{roles}{ $classname } = $role;
		$role->addedBehavor( $self, @args );
	}

	sub getRole {
		my $self = shift;
		my ( $classname ) = @_;

		return $self->{roles}{$classname};
	}

	sub hasRole {
		my $self = shift;
		my ( $classname ) = @_;

		return $self->{roles}{$classname};
	}

	sub removeRole {
		my $self = shift;
		my ( $classname ) = @_;

		delete $self->{roles}{$classname};
	}
}

package UserRole {
	our @ISA = qw(UserComponent);
	use Scalar::Util;

	use Mouse;
	sub new {
		my $class = shift;
		my ( $core, @args ) = @_;
		my $self = bless {}, $class;
		$self->{core} = $core;
		Scalar::Util::weaken( $self->{core} );
		$self->init( @args );
	}
	sub init {}
	sub operation {}
	sub addRole {}
	sub getRole {}
	sub hasRole {
		my $self = shift;
		$self->{core}->hasRole( @_ );
	}
	sub removeRole {}
}

package UserCreator {
	our @ISA = qw(UserRole);

	sub addedBehavor { # 初期化処理的な？
		my $self = shift;
		my ( $core, @args ) = @_;
	}

	sub operation {
	}

	sub owns {
		my $self = shift;
		my $work = shift;
		return $work->{user_id} == $self->{core}->user_id();
	}
}

package UserPremium {
	our @ISA = qw(UserRole);

	sub addedBehavor { # 初期化処理的な？
		my $self = shift;
		my ( $core, @args ) = @_;
	}

	sub operation {
	}

	sub can_read {   # UserAudienceという上位Roleを作る？
		my $self = shift;
		my $work = shift;
		if ( $work->{public_flg} == 1 ) {
			return 1;
		}
		return;
	}
}

package UserReadTicket {
	our @ISA = qw(UserRole);

	sub addedBehavor { # 初期化処理的な？
		my $self = shift;
		my ( $core, @args ) = @_;
	}

	sub operation {
	}

	sub spend_ticket {
		my $self = shift;
		my ($work, $page_no) = @_;

		$self->{balance} -= 3;
	}

	sub read_ticket_balance {
		my $self = shift;
		if ( !defined $self->{balance} ) {
			$self->{balance} = 100;
		}
		return $self->{balance};
	}

	sub can_read {
		my $self = shift;
		my ($work, $page_no) = @_;
		if ( $work->{public_flg} != 1 ) {
			return;
		}
		if ( my $role = $self->hasRole( 'UserPremium' ) ) {
			return $role->can_read( $work, $page_no );
		}

		if ( $self->read_ticket_balance() >= $work->{required_ticket_cnt} ) {
			return 1;
		}
		return;
	}

	sub read_by_ticket {
		my $self = shift;
		my ($work, $page_no) = @_;
		$self->spend_ticket( $work, $page_no );
	}
}


my $user = User->new( { user_id => 32123121 } );
$user->addRole('UserReadTicket');



