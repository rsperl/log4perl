##################################################
package Log::Log4perl::Namespace;
##################################################

use 5.006;
use strict;
use warnings;

use Log::Log4perl;

###########################################
sub new {
###########################################
    my( $class, $name ) = @_;

    $name = "default" if !defined $name;

    my $self = {
        root_logger        => undef,
        loggers_by_name    => {},
        appenders_by_name  => {},
        initialized        => 0,
        non_init_warned    => 0,
        warn_appender_name => "_l4p_warn",
    };

    return bless $self, $class;
}

###########################################
sub reset {
###########################################
    my( $self ) = @_;
}

###########################################
sub warn_appender_setup {
###########################################
    my( $self ) = @_;

    # Define the default appender that's used for formatting
    # warn/die/croak etc. messages.
    $self->{ warn_appender } = 
        Log::Log4perl::Appender->new(
            "Log::Log4perl::Appender::String",
            name => $self->{ warn_appender_name } );

    $self->{ warn_appender }->layout(
        Log::Log4perl::Layout::PatternLayout->new("%m") );

    $self->{ warn_appender_coderef } =
        Log::Log4perl::Logger(
            generate_coderef(
              [ [ $self->{ warn_appender_name }, 
                  $self->{ warn_appender }] ] );
}

###########################################
sub warning_render {
###########################################
    my( $self, $logger, @message) = @_;

    $self->{ warn_appender }->string("");
    $self->{ warn_appender_coderef }->($logger, 
                          @message, 
                          Log::Log4perl::Level::to_level($ALL));
    return $self->{ warn_appender }->string();
}

TODO

##################################################
sub cleanup {
##################################################
    # warn "Logger cleanup";

    # Nuke all convenience loggers to avoid them causing cleanup to 
    # be delayed until global destruction. Problem is that something like
    #     *{"DEBUG"} = sub { $logger->debug };
    # ties up a reference to $logger until global destruction, so we 
    # need to clean up all :easy shortcuts, hence freeing the last
    # logger references, to then rely on the garbage collector for cleaning
    # up the loggers.
    Log::Log4perl->easy_closure_global_cleanup();

    # Delete all loggers
    $LOGGERS_BY_NAME = {};

    # Delete the root logger
    undef $ROOT_LOGGER;

    # Delete all appenders
    %APPENDER_BY_NAME   = ();

    undef $INITIALIZED;
}

##################################################
sub DESTROY {
##################################################
    CORE::warn "Destroying logger $_[0] ($_[0]->{category})" 
            if $Log::Log4perl::CHATTY_DESTROY_METHODS;
}

##################################################
sub reset {
##################################################
    $ROOT_LOGGER        = __PACKAGE__->_new("", $OFF);
#    $LOGGERS_BY_NAME    = {};  #leave this alone, it's used by 
                                #reset_all_output_methods when 
                                #the config changes

    %APPENDER_BY_NAME   = ();
    undef $INITIALIZED;
    undef $NON_INIT_WARNED;
    Log::Log4perl::Appender::reset();

    #clear out all the existing appenders
    foreach my $logger (values %$LOGGERS_BY_NAME){
        $logger->{appender_names} = [];

	#this next bit deals with an init_and_watch case where a category
	#is deleted from the config file, we need to zero out the existing
	#loggers so ones not in the config file not continue with their old
	#behavior --kg
        next if $logger eq $ROOT_LOGGER;
        $logger->{level} = undef;
        $logger->level();  #set it from the hierarchy
    }

    # Clear all filters
    Log::Log4perl::Filter::reset();
}

##################################################
sub reset_all_output_methods {
##################################################
    print "reset_all_output_methods: \n" if _INTERNAL_DEBUG;

    foreach my $loggername ( keys %$LOGGERS_BY_NAME){
        $LOGGERS_BY_NAME->{$loggername}->set_output_methods;
    }
    $ROOT_LOGGER->set_output_methods;
}

##################################################
sub get_root_logger {
##################################################
    my($class) = @_;
    return $ROOT_LOGGER;    
}

1;

__END__

=encoding utf8

=head1 NAME

Log::Log4perl::Namespace - A whole world of loggers

=head1 SYNOPSIS

    # It's not here

=head1 DESCRIPTION

Compartment for a world of loggers.

=head1 LICENSE

Copyright 2002-2013 by Mike Schilli E<lt>m@perlmeister.comE<gt> 
and Kevin Goess E<lt>cpan@goess.orgE<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 AUTHOR

Please contribute patches to the project on Github:

    http://github.com/mschilli/log4perl

Send bug reports or requests for enhancements to the authors via our

MAILING LIST (questions, bug reports, suggestions/patches): 
log4perl-devel@lists.sourceforge.net

Authors (please contact them via the list above, not directly):
Mike Schilli <m@perlmeister.com>,
Kevin Goess <cpan@goess.org>

Contributors (in alphabetical order):
Ateeq Altaf, Cory Bennett, Jens Berthold, Jeremy Bopp, Hutton
Davidson, Chris R. Donnelly, Matisse Enzer, Hugh Esco, Anthony
Foiani, James FitzGibbon, Carl Franks, Dennis Gregorovic, Andy
Grundman, Paul Harrington, Alexander Hartmaier  David Hull, 
Robert Jacobson, Jason Kohles, Jeff Macdonald, Markus Peter, 
Brett Rann, Peter Rabbitson, Erik Selberg, Aaron Straup Cope, 
Lars Thegler, David Viner, Mac Yang.

