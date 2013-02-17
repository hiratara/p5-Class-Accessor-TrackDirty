use strict;
use warnings;
use Test::More;
use t::SimpleEntity;
use t::TestEntity;
use t::CasualEntity;

for (qw(SimpleEntity TestEntity CasualEntity)) {
    {
        my $entity = "t::$_"->new({key1 => 35});
        ok $entity->is_dirty, "The new entity should be stored";
        $entity->is_dirty(undef);
        ok $entity->is_dirty, "You can't modify is_dirty.";

        $entity->revert;
        is $entity->key1, undef, "All fields shoud be removed.";
        ok $entity->is_dirty, "The new entity should be stored";
    }

    {
        my $entity = "t::$_"->new({});
        ok $entity->is_dirty, "Save empty data";

        $entity->revert;
        ok $entity->is_dirty, "Is reverted but it has not been serialized.";

        $entity->key1(18);
        is $entity->key1, 18, "Ordinary use after reverting.";
        ok $entity->is_dirty, "The key1 field was modified.";
    }

    {
        my $entity = "t::$_"->new({
            is_dirty => 1,
        });
        $entity->key1(99);  # Keep _origin field from being defined.

        $entity->revert;
        ok $entity->is_dirty, "Is reverted but it has not been serialized.";
    }

    {
        my $entity = "t::$_"->from_hash({
            key1 => 35,
        });
        ok ! $entity->is_dirty, "need not store the loaded data";
        $entity->is_dirty(1);
        ok ! $entity->is_dirty, "You can't modify is_dirty.";

        $entity->key1(35);
        $entity->key2(undef);
        ok ! $entity->is_dirty, "I didn't change anything :p";
        ok ! $entity->is_dirty, "I didn't change anything :p";

        $entity->key1(36);
        $entity->key2("something");
        ok $entity->is_dirty, "Changed";
        ok $entity->is_dirty, "Changed";

        $entity->key1(35);
        $entity->key2(undef);
        ok ! $entity->is_dirty, "Finally return to the original value :p";
        ok ! $entity->is_dirty, "Finally return to the original value :p";

        $entity->key1(36);
        $entity->key2("something");
        $entity->revert;
        is $entity->key1, 35, "reverted changes";
        is $entity->key2, undef, "reverted changes";
        ok ! $entity->is_dirty, "reverted all statuses";

        # Freeze all changes
        $entity->key1(36);
        $entity->key2('hiratara');
        my $hash = $entity->to_hash;
        is $hash->{key1}, 36;
        is $entity->key1, 36;
        ok ! $entity->is_dirty, "Reset the is_dirty field";
    }

    {
        my $entity = "t::$_"->from_hash({
            # Sat Feb 16 13:38:31 2013
            key1 => 35, mtime => 1360989511,
        });
        is $entity->mtime, 1360989511, "Can load volatile fields";

        # Fri Feb 15 17:46:42 2013 JST
        $entity->mtime(1360918002);

        is $entity->mtime, 1360918002;
        ok ! $entity->is_dirty, "Don't save the modification of modified";

        $entity->revert;
        is $entity->mtime, 1360918002, "Can't revert volatile fields";

        $entity->key1(36);
        my $hash = $entity->is_dirty ? $entity->to_hash : {};
        is $hash->{key1}, 36;
        is $hash->{mtime}, 1360918002, "Store volatile fields";
    }

    {
        my $entity = "t::$_"->from_hash({
            is_dirty => 1,
        });
        ok ! $entity->is_dirty, "You mustn't set is_dirty.";
    }
}

done_testing;
