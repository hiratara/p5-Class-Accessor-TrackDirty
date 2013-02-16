package t::CasualEntity;
use strict;
use warnings;
use Class::Stored;

fields qw(key1 key2);
volatile_fields qw(mtime);

sub new {
    my $class = shift;

    # I don't need any checks :)
    bless {@_ == 1 ? %{$_[0]} : @_} => $class;
}

1;
