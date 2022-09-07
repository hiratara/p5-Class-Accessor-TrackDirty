# NAME

Class::Accessor::TrackDirty - Define simple entities stored in some places.

# SYNOPSIS

    package UserInfo;
    use Class::Accessor::TrackDirty;
    Class::Accessor::TrackDirty->mk_new_and_tracked_accessors("name", "password");
    Class::Accessor::TrackDirty->mk_accessors("modified");

    package main;
    my $user = UserInfo->new({name => 'honma', password => 'F!aS3l'});
    store_into_someplace($user->to_hash) if $user->is_dirty;
    # ...
    $user = UserInfo->from_hash(restore_from_someplace());
    $user->name('hiratara');
    $user->revert; # but decided not to
    $user->name('honma');
    $user->name('hiratara');
    $user->name('honma'); # I can't make up my mind...
    # ... blabla ...

    # Check the status of fields if needed
    $user->is_dirty('name') and warn "Did you change name?";
    my @dirty_fields = $user->dirty_fields;

    # Store it only if $user was really modified.
    store_into_someplace($user->to_hash) if $user->is_dirty;

# DESCRIPTION

Class::Accessor::TrackDirty defines simple entities stored in files, RDBMS,
KVS, and so on. It tracks dirty columns and you can store it only when the
instance was really modified.

# INTERFACE

## Functions

### `Class::Accessor::TrackDirty->mk_new;`

Create the `<new`> methods in your class.
You can pass a hash-ref or hash-like list to `<new`> method.

- `my $object = YourClass->new({name1 => "value1", ...});`

    The instance created by `<new`> is regarded as \`dirty' since it hasn't been
    stored yet.

### `Class::Accessor::TrackDirty->mk_tracked_accessors("name1", "name2", ...);`

Create accessor methods and helper methods in your class.
Following helper methods will be created automatically.

- `$your_object->is_dirty;`
- `$your_object->is_dirty("field_name");`

    Check that the instance is modified. If it's true, you should store this
    instance into some place through using `<to_hash`> method.

    When you pass the name of a field, you can know if the field contains the same
    value as the stored object. Returns `undef` if the field is not tracked,
    otherwise returns a defined boolean value.

- `my @fields = $your_object->dirty_fields;`

    Gets the name of all dirty fields of `$your_object`.

- `$your_object->is_new;`

    Checks if the instance might be in a storage. Returns false value when
    the instance comes from `from_hash` method, or after you call
    `to_hash` method.

- `my $hash_ref = $your_object->to_hash;`

    Eject data from this instance as plain hash-ref format.
    `<$your_object`> is regarded as \`clean' after calling this method.

    You'd better store `<$hash_ref`> into some place ASAP. It's up to you how
    `<$hash_ref`> should be serialized.

- `$your_object->raw;`

    Retrieves the row data from the instance. The return value is the same as
    `to_hash` method, but this method doesn't change the state of the
    instance.

- `my $object = YourClass->from_hash({name1 => "value1", ...});`

    Rebuild the instance from a hash-ref ejected by `<to_hash`> method.
    The instance constructed by `<from_hash`> is regarded as \`clean'.

- `$your_object->revert;`

    Revert all \`dirty' changes. Fields created by `<mk_tracked_accessors`> returns to
    the point where you call `<new`>, `<to_hash`>, or `<from_hash`>.

    The volatile fields will be never reverted.

You'd better \*NOT\* store references in tracked fields. Though following codes
work well, to make `revert` work well, we'll have to copy references deeply
when you call getter.

    my $your_object = YourClass->new(some_refs => {key => 'value'});
    # some_refs are copyied deeply :(
    $your_object->some_refs->{key} = '<censored>';

    $your_object->revert;
    print $your_object->some_refs, "\n"; # printed "value"

### `Class::Accessor::TrackDirty->mk_accessors("name1", "name2", ...);`

Define the field which isn't tracked. You can freely change these fields,
and it will never be marked as \`dirty'.

### `Class::Accessor::TrackDirty->mk_new_and_tracked_accessors("name1", "name2", ...);`

This method is a combination of `<mk_tracked_accessors`> and `<mk_new`>.

# SEE ALSO

[Class::Accessor](https://metacpan.org/pod/Class%3A%3AAccessor), [Class::Accessor::Lite](https://metacpan.org/pod/Class%3A%3AAccessor%3A%3ALite), [MooseX::TrackDirty::Attributes](https://metacpan.org/pod/MooseX%3A%3ATrackDirty%3A%3AAttributes), [Hash::Dirty](https://metacpan.org/pod/Hash%3A%3ADirty)

# AUTHOR

Masahiro Honma <hiratara@cpan.org>

# LICENSE AND COPYRIGHT

Copyright (c) 2013, Masahiro Honma. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
