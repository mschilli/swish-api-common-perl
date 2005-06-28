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
