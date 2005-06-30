######################################################################
# Test suite for SWISH::API::Common
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More qw(no_plan);
use Sysadm::Install qw(:all);
use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);

BEGIN { use_ok('SWISH::API::Common') };

my $CANNED = "eg/canned";
$CANNED = "../eg/canned" unless -d $CANNED;

use SWISH::API::Common;

    # Not preserving atime
my $sw = SWISH::API::Common->new(swish_adm_dir => "$CANNED/adm");

my($atime, $mtime) = (stat("$CANNED/abc"))[8,9];
die "Cannot get atime" unless $atime;
sleep(1);

$sw->index("$CANNED/abc");

my($atime2, $mtime2) = (stat("$CANNED/abc"))[8,9];

isnt($atime, $atime2, "atime modified by index");
is($mtime, $mtime2, "mtime unmodified by index");

    # Not preserving atime
$sw = SWISH::API::Common->new(swish_adm_dir  => "$CANNED/adm",
                              atime_preserve => 1);

($atime, $mtime) = (stat("$CANNED/abc"))[8,9];
die "Cannot get atime" unless $atime;

sleep(1);
$sw->index("$CANNED/abc");

($atime2, $mtime2) = (stat("$CANNED/abc"))[8,9];

is($atime, $atime2, "atime unmodified by index");
is($mtime, $mtime2, "mtime unmodified by index");

END { rmf "$CANNED/adm"; }
