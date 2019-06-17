use strict;
use warnings;

use Bookmarker;
use Test::More tests => 2;
use Plack::Test;
use HTTP::Request::Common;
use Ref::Util qw<is_coderef>;

my $app = Bookmarker->to_app;
ok( is_coderef($app), 'Got app' );

my $test = Plack::Test->create($app);
my $res  = $test->request( GET '/?a=123' );

ok( $res->is_success, '[GET /] successful' );
warn $res->message, "\n" unless $res->is_success;
