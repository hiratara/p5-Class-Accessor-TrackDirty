use strict;
use warnings;
use Test::More;
use t::TestEntity;
use t::CasualEntity;

for (qw(TestEntity CasualEntity)) {
    {
        my $entity = "t::$_"->new({key1 => 35});
        ok $entity->is_modified, "The new entity should be stored";
        $entity->is_modified(undef);
        ok $entity->is_modified, "You can't modify is_modified.";
    }

    {
        my $entity = "t::$_"->new({});
        ok $entity->is_modified, "Save empty data";

        $entity->revert;
        ok $entity->is_modified, "Is reverted but it has not been serialized.";

        $entity->key1(18);
        is $entity->key1, 18, "Ordinary use after reverting.";
        ok $entity->is_modified, "The key1 field was modified.";
    }

    {
        my $entity = "t::$_"->new({
            is_modified => 1,
        });
        $entity->key1(99);  # Keep _origin field from being defined.

        $entity->revert;
        ok $entity->is_modified, "Is reverted but it has not been serialized.";
    }

    {
        my $entity = "t::$_"->from_hash({
            key1 => 35,
        });
        ok ! $entity->is_modified, "need not store the loaded data";
        $entity->is_modified(1);
        ok ! $entity->is_modified, "You can't modify is_modified.";

        $entity->key1(35);
        $entity->key2(undef);
        ok ! $entity->is_modified, "I didn't change anything :p";
        ok ! $entity->is_modified, "I didn't change anything :p";

        $entity->key1(36);
        $entity->key2("something");
        ok $entity->is_modified, "Changed";
        ok $entity->is_modified, "Changed";

        $entity->key1(35);
        $entity->key2(undef);
        ok ! $entity->is_modified, "Finally return to the original value :p";
        ok ! $entity->is_modified, "Finally return to the original value :p";

        $entity->key1(36);
        $entity->key2("something");
        $entity->revert;
        is $entity->key1, 35, "reverted changes";
        is $entity->key2, undef, "reverted changes";
        ok ! $entity->is_modified, "reverted all statuses";

        # Freeze all changes
        $entity->key1(36);
        $entity->key2('hiratara');
        my $hash = $entity->to_hash;
        is $hash->{key1}, 36;
        is $entity->key1, 36;
        ok ! $entity->is_modified, "Reset the is_modified field";
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
        ok ! $entity->is_modified, "Don't save the modification of modified";

        $entity->key1(36);
        my $hash = $entity->is_modified ? $entity->to_hash : {};
        is $hash->{key1}, 36;
        ok ! exists $hash->{mtime}, "Don't store volatile fields";
    }

    {
        my $entity = "t::$_"->from_hash({
            is_modified => 1,
        });
        ok ! $entity->is_modified, "You mustn't set is_modified.";
    }
}

done_testing;
