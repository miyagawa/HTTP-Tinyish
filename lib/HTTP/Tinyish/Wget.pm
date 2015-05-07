package HTTP::Tinyish::Wget;
use strict;
use warnings;
use IPC::Run3 qw(run3);
use File::Which qw(which);
use HTTP::Tinyish::Util qw(parse_http_response internal_error);

my %supports;
my $wget;

sub configure {
    my $class = shift;
    my %meta;

    $wget = which('wget');

    eval {
        local $ENV{LC_ALL} = 'en_US';

        my $config = $class->new(agent => __PACKAGE__);
        my @options = grep { $_ ne '--quiet' } $config->build_options;

        run3([$wget, @options, 'https://'], \undef, \my $out, \my $err);

        # TODO requires 1.12 for server-response with quiet support?
        if ($err && $err =~ /HTTPS support not compiled/) {
            $supports{http} = 1;
        } elsif ($err && $err =~ /Invalid host/) {
            $supports{http} = $supports{https} = 1;
        }

        run3([$wget, '--version'], \undef, \my $version, \undef);
        $meta{$wget} = "$version";
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

    my($stdout, $stderr);
    eval {
        run3 [$wget, $self->build_options($url, $opts), $url, '-O', '-'], \undef, \$stdout, \$stderr;
    };

    if ($? && $? <= 128) {
        return internal_error($url, $@ || $stderr);
    }

    $stderr =~ s/^  //gm;
    $stderr =~ s/.+^(HTTP\/\d\.\d)/$1/ms; # multiple replies for authenticated requests :/

    my $res = { url => $url };
    parse_http_response(join("\n", $stderr, $stdout), $res);
    $res;
}

sub mirror {
    my($self, $url, $file, $opts) = @_;
    $opts ||= {};

    # This doesn't send If-Modified-Since because -O and -N are mutually exclusive :(
    my($stdout, $stderr);
    eval {
        run3 [$wget, $self->build_options($url, $opts), $url, '-O', $file], \undef, \$stdout, \$stderr;
    };

    if ($@ or $?) {
        return internal_error($url, $@ || $stderr);
    }

    $stderr =~ s/^  //gm;
    $stderr =~ s/.*^(HTTP\/\d\.\d)/$1/ms; # multiple replies for authenticated requests :/

    my $res = { url => $url };
    parse_http_response(join("\n", $stderr, $stdout), $res);
    $res;
}

sub build_options {
    my($self, $url, $opts) = @_;

    my @options = (
        '--retry-connrefused',
        '--quiet',
        '--server-response',
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
            # wget doesn't honor multiple header fields
            push @$options, '--header', "$field:" . join(",", @$value);
        } else {
            push @$options, '--header', "$field:$value";
        }
    }
}



1;
