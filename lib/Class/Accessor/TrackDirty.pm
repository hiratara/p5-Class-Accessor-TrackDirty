package Class::Accessor::TrackDirty;
use 5.008_001;
use strict;
use warnings;
our $VERSION = '0.01';

our $RESERVED_FIELD = '_original';
our $NEW = 'new';
our $FROM_HASH = 'from_hash';
our $TO_HASH = 'to_hash';
our $IS_MODIFIED = 'is_modified';
our $REVERT = 'revert';

my %package_info;
sub _package_info($) {
    my $package = shift;
    $package_info{$package} //= {fields => [], volatiles => []};
}

sub _is_different($$) {
    my ($x, $y) = @_;
    if (defined $x && defined $y) {
        return $x ne $y;
    } else {
        return defined $x || defined $y;
    }
}

sub _fields_cleaner($) {
    my $package = shift;
    my ($fields, $volatile_fields) =
        @{_package_info $package}{qw(fields volatiles)};
    sub {
        my $hash_ref = shift;
        for my $k (keys %$hash_ref) {
            delete $hash_ref->{$k} unless grep { $k eq $_ }
                                               @$fields, @$volatile_fields;
        }
    };
};

sub _make_accessor($$) {
    no strict 'refs';
    my ($package, $name) = @_;

    *{"$package\::$name"} = sub {
        my $self = shift;
        my $value;
        if (exists $self->{$name}) {
            $value = $self->{$name};
        } elsif (defined $self->{$RESERVED_FIELD})  {
            $value = $self->{$RESERVED_FIELD}{$name};
        }

        if (@_) {
            if (! defined $self->{$RESERVED_FIELD}
                || _is_different $self->{$RESERVED_FIELD}{$name}, $_[0]) {
                $self->{$name} = $_[0];
            } else {
                delete $self->{$name};
            }
        }

        return $value;
    };
}

sub _mk_accessors($@) {
    my $package = shift;
    _make_accessor $package => $_ for @_;
    push @{_package_info($package)->{fields}}, @_;
}

sub _mk_helpers($) {
    no strict 'refs';
    my $package = shift;
    my ($fields, $volatile_fields) =
        @{_package_info $package}{qw(fields volatiles)};
    my $clean_fields = _fields_cleaner($package);

    # cleate helper methods
    *{"$package\::$FROM_HASH"} = sub {
        my $package = shift;
        my %origin = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
        $clean_fields->(\%origin);

        bless {$RESERVED_FIELD => \%origin}, $package;
    };

    *{"$package\::$TO_HASH"} = sub {
        my ($self) = @_;

        my %hash = (
            (map {
                # Don't store undefined values.
                my $v = $self->$_;
                defined $v ? ($_ => $v) : ();
            } @$fields),
            lastupdate => time, v => 2,
        );

        # rewrite the caller directly
        $_[0] = (ref $self)->from_hash(\%hash);

        return \%hash;
    };

    *{"$package\::$IS_MODIFIED"} = sub {
        my $self = shift;
        return 1 unless defined $self->{$RESERVED_FIELD};

        for (@$fields) {
            return 1 if exists $self->{$_};
        }
        return;
    };

    *{"$package\::$REVERT"} = sub {
        my $self = shift;
        %$self = ($RESERVED_FIELD => $self->{$RESERVED_FIELD});
    };
}

sub _mk_volatile_accessors($@) {
    my $package = shift;
    _make_accessor $package => $_ for @_;
    push @{_package_info($package)->{volatiles}}, @_;
}

sub _mk_new($) {
    no strict 'refs';
    my $package = shift;

    my $clean_fields = _fields_cleaner($package);
    *{"$package\::$NEW"} = sub {
        my $package = shift;
        my %modified = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
        $clean_fields->(\%modified);

        bless \%modified => $package;
    };
}

sub mk_accessors {
    (undef, my @fields) = @_;
    my $package = caller(0);
    _mk_accessors $package => @fields;
    _mk_helpers $package;
}

sub mk_volatile_accessors {
    (undef, my @volatiles) = @_;
    my $package = caller(0);
    _mk_volatile_accessors $package => @volatiles;
}

sub mk_new {
    my $package = caller(0);
    _mk_new $package;
}

sub mk_new_and_accessors {
    (undef, my @fields) = @_;
    my $package = caller(0);
    _mk_accessors $package => @fields;
    _mk_helpers $package;
    _mk_new $package;
}

1;
__END__

=head1 NAME

Class::Accessor::TrackDirty - Define simple entities stored in some places.

=head1 SYNOPSIS

    package UserInfo;
    use Class::Accessor::TrackDirty;
    Class::Accessor::TrackDirty->mk_new_and_accessors("name", "password");
    Class::Accessor::TrackDirty->mk_volatile_accessors("modified");

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

Class::Accessor::TrackDirty defines simple entities stored in files, RDBMS, KVS, and so on.

=head1 INTERFACE

=head2 Functions

=head3 C<< Class::Accessor::TrackDirty->mk_accessors("name1", "name2", ...); >>

=head3 C<< Class::Accessor::TrackDirty->mk_volatile_accessors("name1", "name2", ...); >>

=head3 C<< Class::Accessor::TrackDirty->mk_new; >>

=head3 C<< Class::Accessor::TrackDirty->mk_new_and_accessors("name1", "name2", ...); >>

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
