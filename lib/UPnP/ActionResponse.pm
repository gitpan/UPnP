package UPnP::ActionResponse;

#-----------------------------------------------------------------
# UPnP::ActionResponse
#-----------------------------------------------------------------

use strict;

use UPnP::HTTP;
use UPnP::HTTPResponse;

use vars qw($_HTTP_RESPONSE);

$_HTTP_RESPONSE = 'httpres';

#------------------------------
# new
#------------------------------

sub new {
	my($class) = shift;
	my($this) = {
		$UPnP::ActionResponse::_HTTP_RESPONSE => undef,
	};
	bless $this, $class;
}

#------------------------------
# header
#------------------------------

sub sethttpresponse() {
	my($this) = shift;
	$this->{$UPnP::ActionResponse::_HTTP_RESPONSE} = $_[0];
 }

sub gethttpresponse() {
	my($this) = shift;
	$this->{$UPnP::ActionResponse::_HTTP_RESPONSE};
 }
 
#------------------------------
# status
#------------------------------

sub getstatus() {
	my($this) = shift;
	my($http_res) = $this->gethttpresponse();
	$http_res->getstatus();
 }

sub getstatuscode() {
	my($this) = shift;
	my($http_res) = $this->gethttpresponse();
	$http_res->getstatuscode();
 }

#------------------------------
# header
#------------------------------

sub getheader() {
	my($this) = shift;
	my($http_res) = $this->gethttpresponse();
	$http_res->getheader();
 }

#------------------------------
# content
#------------------------------

sub getcontent() {
	my($this) = shift;
	my($http_res) = $this->gethttpresponse();
	$http_res->getcontent();
 }

#------------------------------
# content
#------------------------------

sub getargumentlist() {
	my($this) = shift;
	my(
		$http_res,
		%argument_list,
		$res_statcode,
		$res_content,
		$soap_response,
		$arg_name,
		$arg_value,
	);
	
	%argument_list = ();
	
	$http_res = $this->gethttpresponse();
	
	$res_statcode = $http_res->getstatuscode();
	if ($res_statcode != 200) {
		return \%argument_list;
	}

	$res_content = $http_res->getcontent();
	if ($res_content =~ m/<.*Response[^>]*>\s*(.*)\s*<\/.*Response>/si) {
		$soap_response = $1;
	}
	
	while ($soap_response =~ m/<([^>]*)>([^<]*)<\/[^>]*>/sg) {
		$arg_name = $1;
		$arg_value = $2;
		$arg_value = UPnP::HTTP::xmldecode($arg_value);
		$argument_list{$arg_name} = $arg_value;
	}
	
	return \%argument_list;
 }

1;

__END__

=head1 NAME

UPnP::ActionResponse - Perl extension for UPnP.

=head1 SYNOPSIS

    use UPnP::ControlPoint;

    my $obj = UPnP::ControlPoint->new();

    @dev_list = $obj->search(st =>'upnp:rootdevice', mx => 3);

    $devNum= 0;
    foreach $dev (@dev_list) {
        $device_type = $dev->getdevicetype();
        if  ($device_type ne 'urn:schemas-upnp-org:device:MediaServer:1') {
            next;
        }
        print "[$devNum] : " . $dev->getfriendlyname() . "\n";
        unless ($dev->getservicebyname('urn:schemas-upnp-org:service:ContentDirectory:1')) {
            next;
        }
        $condir_service = $dev->getservicebyname('urn:schemas-upnp-org:service:ContentDirectory:1');
        unless (defined(condir_service)) {
            next;
        }
        %action_in_arg = (
                'ObjectID' => 0,
                'BrowseFlag' => 'BrowseDirectChildren',
                'Filter' => '*',
                'StartingIndex' => 0,
                'RequestedCount' => 0,
                'SortCriteria' => '',
            );
        $action_res = $condir_service->postcontrol('Browse', \%action_in_arg);
        unless ($action_res->getstatuscode() == 200) {
        	next;
        }
        $actrion_out_arg = $action_res->getargumentlist();
        unless ($actrion_out_arg->{'Result'}) {
            next;
        }
        $result = $actrion_out_arg->{'Result'};
        while ($result =~ m/<dc:title>(.*?)<\/dc:title>/sgi) {
            print "\t$1\n";
        }
        $devNum++;
    }

=head1 DESCRIPTION

The package is used a object of the action response.

=head1 METHODS

=over 4

=item B<getstatuscode> - get the status code.

    $status_code = $service->getstatuscode();

Get the status code of the SOAP response.

=item B<getargumentlist> - get the argument list.

    \%argument_list = $service->getargumentlist();

Get the argument list of the SOAP response.

=back

=head1 AUTHOR

Satoshi Konno
skonno@cybergarage.org

CyberGarage
http://www.cybergarage.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Satoshi Konno

It may be used, redistributed, and/or modified under the terms of BSD License.

=cut
