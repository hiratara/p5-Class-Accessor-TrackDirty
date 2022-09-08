use strict;
use warnings;
use lib '.';
use Test::More;
use t::SimpleEntity;
use constant FALSE_VALUE => !!0;

{
    my $entity = t::SimpleEntity->new(
        key1 => {nested => {count => 0}},
        key2 => [qw(x y)],
    );
    is $entity->key2->[1], 'y';
    ok $entity->is_dirty;

    $entity->key1->{nested}->{count}++;
    push @{$entity->key2}, 'z';
    is $entity->key1->{nested}->{count}, 1;
    ok $entity->is_dirty;

    $entity->revert;
    is $entity->key1, undef;
    is $entity->key2, undef;
    ok $entity->is_dirty;
}

{
    my $entity = t::SimpleEntity->from_hash(
        key1 => {nested => {count => 0}},
        key2 => [qw(x y)],
    );
    is $entity->key2->[1], 'y';
    is $entity->is_dirty, FALSE_VALUE;

    $entity->key1->{nested}->{count}++;
    push @{$entity->key2}, 'z';
    is $entity->key1->{nested}->{count}, 1;
    ok $entity->is_dirty;

    $entity->revert;
    is $entity->key1->{nested}->{count}, 0;
    is_deeply $entity->key2, ['x', 'y'];
    is $entity->is_dirty, FALSE_VALUE;
}

{
    my $entity = t::SimpleEntity->from_hash(
        key1 => {nested => {count => 0}},
        key2 => [qw(x y)],
    );

    # Change values
    $entity->key1->{nested}->{count}++;
    push @{$entity->key2}, 'z';

    # Revert by myself
    $entity->key1({nested => {count => 0}});
    pop @{$entity->key2};
    is $entity->key1->{nested}->{count}, 0;
    is_deeply $entity->key2, ['x', 'y'];
    is $entity->is_dirty, FALSE_VALUE;
}

{
    # [the reproducible test case] broken by Hash Randomization
    my %value1 = map { $_ => 1 } 1 .. 100;
    my $entity = t::SimpleEntity->from_hash(
        key1 => \%value1,
        key2 => [],
    );
    is $entity->is_dirty, FALSE_VALUE;
    is_deeply $entity->key1, \%value1;
    is $entity->is_dirty, FALSE_VALUE, 'clean, even after accessing key1';
}

done_testing;
