package HTTP::Tinyish::Curl;
use strict;
use warnings;
use IPC::Run3 qw(run3);
use File::Which qw(which);
use File::Temp ();
use HTTP::Tinyish::Util qw(parse_http_response internal_error);

my %supports;
my $curl;

sub _slurp {
    open my $fh, "<", shift or die $!;
    local $/;
    <$fh>;
}

sub configure {
    my $class = shift;

    my %meta;
    $curl = which('curl');

    eval {
        run3([$curl, '--version'], \undef, \my $version, \my $error);
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

    my(undef, $temp) = File::Temp::tempfile;

    my($output, $error);
    eval {
        run3 [
            $curl,
            $self->build_options($url, $opts),
            '--dump-header', $temp,
            $url,
        ], \undef, \$output, \$error;
    };

    if ($@ or $?) {
        return internal_error($url, $@ || $error);
    }

    my $res = { url => $url, content => $output };
    parse_http_response( _slurp($temp), $res );
    $res;
}

sub mirror {
    my($self, $url, $file, $opts) = @_;
    $opts ||= {};

    my(undef, $temp) = File::Temp::tempfile;

    my $output;
    eval {
        run3 [
            $curl,
            $self->build_options($url, $opts),
            '-z', $file,
            '-o', $file,
            '--dump-header', $temp,
            '--remote-time',
            $url,
        ], \undef, \$output, \undef;
    };

    if ($@) {
        return internal_error($url, $@);
    }

    my $res = { url => $url, content => $output };
    parse_http_response( _slurp($temp), $res );
    $res;
}

sub build_options {
    my($self, $url, $opts) = @_;

    my @options = (
        '--location',
        '--silent',
        '--max-time', ($self->{timeout} || 60),
        '--max-redirs', ($self->{max_redirect} || 5),
        '--user-agent', ($self->{agent} || "HTTP-Tinyish/$HTTP::Tinyish::VERSION"),
    );

    my %headers;
    if ($self->{default_headers}) {
        %headers = %{$self->{default_headers}};
    }
    if ($opts->{headers}) {
        %headers = (%headers, %{$opts->{headers}});
    }
    $self->_translate_headers(\%headers, \@options);

    unless ($self->{verify_SSL}) {
        push @options, '--insecure';
    }

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
