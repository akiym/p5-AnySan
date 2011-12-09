use strict;
use warnings;
use AnySan;
use AnySan::Provider::Skype;
use LWP::UserAgent;
use URI::Find;

my $ua = LWP::UserAgent->new;
my $finder = URI::Find->new(sub {
    my $url = shift;

    my $res = $ua->get($url);
    return $res->code unless $res->is_success;

    my ($title) = $res->decoded_content =~ m!<title>(.*)</title>!i;
    return $title;
});

my $skype = skype;

AnySan->register_listener(
    url => {
        event => 'chatmessage',
        cb => sub {
            my $receive = shift;
            my $message = $receive->message;
            if ($finder->find(\$message)) {
                $receive->send_reply($message);
            }
        },
    },
);

AnySan->run;
