use strict;
use warnings;
use lib '.';
use Test::More;
use t::SimpleEntity;
use t::TestEntity;
use t::CasualEntity;
use constant FALSE_VALUE => !!0;

for (qw(SimpleEntity TestEntity CasualEntity)) {
    {
        my $entity = "t::$_"->new({
            key1 => 36, mtime => 1389955234,
            not_managed_by_tdirty => 'HOGEHOGE',
        });
        is_deeply $entity->raw, {key1 => 36, mtime => 1389955234};
        ok $entity->is_dirty, "Haven't been saved yet";

        $entity->key1(37);
        $entity->mtime(1389955235);
        is_deeply $entity->raw, {
            key1 => 37, mtime => 1389955235,
        };
        ok $entity->is_dirty, "Has not been stored yet";

        (undef) = $entity->to_hash; # Stored into some storages

        is_deeply $entity->raw, {
            key1 => 37, mtime => 1389955235,
        };
        is $entity->is_dirty, FALSE_VALUE, "Stored all data";

        $entity->key1(36);
        $entity->mtime(1389955234);
        is_deeply $entity->raw, {
            key1 => 36, mtime => 1389955234,
        };
        ok $entity->is_dirty, "Has not been stored yet";
    }

    {
        my $entity = "t::$_"->from_hash({
            key1 => 36, mtime => 1389955234,
            not_managed_by_tdirty => 'HOGEHOGE',
        });
        is_deeply $entity->raw, {key1 => 36, mtime => 1389955234};
        is $entity->is_dirty, FALSE_VALUE, "Fresh instance";

        (undef) = $entity->to_hash; # Stored into some storages

        is_deeply $entity->raw, {key1 => 36, mtime => 1389955234};
        is $entity->is_dirty, FALSE_VALUE, "Fresh instance";
    }
}

done_testing;
