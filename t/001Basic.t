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
my $sw = SWISH::API::Common->new(
  swish_adm_dir             => "$CANNED/adm",
  swish_fuzzy_indexing_mode => "NONE",
);
$sw->index($CANNED);

my @found = $sw->search("mike");
my $found = join " ", map { $_->path } @found;
like($found, qr(canned/abc), "simple query");

@found = $sw->search("someone AND else");
$found = join " ", map { $_->path } @found;
like($found, qr(canned/def), "boolean query");

@found = $sw->search("someone AND else OR mike");
$found = join " ", map { $_->path } @found;
like($found, qr(canned/def), "and-or query");
like($found, qr(canned/abc), "and-or query");

#END { rmf "$CANNED/adm"; }
