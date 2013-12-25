use 5.16.1;

package User {
    use Mouse;

    with 'User::Role::Premium';
    with 'User::Role::Prof';
    with 'User::Role::ReadTicket';

    has user_id => (is => 'ro', isa => 'Int' );



    __PACKAGE__->meta->make_immutable();
};

package User::Role::Premium {
    use Mouse::Role;
    requires 'user_id';

    sub is_premium {
        my $self = shift;

        # select pay_monthly_trans
        # TODO must be implement.
        return $self->user_id > 0;
    }
}

package User::Role::Prof {
    use Mouse::Role;
    requires 'user_id';

    sub profile {
        my $self = shift;
        warn "a";
        return $self->_select_crea_user();
    }

    sub _select_crea_user {
        return { creaname => 'hogehoge' },
    }
}

package User::Role::ReadTicket {
    use Mouse::Role;
    requires 'user_id';

    sub select_ticket_balance {
        # TODO balance
        return 300;
    }
}


1;
