#!/dv/tools/bin/perl
#########################################################
#       PERL example for communicating with vApi        #
#       Perl version: v5.12.2                           #
#       Vmanager version: 14.20.001                     #
#       Written by Nadav Eden                           #
#########################################################
use REST::Client;
use JSON::XS;
use LWP::UserAgent;
use Data::Dumper;
use Getopt::Long;

my $server;
my $debug = 0;
my $port;
my $url;
my $json_file;
my $summary;
my $desc;
my $op = "issue";
GetOptions ("server|s=s"        => \$server,
                        "port|p=i"              => \$port,
                        "desc|d=s"      => \$desc,
                        "summary=s"     => \$summary,
                        "op=s"          => \$op,
                        "id=s"          => \$id,
                        "json|j=s"              => \$json_file) or die "$0 - Incorrect usage\n";

$url = "http://$server:$port/rest/api/2/$op/";
#########################################################
# sub: get_json                                         #
# Creates a JSON from a given file or use a default     #
# '{}' JSON                                             #
#########################################################
sub get_json {
        my $json = "{}";
        my ($json_file) = @_;
        if ($json_file) {
                if (-e $json_file and -s $json_file) {
                        print "$json_file exists and non-empty\n" if ($debug);
                        local $/=undef;
                        open FH, "<", $json_file;
                        $json = <FH>;
                        $json =~ s/SUMMARY/$summary/;
                        $json =~ s/DESC/$desc/;
                        close FH;
                } else {
                          die ("$json_file is given but either empty or not exists\n");
                }
        }
        if ($id) {
                $json =~ s/JIRA_ID/$id/;
        };
        return $json;
}
#########################################################
#       sub: create_post_request                        #
#       Creates a n HTTP request from a JSON and a URL  #
#########################################################
sub create_post_request {
        my ($json, $url) = @_;
        my $req = HTTP::Request->new(POST => $url);
        $req->header("Content-Type" => "application/json");
        my $username    = $ENV{'USER'};
        my $password    = "letmein";
        $req->authorization_basic($username, $password);
        $req->content($json);
        return $req;
}
#########################################################
#       sub: create_put_request                         #
#       Creates a n HTTP request from a JSON and a URL  #
#########################################################
sub create_put_request {
        my ($json, $url, $ssl) = @_;
        my $req = HTTP::Request->new(PUT => $url);
        $req->header("Content-Type" => "application/json");
        $req->content($json);
        return $req;
}
sub create_get_request {
        my ($json, $url, $ssl) = @_;
        my $req = HTTP::Request->new(GET => $url);
        $req->header("Content-Type" => "application/json");
        $req->content($json);
        return $req;
}
#########################################################
#       sub: send_to_server                             #
#       Send the given request to server and decode the #
#       response                                        #
#########################################################
sub send_to_server {
        my ($req) = @_;
        my $ua  = LWP::UserAgent->new();
        my $res = $ua->request($req);
        my $json_data;

        if ($res->is_success) {
                $json_data = decode_json($res->content);
                print Dumper($json_data) if ($debug);
        } else {
                print Dumper(\$res) . "\n";
                exit 1;
        }
        return $json_data;
}
$json = get_json($json_file, $id);
print Dumper(\$json) if ($debug);
$req = create_post_request($json, $url);
print "-I- URL: $url\n" if ($debug);
my $res = send_to_server($req);
print "-I- Response\n" if ($debug);
print Dumper(\$res) if ($debug);
if ($op =~ m/search/) {
        print $res->{'issues'}[0]->{'fields'}->{'status'}->{'name'};
} else {
        print $res->{'key'};
}
exit 0;
