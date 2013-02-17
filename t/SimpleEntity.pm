package t::SimpleEntity;
use strict;
use warnings;
use Class::Accessor::TrackDirty;

Class::Accessor::TrackDirty->mk_new_and_accessors(qw(key1 key2));
Class::Accessor::TrackDirty->mk_volatile_accessors(qw(mtime));

1;
