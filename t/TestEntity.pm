package t::TestEntity;
use strict;
use warnings;
use Class::Stored;

fields qw(key1 key2);
volatile_fields qw(mtime);

1;
