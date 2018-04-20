use strict;
use Test::More;
use HTTP::Tinyish;
use File::Temp qw(tempdir);
use JSON::PP qw(decode_json);

unless ($ENV{LIVE_TEST} or -e ".git") {
    pass "skip network testing";
    done_testing;
    exit;
}

sub read_file {
    open my $fh, "<", shift;
    join "", <$fh>;
}

my @backends = $ENV{TEST_BACKEND}
  ? map "HTTP::Tinyish::$_", split(",", $ENV{TEST_BACKEND})
  : @HTTP::Tinyish::Backends;

for my $backend (@backends) {
    $HTTP::Tinyish::PreferredBackend = $backend;
    my $config = HTTP::Tinyish->configure_backend($backend);
    next unless $config && $backend->supports('http');

    diag "Testing with $backend";

    my $res = HTTP::Tinyish->new->get("http://www.cpan.org");
    is $res->{status}, 200;
    like $res->{content}, qr/Comprehensive/;

 SKIP: {
        skip "HTTPS is not supported with $backend", 2 unless $backend->supports('https');
        $res = HTTP::Tinyish->new(verify_SSL => 1)->get("https://github.com/");
        is $res->{status}, 200;
        like $res->{content}, qr/github/i;

        $res = HTTP::Tinyish->new(verify_SSL => 0)->get("https://cpan.metacpan.org/");
        is $res->{status}, 200;
        like $res->{content}, qr/Comprehensive/i;
    }

    $res = HTTP::Tinyish->new->get("http://example.invalid");
    is $res->{status}, 599;
    ok !$res->{success};

    $res = HTTP::Tinyish->new->head("http://httpbin.org/headers");
    is $res->{status}, 200;

    $res = HTTP::Tinyish->new->post("http://httpbin.org/post", {
        headers => { 'Content-Type' => 'application/x-www-form-urlencoded' },
        content => "foo=1&bar=2",
    });
    is $res->{status}, 200;
    is_deeply decode_json($res->{content})->{form}, { foo => "1", bar => "2" };

 SKIP: {
        skip "HTTP::Tiny's and LWP's chunked uploads are not supported by httpbin.", 1 if $backend =~ /HTTPTiny|LWP/;
        my @data = ("xyz\n", "xyz");
        $res = HTTP::Tinyish->new(timeout => 1)->post("http://httpbin.org/post", {
            headers => { 'Content-Type' => 'application/octet-stream' },
            content => sub { shift @data },
        });
        is $res->{status}, 200;
        is_deeply decode_json($res->{content})->{data}, "xyz\nxyz";
    }

 SKIP: {
        skip "wget before 1.15 doesn't support custom HTTP methods", 2
          if $backend =~ /Wget/ && !$config->{method_supported};
        $res = HTTP::Tinyish->new->put("http://httpbin.org/put", {
            headers => { 'Content-Type' => 'text/plain' },
            content => "foobarbaz",
        });
        is $res->{status}, 200;
        is_deeply decode_json($res->{content})->{data}, "foobarbaz";
    }

    $res = HTTP::Tinyish->new(default_headers => { "Foo" => "Bar", Dnt => "1" })
      ->get("http://httpbin.org/headers", { headers => { "Foo" => ["Bar", "Baz"] } });
 SKIP: {
        skip "httpbin does not support multiple headers", 1;
        is decode_json($res->{content})->{headers}{Foo}, "Bar,Baz";
    }
    is decode_json($res->{content})->{headers}{Dnt}, "1";

    my $fn = tempdir(CLEANUP => 1) . "/index.html";
    $res = HTTP::Tinyish->new->mirror("http://www.cpan.org", $fn);
    is $res->{status}, 200;
    like read_file($fn), qr/Comprehensive/;

 SKIP: {
        skip "Wget doesn't handle mirror", 1 if $backend =~ /Wget/;
        $res = HTTP::Tinyish->new->mirror("http://www.cpan.org", $fn);
        is $res->{status}, 304;
        ok $res->{success};
    }

    my $fn = tempdir(CLEANUP => 1) . "/index.html";
    $res = HTTP::Tinyish->new->mirror("http://example.invalid", $fn);
    is $res->{status}, 599;
    ok !$res->{success};

    $res = HTTP::Tinyish->new(agent => "Menlo/1")->get("http://httpbin.org/user-agent");
    is_deeply decode_json($res->{content}), { 'user-agent' => "Menlo/1" };

    $res = HTTP::Tinyish->new->get("http://httpbin.org/status/404");
    is $res->{status}, 404;
    is $res->{reason}, "NOT FOUND";

    $res = HTTP::Tinyish->new->get("http://httpbin.org/response-headers?Foo=Bar+Baz");
    is $res->{headers}{foo}, "Bar Baz";

    $res = HTTP::Tinyish->new->get("http://httpbin.org/basic-auth/user/passwd");
    is $res->{status}, 401;

    $res = HTTP::Tinyish->new->get("http://user:passwd\@httpbin.org/basic-auth/user/passwd");
    is $res->{status}, 200;
    is_deeply decode_json($res->{content}), { authenticated => JSON::PP::true(), user => "user" };

    $res = HTTP::Tinyish->new->get("http://httpbin.org/redirect/1");
    is $res->{status}, 200;

    $res = HTTP::Tinyish->new(max_redirect => 2)->get("http://httpbin.org/redirect/3");
    isnt $res->{status}, 200; # either 302 or 599

    $res = HTTP::Tinyish->new(timeout => 1)->get("http://httpbin.org/delay/2");
    is substr($res->{status}, 0, 1), '5';

    $res = HTTP::Tinyish->new->get("http://httpbin.org/encoding/utf8");
    like $res->{content}, qr/コンニチハ/;
}

done_testing;
