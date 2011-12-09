package AnySan::Provider::Skype;
use strict;
use warnings;
use base 'AnySan::Provider';
our @EXPORT = qw(skype);
use AnySan;
use AnySan::Receive;
use Skype::Any;
use Skype::Any::User;

{
    no warnings 'redefine';
    sub AnySan::run { Skype::Any->run }
}

sub skype {
    my(%config) = @_;
    my $self = __PACKAGE__->new(
        client => undef,
        config => \%config,
    );

    my $client = Skype::Any->new(%config);
    $self->{client} = $client;

    my $nickname = $client->send_command('GET CURRENTUSERHANDLE');

    $client->message_received(sub {
        my $msg = shift;
        my $receive; $receive = AnySan::Receive->new(
            provider      => 'skype',
            event         => 'chatmessage',
            message       => $msg->body,
            nickname      => $nickname,
            from_nickname => $msg->from_handle,
            attribute     => {
                chatname  => $msg->chatname,
                dispname  => $msg->from_dispname,
                timestamp => $msg->timestamp,
                obj       => $msg,
            },
            cb            => sub { $self->event_callback($receive, @_) },
        );
        AnySan->broadcast_message($receive);
    });

    return $self;
}

sub event_callback {
    my($self, $receive, $type, @args) = @_;

    if ($type eq 'reply') {
        my $chat = $receive->attribute('obj')->chat;
        $chat->send_message($args[0]);
    }
}

sub send_message {
    my($self, $message, %args) = @_;

    my $user = Skype::Any::User->new($args{nickname});
    $user->send_message($message);
}

1;
__END__

=head1 NAME

AnySan::Provider::Skype - AnySan provides Skype API protocol

=head1 SYNOPSIS

    use AnySan;
    use AnySan::Provider::Skype;

    my $skype = skype
        name     => 'myapp',
        protocol => 8;

    $skype->send_message('message', nickname => 'echo123');

=head1 SEE ALSO

L<AnySan>, L<Skype::Any>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
