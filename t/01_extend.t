use strict;
use warnings;
use Test::More;

subtest 'extends object' => sub {
    my $obj1 = My::Foo->new;
    my $obj2 = My::Foo->new;

    ok !$obj1->can('bar');
    ok !$obj2->can('bar');

    $obj1->extend(qw(My::Bar My::Baz));

    ok $obj1->can('bar');
    ok !$obj2->can('bar');
    ok $obj1->can('baz');
    ok !$obj2->can('baz');
};

package My::Foo;
use Class::Extendable;
sub new { bless {}, shift }

package My::Bar;
sub bar {}

package My::Baz;
sub baz {}

package main;

done_testing;
