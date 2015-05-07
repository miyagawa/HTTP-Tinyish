package HTTP::Tinyish::LWP;
use strict;
use LWP 5.802;
use LWP::UserAgent;

my %supports = (http => 1);

sub configure {
    my %meta = (
        LWP => $LWP::VERSION,
    );

    if (eval { require LWP::Protocol::https; 1 }) {
        $supports{https} = 1;
        $meta{"LWP::Protocol::https"} = $LWP::Protocol::https::VERSION;
    }

    \%meta;
}

sub supports {
    $supports{$_[1]};
}

sub new {
    my($class, %attr) = @_;

    bless {
        ua => LWP::UserAgent->new($class->lwp_params(%attr)),
    }, $class;
}

sub _headers_to_hashref {
    my($self, $hdrs) = @_;

    my %headers;
    for my $field ($hdrs->header_field_names) {
        $headers{lc $field} = $hdrs->header($field); # could be an array ref
    }

    \%headers;
}

sub get {
    my($self, $url, $opts) = @_;
    $opts ||= {};

    my $req = HTTP::Request->new(GET => $url);

    if ($opts->{headers}) {
        $req->header(%{$opts->{headers}});
    }

    my $res = $self->{ua}->request($req);

    return {
        url     => $url,
        content => $res->decoded_content(charset => 'none'),
        success => $res->is_success,
        status  => $res->code,
        reason  => $res->message,
        headers => $self->_headers_to_hashref($res->headers),
    };
}

sub mirror {
    my($self, $url, $file) = @_;
    my $res = $self->{ua}->mirror($url, $file);
    return {
        url     => $url,
        content => $res->decoded_content,
        success => $res->is_success,
        status  => $res->code,
        reason  => $res->message,
        headers => $self->_headers_to_hashref($res->headers),
    };
}

sub lwp_params {
    my($class, %attr) = @_;

    my %p = (
        parse_head => 0,
        env_proxy => 1,
        timeout      => delete $attr{timeout} || 60,
        max_redirect => delete $attr{max_redirect} || 5,
        agent        => delete $attr{agent} || "HTTP-Tinyish/$HTTP::Tinyish::VERSION",
    );

    # LWP default is to verify, HTTP::Tiny isn't
    unless ($attr{verify_SSL}) {
        $p{ssl_opts}{verify_hostname} = 0;
    }

    if ($attr{default_headers}) {
        $p{default_headers} = HTTP::Headers->new(%{$attr{default_headers}})
    }

    %p;
}

1;
