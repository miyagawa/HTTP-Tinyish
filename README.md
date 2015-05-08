# NAME

HTTP::Tinyish - HTTP::Tiny compatible HTTP client wrappers

# SYNOPSIS

    my $res = HTTP::Tinyish->new->get("http://www.cpan.org/");

# DESCRIPTION

HTTP::Tinyish is a wrapper module for HTTP client modules
[LWP](https://metacpan.org/pod/LWP), [HTTP::Tiny](https://metacpan.org/pod/HTTP::Tiny) and HTTP client software `curl` and `wget`.

It provides an API compatible to HTTP::Tiny, and the implementation
has been extracted out of [App::cpanminus](https://metacpan.org/pod/App::cpanminus). This module can be useful
in a restrictive environment where you need to be able to download
CPAN modules without an HTTPS support in built-in HTTP library.

# SUPPORTED METHODS

All request related methods such as `get`, `post`, `put`,
`delete`, `request` and `mirror` are supported.

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
