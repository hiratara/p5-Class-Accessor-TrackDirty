package t::SimpleEntity;
use strict;
use warnings;
use Class::Stored;

Class::Stored->mk_new_and_accessors(qw(key1 key2));
Class::Stored->mk_volatile_accessors(qw(mtime));

1;
