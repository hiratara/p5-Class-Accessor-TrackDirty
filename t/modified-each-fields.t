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
        my $entity = "t::$_"->new({key1 => "ABC", mtime => time});
        ok $entity->is_dirty('key1'), "The field hasn't been stored";
        ok $entity->is_dirty('key2');
        is $entity->is_dirty('mtime'), undef, "Isn't managed by TrackDirty";
        ok eq_set([$entity->dirty_fields], [qw(key1 key2)]);
    }

    {
        my $entity = "t::$_"->from_hash({
            key1 => "ABC",
            key2 => "abc",
            mtime => 1662538400,  # Wed Sep  7 08:13:20 2022 UTC
        });
        is $entity->is_dirty('key1'), FALSE_VALUE;
        is $entity->is_dirty('key2'), FALSE_VALUE;
        is $entity->is_dirty('mtime'), undef, q(Isn't managed by TrackDirty (2));
        ok eq_set([$entity->dirty_fields], [qw()]);

        $entity->key1("XYZ");
        $entity->key2("abc");
        $entity->mtime($entity->mtime + 1);
        ok $entity->is_dirty('key1');
        is $entity->is_dirty('key2'), FALSE_VALUE;
        is $entity->is_dirty('mtime'), undef, q(Isn't managed by TrackDirty (3));
        ok eq_set([$entity->dirty_fields], [qw(key1)]);

        $entity->key1("ABC");
        $entity->key2("xyz");
        is $entity->is_dirty('key1'), FALSE_VALUE;
        ok $entity->is_dirty('key2');
        ok eq_set([$entity->dirty_fields], [qw(key2)]);

        $entity->key1("XYZ");
        ok $entity->is_dirty('key1');
        ok $entity->is_dirty('key2');
        ok eq_set([$entity->dirty_fields], [qw(key1 key2)]);

        $entity->to_hash; # Will be stored into any places
        is $entity->is_dirty('key1'), FALSE_VALUE;
        is $entity->is_dirty('key2'), FALSE_VALUE;
        is $entity->is_dirty('mtime'), undef, q(Isn't managed by TrackDirty (4));
        ok eq_set([$entity->dirty_fields], [qw()]);
    }
}

done_testing;
