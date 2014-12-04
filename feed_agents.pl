#!/usr/bin/env perl
use strict;
use warnings;
use JSON;

my $matching_path = shift @ARGV || '/';

# Only special-case User-Agents such as Mozilla fakers
my @UA = (
    [qr/^Podcasts?\/\d/ => "Apple Podcasts"],
    [qr/^iTunes\/[\d\.]+ \(Macintosh/ => "iTunes (OS X)"],
    [qr/^iTunes\/[\d\.]+ \(Windows;/ => "iTunes (Windows)"],
    [qr/^iTunes\/[\d\.]+ Downcast\// => "Downcast"],
    [qr/^RSS_Radio\/\d+/ => "RSS Radio"],
    [qr/^livedoor FeedFetcher/ => "Livedoor Reader"],
    [qr/ theoldreader\.com;/ => "The Old Reader"],
    [qr/^Feedfetcher-Google; / => "Google Reader"],
    [qr/ BeyondPod\)$/ => "BeyondPod"],
    [qr/ DoggCatcher$/ => "DoggCatcher"],
    [qr/ Feedeen / => "Feedeen"],
    [qr/ inoreader\.com-like FeedFetcher/ => "Inoreader"],
    [qr/ podcast\.de\/\d/ => "Podcast.de"],
    [qr/ BazQux\/[\d\.]+;/ => "BazQux"],
);

# "My RSS Reader 1.2.3/blah blah blah" => "My RSS Reader"
sub normalize_agent {
    my $str = shift;

    for (@UA) {
        my($re, $result) = @$_;
        return $result if $str =~ $re;
    }

    $str =~ s/ *https?:\/\/.*$//;
    $str =~ s/ *\(.*$//;
    $str =~ s/\/.*$//;
    $str =~ s/ [\d\.]+$//;
    $str =~ s/ - .*$//;
    $str =~ s/ Feed ?Fetcher//gi;
    $str;
}

sub parse_ua {
    my $str = shift;

    return "Unknown" if $str eq "-" || $str =~ /^\d+$/;

    # Generic hosted feed crawler
    my($subs, $feed_id);
    if ($str =~ /\b(\d+) subscriber/) {
        $subs = $1;
    }

    if ($str =~ /feed[-_]?id=(\w+)/) {
        $feed_id = $1;
    }

    return normalize_agent($str), $subs, $feed_id;
}

my %hits;

while (<>) {
    my($ip, $path, $agent_string) = /^([0-9\.]+) .*?"[A-Z]+ ([^ ]+) .*"(.*?)" ".*?"$/;
    next unless $ip && $path =~ m/^$matching_path\b/;

    my($agent, $subs, $id) = parse_ua($agent_string);

    if ($subs) {
        $id ||= $path;
        $hits{$agent}{$id} = $subs
          if $subs > ($hits{$agent}{$id} || 0);
    } else {
        $hits{$agent}{_direct}{$ip} = 1;
    }
}

my $total = 0;
my %agents;

for my $agent (keys %hits) {
    my $agent_subs = 0;

    if (my $directs = delete $hits{$agent}{_direct}) {
        $agent_subs += keys %$directs;
    }

    for my $hosted_subs (values %{$hits{$agent}}) {
        $agent_subs += $hosted_subs;
    }

    $agents{$agent} = $agent_subs;
    $total += $agent_subs;
}

my @agents = map { +{ agent => $_, subscribers => $agents{$_} } }
                 sort { $agents{$b} <=> $agents{$a} } keys %agents;
print JSON::encode_json({ total => $total, agents => \@agents });
