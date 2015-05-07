package HTTP::Tinyish::Curl;
use strict;
use warnings;
use IPC::Run3 qw(run3);
use File::Which qw(which);
use HTTP::Tinyish::Util qw(parse_http_response internal_error);

my %supports;
my $curl;

sub configure {
    my $class = shift;

    my %meta;
    $curl = which('curl');

    eval {
        run3([$curl, '--version'], \undef, \my $version, \undef);
        if ($version =~ /^Protocols: (.*)/m) {
            my %protocols = map { $_ => 1 } split /\s/, $1;
            $supports{http}  = 1 if $protocols{http};
            $supports{https} = 1 if $protocols{https};
        }

        $meta{$curl} = $version;
    };

    \%meta;
}

sub supports { $supports{$_[1]} }

sub new {
    my($class, %attr) = @_;
    bless \%attr, $class;
}

sub get {
    my($self, $url, $opts) = @_;
    $opts ||= {};

    my($output, $error);
    eval {
        run3 [$curl, $self->build_options($url, $opts), $url], \undef, \$output, \$error;
    };

    if ($@ or $?) {
        return internal_error($url, $@ || $error);
    }

    my $res = { url => $url };
    parse_http_response($output, $res);
    $res;
}

sub mirror {
    my($self, $url, $file, $opts) = @_;
    $opts ||= {};

    my $output;
    eval {
        run3 [$curl, $self->build_options($url, $opts), $url, '-z', $file, '-o', $file, '--remote-time'], \undef, \$output, \undef;
    };

    if ($@) {
        return internal_error($url, $@);
    }

    my $res = { url => $url };
    parse_http_response($output, $res);
    $res;
}

sub build_options {
    my($self, $url, $opts) = @_;

    my @options = (
        '--location',
        '--silent',
        '--dump-header', '-',
    );

    if ($self->{agent}) {
        push @options, '--user-agent', $self->{agent};
    }

    my %headers;
    if ($self->{default_headers}) {
        %headers = %{$self->{default_headers}};
    }
    if ($opts->{headers}) {
        %headers = (%headers, %{$opts->{headers}});
    }
    $self->_translate_headers(\%headers, \@options);

    @options;
}

sub _translate_headers {
    my($self, $headers, $options) = @_;

    for my $field (keys %$headers) {
        my $value = $headers->{$field};
        if (ref $value eq 'ARRAY') {
            push @$options, map { ('-H', "$field:$_") } @$value;
        } else {
            push @$options, '-H', "$field:$value";
        }
    }
}

1;
