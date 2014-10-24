package UPnP::Service;

#-----------------------------------------------------------------
# Net::UPnP::Service
#-----------------------------------------------------------------

use strict;

use UPnP;
use UPnP::ActionResponse;

use vars qw($_DEVICE $_DEVICE_DESCRIPTION $SERVICETYPE $SERVICEID $SCPDURL $CONTROLURL $EVENTSUBURL);

$_DEVICE = 'device';
$_DEVICE_DESCRIPTION = 'device_description';

$SERVICETYPE = 'serviceType';
$SERVICEID = 'serviceId';
$SCPDURL = 'SCPDURL';
$CONTROLURL = 'controlURL';
$EVENTSUBURL = 'eventSubURL';

#------------------------------
# new
#------------------------------

sub new {
	my($class) = shift;
	my($this) = {
		$UPnP::Service::_DEVICE  => undef,
		$UPnP::Service::_DEVICE_DESCRIPTION => '',
	};
	bless $this, $class;
}

#------------------------------
# device
#------------------------------

sub setdevice() {
	my($this) = shift;
	if (@_) {
		$this->{$UPnP::Service::_DEVICE} = $_[0];
	}
			
}

sub getdevice() {
	my($this) = shift;
	$this->{$UPnP::Service::_DEVICE};
}

#------------------------------
# device description
#------------------------------

sub setdevicedescription() {
	my($this) = shift;
	$this->{$UPnP::Service::_DEVICE_DESCRIPTION} = $_[0];
 }

sub getdevicedescription() {
	my($this) = shift;
	$this->{$UPnP::Service::_DEVICE_DESCRIPTION};
 }

#------------------------------
# getservicetype
#------------------------------

sub getservicetype() {
	my($this) = shift;
	unless ($this->{$UPnP::Service::_DEVICE_DESCRIPTION} =~ m/<$UPnP::Service::SERVICETYPE>(.*)<\/$UPnP::Service::SERVICETYPE>/i) {
		return undef;
	}
 	return $1;
 }

#------------------------------
# getserviceid
#------------------------------

sub getserviceid() {
	my($this) = shift;
	unless ($this->{$UPnP::Service::_DEVICE_DESCRIPTION} =~ m/<$UPnP::Service::SERVICEID>(.*)<\/$UPnP::Service::SERVICEID>/i) {
		return undef;
	}
 	return $1;
 }

#------------------------------
# getscpdurl
#------------------------------

sub getscpdurl() {
	my($this) = shift;
	unless ($this->{$UPnP::Service::_DEVICE_DESCRIPTION} =~ m/<$UPnP::Service::SCPDURL>(.*)<\/$UPnP::Service::SCPDURL>/i) {
		return undef;
	}
 	return $1;
 }

#------------------------------
# getcontrolurl
#------------------------------

sub getcontrolurl() {
	my($this) = shift;
	unless ($this->{$UPnP::Service::_DEVICE_DESCRIPTION} =~ m/<$UPnP::Service::CONTROLURL>(.*)<\/$UPnP::Service::CONTROLURL>/i) {
		return undef;
	}
 	return $1;
 }

#------------------------------
# geteventsubrul
#------------------------------

sub geteventsubrul() {
	my($this) = shift;
	unless ($this->{$UPnP::Service::_DEVICE_DESCRIPTION} =~ m/<$UPnP::Service::EVENTSUBURL>(.*)<\/$UPnP::Service::EVENTSUBURL>/i) {
		return undef;
	}
 	return $1;
 }

#------------------------------
# geteventsubrul
#------------------------------

sub postcontrol() {
	my($this) = shift;
	my ($action_name, $action_arg) = @_;
	my (
		$dev,
		$location_url,
		$url_base,
		$ctrl_url,
		$service_type,
		$soap_action,
		$soap_content,
		$arg_name,
		$arg_value,
		$post_addr,
		$post_port,
		$post_path,
		$http_req,
		$post_res,
		$action_res,
		$key,
	);
	
	$action_res = UPnP::ActionResponse->new();
	
	$dev = $this->getdevice();
	
	$location_url = $dev->getlocation();
	$url_base = $dev->geturlbase();
	$ctrl_url = $this->getcontrolurl();

	#print "$location_url\n";
	#print "$url_base\n";
	#print "$ctrl_url\n";
		
	unless ($ctrl_url =~ m/http:\/\/(.*)/i) {
		if (0 < length($url_base)) {
			$ctrl_url = $url_base . $ctrl_url;
		}
		else {
			if ($location_url =~ m/http:\/\/([0-9a-z.]+)[:]*([0-9]*)\/(.*)/i) {
				if (0 < length($3)) {
					$ctrl_url = "http:\/\/$1:$2$ctrl_url";
				} else {
					$ctrl_url = "http:\/\/$1:$2$\/$ctrl_url";
				}
			} else {
				$ctrl_url = $location_url .  $ctrl_url;
			}
		}
	}

	#print "$ctrl_url\n";
	
	unless ($ctrl_url =~ m/http:\/\/([0-9a-z.]+)[:]*([0-9]*)\/(.*)/i) {
		#print "Invalid URL : $ctrl_url\n";
		$post_res = UPnP::HTTPResponse->new();
		$action_res->sethttpresponse($post_res);
		return $action_res;
	}
	$post_addr = $1;
	$post_port = $2;
	$post_path = '/' . $3;
	#$post_path = $this->getcontrolurl();
	
	$service_type = $this->getservicetype();
	$soap_action = "\"" . $service_type . "#" . $action_name . "\"";


$soap_content = <<"SOAP_CONTENT";
<?xml version=\"1.0\" encoding=\"utf-8\"?>
<s:Envelope xmlns:s=\"http:\/\/schemas.xmlsoap.org\/soap\/envelope\/\" s:encodingStyle=\"http:\/\/schemas.xmlsoap.org\/soap\/encoding/\">
\t<s:Body>
\t\t<u:$action_name xmlns:u=\"$service_type\">
SOAP_CONTENT

	if (ref $action_arg) {
		while (($arg_name, $arg_value) = each (%{$action_arg} ) ) {
			if (length($arg_value) <= 0) {
				$soap_content .= "\t\t\t<$arg_name \/>\n";
				next;
			}
			$soap_content .= "\t\t\t<$arg_name>$arg_value<\/$arg_name>\n";
		}
	}

$soap_content .= <<"SOAP_CONTENT";
\t\t</u:$action_name>
\t</s:Body>
</s:Envelope>
SOAP_CONTENT

	$http_req = UPnP::HTTP->new();
	$post_res = $http_req->postsoap($post_addr, $post_port, $post_path, $soap_action, $soap_content);

	$action_res->sethttpresponse($post_res);
	
	return $action_res;
}

1;

__END__

=head1 NAME

UPnP::Service - Perl extension for UPnP.

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

The package is used a object of UPnP service.

=head1 METHODS

=over 4

=item B<getdevice> - get the device.

    $description = $service->getdevice();

Get the parent device of the service.

=item B<getservicetype> - get the service type.

    $service_type = $service->getservicetype();

Get the service type.

=item B<getserviceid> - get the service id.

    $service_id = $service->getserviceid();

Get the service id.

=item B<postcontrol> - post a control action.

    $action_res = $service->postcontrol($action_name, \%action_arg);

Post a control action to the device, and return L<UPnP::ActionResponse>.

=back

=head1 SEE ALSO

L<UPnP::ActionResponse>

=head1 AUTHOR

Satoshi Konno
skonno@cybergarage.org

CyberGarage
http://www.cybergarage.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Satoshi Konno

It may be used, redistributed, and/or modified under the terms of BSD License.

=cut
