requires 'perl', '5.008005';

requires 'IPC::Run3';
requires 'HTTP::Tiny', 0.054;

on test => sub {
    requires 'Test::More', '0.96';
};

on develop => sub {
    requires 'LWP', 6;
    requires 'LWP::Protocol::https', 6;
};

