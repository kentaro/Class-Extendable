package Class::Extendable;
use strict;
use warnings;
use 5.008008;
our $VERSION = '0.01';

use Carp ();
use Class::Inspector;

my %SINGLETON_METHODS;

sub import {
    my ($class) = caller;

    {
        no strict 'refs';

        *{"$class\::extend"} = sub {
            my ($self, @classes) = @_;
            for my $class (@classes) {
                for my $function (@{Class::Inspector->functions($class) || []}) {
                    my $code_ref = $class->can($function);
                    $SINGLETON_METHODS{$self+0}{$function} = $code_ref;
                }
            }

            if ($self->can('extended')) {
                $self->extended(@classes);
            }
        };

        my $orig_can = $class->can('can');
        *{"$class\::can"} = sub {
            my ($self, $method) = @_;
            my $code_ref = $SINGLETON_METHODS{$self+0}{$method};
            return $code_ref if $code_ref;
            $orig_can->($self, $method);
        };

        *{"$class\::DESTROY"} = sub {
            my $self = shift;
            delete $SINGLETON_METHODS{$self+0};
        };

        *{"$class\::AUTOLOAD"} = sub {
            my $self   = shift;
            my $method = ${"$class\::AUTOLOAD"};
               $method =~ s/.*:://;

            if (my $code_ref = $SINGLETON_METHODS{$self+0}{$method}) {
                $code_ref->($self, @_);
            }
            else {
                my $pkg = ref $self;
                Carp::croak qq(Can't locate object method "$method" via package "$pkg");
            }
        }
    }
}

!!1;

__END__

=encoding utf8

=head1 NAME

Class::Extendable - Extendable like Ruby's `singleton method`

=head1 SYNOPSIS

  package My::Foo;
  use Class::Extendable;
  sub new { bless {}, shift }

  package My::Bar;
  sub bar {}

  package main;
  my $obj1 = My::Foo->new;
  my $obj2 = My::Foo->new;

  ok !$obj1->can('bar');
  ok !$obj2->can('bar');

  $obj1->extend('My::Bar');

  # Now that `$obj1` extended, it can receive all the methods in `My::Bar`
  ok $obj1->can('bar');
  ok !$obj2->can('bar');

=head1 DESCRIPTION

Class::Extendable provides a feature like Ruby's `singleton
method`. Once some object is extended with other classes, only that
object can receive all the methods in those classes, without affecting
the object's class.

=head1 AUTHOR

Kentaro Kuribayashi E<lt>kentarok@gmail.comE<gt>

=head1 SEE ALSO

=over 4

=item * http://blog.livedoor.jp/dankogai/archives/50484421.html

=back

=head1 LICENSE

Copyright (C) Kentaro Kuribayashi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
