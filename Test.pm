module Test;
# Copyright (C) 2007, The Perl Foundation.
# $Id: Test.pm 34904 2009-01-03 23:24:38Z masak $

## This is a temporary Test.pm to get us started until we get pugs's Test.pm
## working. It's shamelessly stolen & adapted from MiniPerl6 in the pugs repo.

# globals to keep track of our tests
our $num_of_tests_run    = 0;
our $num_of_tests_failed = 0;
our $todo_upto_test_num  = 0;
our $todo_reason         = '';
our $num_of_tests_planned;
our $no_plan;
our $die_on_fail;

our $*WARNINGS = 0;

# for running the test suite multiple times in the same process
our $testing_started;


## test functions

# you can call die_on_fail; to turn it on and die_on_fail(0) to turn it off
sub die_on_fail($fail=1) {
    $die_on_fail = $fail;
}

# "plan 'no_plan';" is now "plan *;"
multi sub plan(Whatever $plan) is export(:DEFAULT) {
    $no_plan = 1;
}

multi sub plan($number_of_tests) is export(:DEFAULT) {
    $testing_started      = 1;

    $num_of_tests_planned = $number_of_tests;

    say '1..' ~ $number_of_tests;
}

multi sub pass($desc) is export(:DEFAULT) {
    proclaim(1, $desc);
}

multi sub ok(Object $cond, $desc) is export(:DEFAULT) {
    proclaim(?$cond, $desc);
}

multi sub ok(Object $cond) is export(:DEFAULT) { ok(?$cond, ''); }


multi sub nok(Object $cond, $desc) is export(:DEFAULT) {
    proclaim(!$cond, $desc);
}

multi sub nok(Object $cond) is export(:DEFAULT) { nok($cond, ''); }


multi sub is(Object $got, Object $expected, $desc) is export(:DEFAULT) {
    my $test = $got eq $expected;
    proclaim(?$test, $desc);
}

multi sub is(Object $got, Object $expected) is export(:DEFAULT) { is($got, $expected, ''); }


multi sub isnt(Object $got, Object $expected, $desc) is export(:DEFAULT) {
    my $test = !($got eq $expected);
    proclaim($test, $desc);
}

multi sub isnt(Object $got, Object $expected) is export(:DEFAULT) { isnt($got, $expected, ''); }

multi sub is_approx(Object $got, Object $expected, $desc) is export(:DEFAULT) {
    my $test = abs($got - $expected) <= 0.00001;
    proclaim(?$test, $desc);
}

multi sub is_approx(Object $got, Object $expected) is export(:DEFAULT) {
    is_approx($got, $expected, '');
}

multi sub todo($reason, $count) is export(:DEFAULT) {
    $todo_upto_test_num = $num_of_tests_run + $count;
    $todo_reason = '# TODO ' ~ $reason;
}

multi sub todo($reason) is export(:DEFAULT) {
    $todo_upto_test_num = $num_of_tests_run + 1;
    $todo_reason = '# TODO ' ~ $reason;
}

multi sub skip()                is export(:DEFAULT) { proclaim(1, "# SKIP"); }
multi sub skip($reason)         is export(:DEFAULT) { proclaim(1, "# SKIP " ~ $reason); }
multi sub skip($count, $reason) is export(:DEFAULT) {
    for 1..$count {
        proclaim(1, "# SKIP " ~ $reason);
    }
}

multi sub skip_rest() is export(:DEFAULT) {
    skip($num_of_tests_planned - $num_of_tests_run, "");
}

multi sub skip_rest($reason) is export(:DEFAULT) {
    skip($num_of_tests_planned - $num_of_tests_run, $reason);
}

sub diag($message) is export(:DEFAULT) { say '# '~$message; }


multi sub flunk($reason) is export(:DEFAULT) { proclaim(0, "flunk $reason")}


multi sub isa_ok(Object $var,$type) is export(:DEFAULT) {
    ok($var.isa($type), "The object is-a '$type'");
}
multi sub isa_ok(Object $var,$type, $msg) is export(:DEFAULT) { ok($var.isa($type), $msg); }

multi sub dies_ok(Callable $closure, $reason) is export(:DEFAULT) {
    try {
        $closure();
    }
    proclaim((defined $!), $reason);
}
multi sub dies_ok(Callable $closure) is export(:DEFAULT) {
    dies_ok($closure, '');
}

multi sub lives_ok(Callable $closure, $reason) is export(:DEFAULT) {
    try {
        $closure();
    }
    proclaim((not defined $!), $reason);
}
multi sub lives_ok(Callable $closure) is export(:DEFAULT) {
    lives_ok($closure, '');
}

multi sub eval_dies_ok(Str $code, $reason) is export(:DEFAULT) {
    proclaim((defined eval_exception($code)), $reason);
}
multi sub eval_dies_ok(Str $code) is export(:DEFAULT) {
    eval_dies_ok($code, '');
}

multi sub eval_lives_ok(Str $code, $reason) is export(:DEFAULT) {
    proclaim((not defined eval_exception($code)), $reason);
}
multi sub eval_lives_ok(Str $code) is export(:DEFAULT) {
    eval_lives_ok($code, '');
}


multi sub is_deeply(Object $this, Object $that, $reason) is export(:DEFAULT) {
    my $val = _is_deeply( $this, $that );
    proclaim($val, $reason);
}

multi sub is_deeply(Object $this, Object $that) is export(:DEFAULT) {
    my $val = _is_deeply( $this, $that );
    proclaim($val, '');
}

sub _is_deeply(Object $this, Object $that) {

    if $this ~~ List && $that ~~ List {
        return if +$this.values != +$that.values;
        for $this Z $that -> $a, $b {
            return if ! _is_deeply( $a, $b );
        }
        return True;
    }
    elsif $this ~~ Hash && $that ~~ Hash {
        return if +$this.keys != +$that.keys;
        for $this.keys.sort Z $that.keys.sort -> $a, $b {
            return if $a ne $b;
            return if ! _is_deeply( $this{$a}, $that{$b} );
        }
        return True;
    }
    elsif $this ~~ Str | Num | Int && $that ~~ Str | Num | Int {
        return $this eq $that;
    }
    elsif $this ~~ Pair && $that ~~ Pair {
        return $this.key eq $that.key
               && _is_deeply( $this.value, $this.value );
    }
    elsif $this ~~ undef && $that ~~ undef && $this.WHAT eq $that.WHAT {
        return True;
    }

    return;
}


## 'private' subs

sub eval_exception($code) {
    my $eval_exception;
    try { eval ($code); $eval_exception = $! }
    $eval_exception // $!;
}

sub proclaim($cond, $desc) {
    $testing_started  = 1;
    $num_of_tests_run = $num_of_tests_run + 1;

    unless $cond {
        print "not ";
        $num_of_tests_failed = $num_of_tests_failed + 1
            unless  $num_of_tests_run <= $todo_upto_test_num;
    }
    print "ok ", $num_of_tests_run, " - ", $desc;
    if $todo_reason and $num_of_tests_run <= $todo_upto_test_num {
        print $todo_reason;
    }
    print "\n";

    if !$cond && $die_on_fail && !$todo_reason {
        die "Test failed.  Stopping test";
    }
    # must clear this between tests
    $todo_reason = '';
    return $cond;
}

END {
    # until END blocks can access compile-time symbol tables of outer scopes,
    #  we need these declarations
    our $testing_started;
    our $num_of_tests_planned;
    our $num_of_tests_run;
    our $num_of_tests_failed;
    our $no_plan;

    if $no_plan {
        $num_of_tests_planned = $num_of_tests_run;
        say "1..$num_of_tests_planned";
    }

    if ($testing_started and $num_of_tests_planned != $num_of_tests_run) {  ##Wrong quantity of tests
        diag("Looks like you planned $num_of_tests_planned tests, but ran $num_of_tests_run");
    }
    if ($testing_started and $num_of_tests_failed) {
        diag("Looks like you failed $num_of_tests_failed tests of $num_of_tests_run");
    }
}

# vim: ft=perl6
