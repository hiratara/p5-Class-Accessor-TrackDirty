package Class::Stored;
use 5.008_001;
use strict;
use warnings;
our $VERSION = '0.01';

our $RESERVED_FIELD = '__' . __PACKAGE__;
our $FIELDS = 'fields';
our $VOLATILE_FIELDS = 'volatile_fields';
our $NEW = 'new';
our $FROM_HASH = 'from_hash';
our $TO_HASH = 'to_hash';
our $IS_MODIFIED = 'is_modified';
our $REVERT = 'revert';

sub _is_different($$) {
    my ($x, $y) = @_;
    if (defined $x && defined $y) {
        return $x ne $y;
    } else {
        return defined $x || defined $y;
    }
}

sub _make_accessor($$) {
    no strict 'refs';
    my ($package, $name) = @_;

    *{"$package\::$name"} = sub {
        my $self = shift;
        my $slot = $self->{$RESERVED_FIELD};
        my $value;
        if (exists $slot->{modified}{$name}) {
            $value = $slot->{modified}{$name};
        } elsif (defined $slot->{origin}) {
            $value = $slot->{origin}{$name};
        }

        if (@_) {
            $slot->{modified}{$name} = $_[0] if _is_different $value, $_[0];
        }

        return $value;
    };
}

sub import {
    no strict 'refs';
    my $class = shift;
    my $package = caller 0;

    my (@fields, @volatile_fields);

    my $_clean_fields = sub {
        my $hash_ref = shift;
        for my $k (keys %$hash_ref) {
            delete $hash_ref->{$k} unless grep { $k eq $_ }
                                               @fields, @volatile_fields;
        }
    };

    *{"$package\::$FIELDS"} = sub {
        _make_accessor $package => $_ for @_;
        push @fields, @_;
    };

    *{"$package\::$VOLATILE_FIELDS"} = sub {
        _make_accessor $package => $_ for @_;
        push @volatile_fields, @_;
    };

    *{"$package\::$NEW"} = sub {
        my $package = shift;
        my %modified = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
        $_clean_fields->(\%modified);

        bless { $RESERVED_FIELD => {
            modified => \%modified,
            origin   => undef, # Have no data
        } }, $package;
    };

    *{"$package\::$FROM_HASH"} = sub {
        my $package = shift;
        my %origin = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
        $_clean_fields->(\%origin);

        bless { $RESERVED_FIELD => {
            modified => {},
            origin   => \%origin,
        } }, $package;
    };

    *{"$package\::$TO_HASH"} = sub {
        my ($self) = @_;

        my %hash = (
            (map {
                # Don't store undefined values.
                my $v = $self->$_;
                defined $v ? ($_ => $v) : ();
            } @fields),
            lastupdate => time, v => 2,
        );

        # rewrite the caller directly
        $_[0] = (ref $self)->from_hash(\%hash);

        return \%hash;
    };


    *{"$package\::$IS_MODIFIED"} = sub {
        my $self = shift;
        my $slot = $self->{$RESERVED_FIELD};
        return 1 unless defined $slot->{origin};

        for (@fields) {
            return 1 if exists $slot->{modified}{$_};
        }
        return;
    };

    *{"$package\::$REVERT"} = sub {
        my $self = shift;
        $self->{$RESERVED_FIELD}{modified} = {};
    };
}

1;
__END__

=head1 NAME

Class::Stored - Define simple entities stored in some places.

=head1 SYNOPSIS

    package UserInfo;
    use Class::Stored;
    fields "name", "password";
    volatile_fields "modified";

    package main;
    my $user = UserInfo->new({name => 'honma', password => 'F!aS3l'});
    store_into_someplace($user->to_hash) if $user->is_modified;
    ...
    $user = UserInfo->from_hash(restore_from_someplace());
    $user->name('hiratara');
    $user->revert; # but decided not to
    $user->name('honma');
    $user->name('hiratara');
    $user->name('honma'); # I can't make up my mind...
    ... blabla ...

    # Store it only if $user was really modified.
    store_into_someplace($user->to_hash) if $user->is_modified;

=head1 DESCRIPTION

Class::Stored defines simple entities stored in files, RDBMS, KVS, and so on.

=head1 INTERFACE

=head2 Functions

=head3 C<< fields("name1", "name2", ...); >>

=head3 C<< volatile_fields("name1", "name2", ...); >>

=head3 C<< my $object = YourClass->new({name1 => "value1", ...}); >>

=head3 C<< my $object = YourClass->from_hash({name1 => "value1", ...}); >>

=head3 C<< my $hash_ref = $your_object->to_hash; >>

=head3 C<< my $hash_ref = $your_object->revert; >>

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Masahiro Honma E<lt>hiratara@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013, Masahiro Honma. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
