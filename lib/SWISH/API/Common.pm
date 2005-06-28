###########################################
# SWISH::API::Common
###########################################

###########################################
package SWISH::API::Common;
###########################################

use strict;
use warnings;

our $VERSION = "0.01";

use SWISH::API;
use File::Path;
use File::Find;
use File::Basename;
use Log::Log4perl qw(:easy);
use Sysadm::Install qw(:all);

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        swish_adm_dir  => "$ENV{HOME}/.swish-common",
        swish_exe      => "swish-e",
        %options,
    };

    my $defaults = {
        swish_idx_file => "$self->{swish_adm_dir}/default.idx",
        swish_cnf_file => "$self->{swish_adm_dir}/default.cnf",
        dirs_file      => "$self->{swish_adm_dir}/default.dirs",
        streamer       => "$self->{swish_adm_dir}/default.streamer",
        file_len_max   => 100_000,
    };

    for my $name (keys %$defaults) {
        if(! exists $self->{$name}) {
            $self->{$name} = $defaults->{$name};
        }
    }

    bless $self, $class;
}

###########################################
sub index_remove {
###########################################
    my($self) = @_;

    unlink $self->{swish_idx_file};
}

###########################################
sub search {
###########################################
    my($self, $term) = @_;

    if(! -f $self->{swish_idx_file}) {
        ERROR "Index file $self->{swish_idx_file} not found";
        return undef;
    }

    my $swish = SWISH::API->new($self->{swish_idx_file});

    $swish->AbortLastError 
        if $swish->Error;

    my $results = $swish->Query($term);

    $swish->AbortLastError 
        if $swish->Error;

       # We might change this in the future to return an iterator
       # in scalar context
    my @results = ();

    while (my $r = $results->NextResult) {
        my $hit = SWISH::API::Common::Hit->new(
                      path => $r->Property("swishdocpath")
                  );
        push @results, $hit;
    }

    return @results;
}

###########################################
sub files_stream {
###########################################
    my($self) = @_;

    my @dirs = split /,/, slurp $self->{dirs_file};

    find(sub {
        return unless -f;
        return unless -T;

        my $full = $File::Find::name;

        DEBUG "Indexing $full";

        open FILE, "<$_" or die;
        my $rc = sysread FILE, my $data, $self->{file_len_max};

        unless(defined $rc) {
            WARN "Can't read $full: $!";
            return;
        }
        close FILE;

        my $size = length $data;

        print "Path-Name: $full\n",
              "Document-Type: TXT*\n",
              "Content-Length: $size\n\n";
        print $data;

    }, @dirs);
}

############################################
sub dir_prep {
############################################
    my($file) = @_;

    my $dir = dirname($file);

    if(! -d $dir) {
        mkd($dir) unless -d $dir;
    }
}

############################################
sub index {
############################################
    my($self, $dir) = @_;

        # Make a new dirs file
    dir_prep($self->{dirs_file});
    blurt $dir, $self->{dirs_file};

        # Make a new swish conf file
    dir_prep($self->{swish_cnf_file});
    blurt <<EOT, $self->{swish_cnf_file};
IndexDir  $self->{streamer}
IndexFile $self->{swish_idx_file}
UseStemming Yes
EOT

        # Make a new streamer
    dir_prep($self->{streamer});
    blurt <<EOT, $self->{streamer};
#!/usr/bin/perl
use SWISH::API::Common;
SWISH::API::Common->new()->files_stream();
EOT

    chmod 0755, $self->{streamer} or 
        LOGDIE "chmod of $self->{streamer} failed ($!)";

    my($stdout, $stderr, $rc) = tap($self->{swish_exe}, "-c",
                                    $self->{swish_cnf_file},
                                    "-S", "prog");

    unless($stdout =~ /Indexing done!/) {
        ERROR "Indexing failed: $stdout $stderr";
        return undef;
    }

    1;
}

###########################################
package SWISH::API::Common::Hit;
###########################################

make_accessor(__PACKAGE__, "path");

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        %options,
    };

    bless $self, $class;
}

##################################################
# Poor man's Class::Struct
##################################################
sub make_accessor {
##################################################
    my($package, $name) = @_;

    no strict qw(refs);

    my $code = <<EOT;
        *{"$package\\::$name"} = sub {
            my(\$self, \$value) = \@_;
    
            if(defined \$value) {
                \$self->{$name} = \$value;
            }
            if(exists \$self->{$name}) {
                return (\$self->{$name});
            } else {
                return "";
            }
        }
EOT
    if(! defined *{"$package\::$name"}) {
        eval $code or die "$@";
    }
}

1;

__END__

=head1 NAME

SWISH::API::Common - SWISH Document Indexing Made Easy

=head1 SYNOPSIS

    use SWISH::API::Common;

    my $swish = SWISH::API::Common->new();

        # Index all files in a directory and its subdirectories
    $swish->index("/usr/local/share/doc");

        # After indexing once (it's persistent), fire up as many
        # queries as you like:

        # Search documents containing both "swish" and "install"
    for my $hit (@{$swish->search("swish AND install")}) {
        print $hit->path(), "\n";
    }

=head1 DESCRIPTION

C<SWISH::API::Common> offers an easy interface to the Swish index engine.
While SWISH::API offers a complete API, C<SWISH::API::Common> focusses
on ease of use. 

THIS MODULE IS CURRENTLY UNDER DEVELOPMENT. THE API MIGHT CHANGE AT ANY
TIME.

Currently, C<SWISH::API::Common> just allows for indexing documents
in a single directory and any of its subdirectories.

=head1 INSTALLATION

C<SWISH::API::Common> requires C<SWISH::API> and the swish engine to
be installed. Please download the latest release from 

    http://swish-e.org/distribution/swish-e-2.4.3.tar.gz

and untar it, type

    ./configure
    make
    make install

and then install SWISH::API and SWISH::API::Common.

=head2 METHODS

=over 4

=item $sw = SWISH::API::Common-E<gt>new()

Constructor. Takes many options, but the defaults are usually fine.

Available options and their defaults:

    swish_adm_dir   "$ENV{HOME}/.swish-common"
    swish_exe       "swish-e"
    swish_idx_file  "$self->{swish_adm_dir}/default.idx"
    swish_cnf_file  "$self->{swish_adm_dir}/default.cnf"

=item $sw-E<gt>index($dir)

Generate a new index of all text documents under directory C<$dir>.

=item $sw-E<gt>search("foo AND bar");

Searches the index, using the given search expression. Returns a list
hits, which can be asked for their path:

        # Search documents containing 
        # both "foo" and "bar"
    for my $hit (@{$swish->search("foo AND bar")}) {
        print $hit->path(), "\n";
    }

=item index_remove

Permanently delete the current index.

=back 

=head1 TODO List

    * More than one index directory
    * Remove documents from index
    * determine /usr/bin/perl line in streamer generally
    * Iterator for search hits

=head1 LEGALESE

Copyright 2005 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2005, Mike Schilli <cpan@perlmeister.com>
