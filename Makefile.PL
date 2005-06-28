######################################################################
# Makefile.PL for SWISH::API::Common
# 2005, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'SWISH::API::Common',
    'VERSION_FROM' => 'lib/SWISH/API/Common.pm', # finds $VERSION
    'PREREQ_PM'    => {
                        Sysadm::Install => 0,
                        Log::Log4perl   => 0,
                        SWISH::API      => 0,
                        File::Path      => 0,
                        File::Find      => 0,
                        File::Basename  => 0,
                      }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/SWISH/API/Common.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);

my $version = `swish-e -V`;

if($version !~ /SWISH/) {
        print <<EOT;

     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
     This module requires the SWISH library, available from 
         http://swish-e.org/download/index.html
     Please download and install it prior to installing this module.
     Steps:
         tar zxfv swish-e-2.4.x.tar.gz
         cd swish-e-2.4.x
         ./configure
         make
         make install
     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
EOT

exit 0;
}
