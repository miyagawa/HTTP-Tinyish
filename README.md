# NAME

HTTP::Tinyish - HTTP::Tiny compatible HTTP client wrappers

# SYNOPSIS

    my $http = HTTP::Tinyish->new(agent => "Mozilla/4.0");

    my $res = $http->get("http://www.cpan.org/");
    warn $res->{status};

    $http->post("http://example.com/post", {
        headers => { "Content-Type" => "application/x-www-form-urlencoded" },
        content => "foo=bar&baz=quux",
    });

    $http->mirror("http://www.cpan.org/modules/02packages.details.txt.gz", "./02packages.details.txt.gz");

# DESCRIPTION

HTTP::Tinyish is a wrapper module for HTTP client modules
[LWP](https://metacpan.org/pod/LWP), [HTTP::Tiny](https://metacpan.org/pod/HTTP::Tiny) and HTTP client software `curl` and `wget`.

It provides an API compatible to HTTP::Tiny, and the implementation
has been extracted out of [App::cpanminus](https://metacpan.org/pod/App::cpanminus). This module can be useful
in a restrictive environment where you need to be able to download
CPAN modules without an HTTPS support in built-in HTTP library.

# COMPATIBILITIES

All request related methods such as `get`, `post`, `put`,
`delete`, `request` and `mirror` are supported.

## LWP

- [LWP](https://metacpan.org/pod/LWP) backend requires [LWP](https://metacpan.org/pod/LWP) 5.802 or over to be functional, and [LWP::Protocol::https](https://metacpan.org/pod/LWP::Protocol::https) to send HTTPS requests.
- `mirror` method doesn't consider third options hash into account (i.e. you can't override the HTTP headers).
- proxy is automatically detected from environment variables.
- `timeout`, `max_redirect`, `agent`, `default_headers` and `verify_SSL` are translated.

## HTTP::Tiny

Because the actual HTTP::Tiny backend is used, all APIs are supported.

## Curl

- This module has been tested with curl 7.22 and later.
- HTTPS support is automatically detected by running `curl --version` and see its protocol output.
- `timeout`, `max_redirect`, `agent`, `default_headers` and `verify_SSL` are supported.

## Wget

- This module has been tested with Wget 1.12 and later.
- Wget prior to 1.15 doesn't support sending custom HTTP methods, so if you use `$http->put` for example, you'll get an internal error response (599).
- HTTPS support is automatically detected.
- `mirror()` method doesn't send `If-Modified-Since` header to the server, which will result in full-download every time because `wget` doesn't support `--timestamping`.
- `timeout`, `max_redirect`, `agent`, `default_headers` and `verify_SSL` are supported.

# SIMILAR MODULES

- [File::Fetch](https://metacpan.org/pod/File::Fetch) - is core since 5.10. Has support for non-HTTP protocols such as ftp and git. Does not support HTTPS or basic authentication as of this writing.
- [Plient](https://metacpan.org/pod/Plient) - provides more complete runtime API, but is only compatible on Unix environments.
- [HTTP::Tiny::CLI](https://metacpan.org/pod/HTTP::Tiny::CLI) - only provides curl interface so far, and does not provide `mirror` wrapper.

# AUTHOR

Tatsuhiko Miyagawa

# COPYRIGHT

Tatsuhiko Miyagawa, 2015-

# LICENSE

This module is licensed under the same terms as Perl itself.
