package Debug::EchoMessage;

use warnings;
use Carp;

# require Exporter;
@ISA = qw(Exporter);
our @EXPORT = qw(echoMSG debug disp_param);
our @EXPORT_OK = qw(debug echoMSG disp_param);
our %EXPORT_TAGS = (
  all => [@EXPORT_OK],
  echo_msg => [qw(debug echoMSG disp_param)],
);
our $VERSION = 1.00;

=head1 SYNOPSIS

    use Debug::EchoMessage;

=head1 DESCRIPTION

The package contains the modules can be used for debuging or displaying
contents of your runtime state. You would first define the level of 
each message in your program, then define a debug level that you would
like to see in your runtime.

{  # Encapsulated class data
   _debug      =>0,  # debug level
}

=head2 debug($n)

Input variables:

  $n   - a number between 0 and 100. It specifies the
         level of messages that you would like to
         display. The higher the number, the more
         detailed messages that you will get.

Variables used or routines called: None.

How to use:

  $self->debug(2);     # set the message level to 2
  print $self->debug;  # print current message level

Return: the debug level or set the debug level.

=cut

sub debug {
    # my ($c_pkg,$c_fn,$c_ln) = caller;
    # my $s =  ref($_[0])?shift:(bless {}, $c_pkg);
    my $s =  shift;
    croak "ERR: Too many args to debug." if @_ > 1;
    @_ ? ($s->{_debug}=shift) : return $s->{_debug};
}

=head2 echoMSG($msg, $lvl)

Input variables:

  $msg - the message to be displayed. No newline
         is needed in the end of the message. It
         will add the newline code at the end of
         the message.
  $lvl - the message level is assigned to the message.
         If it is higher than the debug level, then
         the message will not be displayed.

Variables used or routines called:

  debug - get debug level.

How to use:

  # default msg level to 0
  $self->echoMSG('This is a test");
  # set the msg level to 2
  $self->echoMSG('This is a test", 2);

Return: None.

This method will display message or a hash array based on I<debug>
level. If I<debug> is set to '0', no message or array will be
displayed. If I<debug> is set to '2', it will only display the message
level ($lvl) is less than or equal to '2'. If you call this
method without providing a message level, the message level ($lvl) is
default to '0'.  Of course, if no message is provided to the method,
it will be quietly returned.

This is how you can call I<echoMSG>:

  my $df = DataFax->new;
     $df->echoMSG("This is a test");   # default the msg to level 0
     $df->echoMSG("This is a test",1); # assign the msg as level 1 msg
     $df->echoMSG("Test again",2);     # assign the msg as level 2 msg
     $df->echoMSG($hrf,1);             # assign $hrf as level 1 msg
     $df->echoMSG($hrf,2);             # assign $hrf as level 2 msg

If I<debug> is set to '1', all the messages with default message level,
i.e., 0, and '1' will be displayed. The higher level messages
will not be displayed.

=cut

sub echoMSG {
    # my ($c_pkg,$c_fn,$c_ln) = caller;
    # my $self = ref($_[0])?shift:(bless {},$c_pkg);
    my $self = shift;
    my ($msg,$lvl) = @_;
    if (!defined($msg)) { return; }      # return if no msg
    if (!defined($lvl)) { $lvl = 0; }    # default level to 0
    my $class = ref($self)||$self;       # get class name
    my $dbg = $self->debug;              # get debug level
    if (!$dbg) { return; }               # return if not debug
    my $ref = ref($msg);
    if ($ref eq $class) {
        if ($lvl <= $dbg && $dbg < 200) { $self->disp_param($msg); }
    } else {
        $msg = "$msg\n";
        if (exists $ENV{QUERY_STRING}) { $msg =~ s/\n/<br>\n/gm; }
        if ($lvl <= $dbg && $dbg < 200) { print $msg; }
    }
}

=head2 disp_param($arf,$lzp)

Input variables:

  $arf - array reference
  $lzp - number of blank space indented in left

Variables used or routines called:

  echoMSG - print debug messages
  debug   - set debug level
  disp_param - recusively called

How to use:

  use Fax::DataFax::Subs qw(:echo_msg);
  my $self= bless {}, "main";
  $self->disp_param($arf);

Return: Display the content of the array.

=cut


sub disp_param {
    my ($self, $hrf, $lzp) = @_;
    $self->echoMSG(" -- displaying parameters...");
    if (!$lzp) { $lzp = 15; } else { $lzp +=4; }
    my $fmt;
    if (exists $ENV{QUERY_STRING}) {
        $fmt = "%${lzp}s = %-30s<br>\n";
    } else {
        $fmt = "%${lzp}s = %-30s\n";
    }
    if (!$hrf) {
        print "Please specify an array ref.\n";
        return;
    }
    # print join "|", $self, "HRF", $hrf, ref($hrf), "\n";
    my ($v);
    if (ref($hrf) eq 'HASH'|| $hrf =~ /.*=HASH/) {
        foreach my $k (sort keys %{$hrf}) {
            if (!defined(${$hrf}{$k})) { $v = "";
            } else { $v = ${$hrf}{$k}; }
            if ($v =~ /([-\w_]+)\/(\w+)\@(\w+)/) {
                $v =~ s{(\w+)/(\w+)\@}{$1/\*\*\*\@};
            }
            printf $fmt, $k, $v;
            if (ref($v) =~ /^(HASH|ARRAY)$/ ||
                $v =~ /.*=(HASH|ARRAY)/) {
                my $db1 = $self->debug;
                $self->debug(0);
                # print "$k = ${$hrf}{$k}: @{${$hrf}{$k}}\n";
                $self->disp_param(${$hrf}{$k},$lzp);
                $self->debug($db1);
                print "\n";
            }
        }
    } elsif (ref($hrf) eq 'ARRAY' || $hrf =~ /.*=ARRAY/) {
        foreach my $i (0..$#{$hrf}) {
            if (!defined(${$hrf}[$i])) { $v = "";
            } else { $v = ${$hrf}[$i]; }
            if ($v =~ /([-\w_]+)\/(\w+)\@(\w+)/) {
                $v =~ s{(\w+)/(\w+)\@}{$1/\*\*\*\@};
            }
            printf $fmt, $i, $v;
            if (ref($v) =~ /^(HASH|ARRAY)$/ ||
                $v =~ /.*=(HASH|ARRAY)/) {
                my $db1 = $self->debug;
                $self->debug(0);
                $self->disp_param(${$hrf}[$i],$lzp);
                $self->debug($db1);
                print "\n";
            }
        }
    }
}

=head1 CODING HISTORY

=over 4

=item * Version 0.01

04/15/2000 (htu) - Initial coding

=item * Version 0.02

04/16/2001 (htu) - finished debug and echoMSG

=item * Version 0.03

05/19/2001 (htu) - added disp_param 

=item * Version 1.00

06/25/2002 (htu) - added HTML format in disp_param 

=back

=head1 FUTURE IMPLEMENTATION

=over 4

=item * no plan yet 

=back

=head1 AUTHOR

Copyright (c) 2004 Hanming Tu.  All rights reserved.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut

