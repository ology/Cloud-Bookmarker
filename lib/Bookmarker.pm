package Bookmarker;

# ABSTRACT: Manage bookmarks

use Dancer2;
use Try::Tiny;

our $VERSION = '0.01';

set engines => {
    serializer => {
        JSON => {
           allow_nonref => 1
        },
    }
};
set serializer   => 'JSON';
set content_type => 'application/json';

=head1 NAME

Bookmarker - Manage bookmarks

=head1 DESCRIPTION

A C<Bookmarker> instance manages bookmarks.

=head1 ROUTES

=head2 /

Main page.

=cut

get '/' => sub {
    my $account = query_parameters->get('a');
    my $format  = query_parameters->get('f');

    unless ( $account ) {
        my $code = 401;
        my $msg  = 'Not authorized';
        error "ERROR: $code - $msg";
        return { error => $msg, code => 401 };
    }

    my $file = 'public/accounts/' . $account . '.txt';

    my $data = [];

    try {
        open my $fh, '<', $file or die "Can't read $file: $!";
        while ( my $line = readline($fh) ) {
            chomp $line;
            my ( $id, $title, $url ) = split /\s+:\s+/, $line;
            push @$data, { id => $id, title => $title, url => $url };
        }
        close $fh or die "Can't close $file: $!";
        info "Read $file";
    }
    catch {
        my $code = 500;
        error "ERROR: $code - $_";
        return { error => $_, code => 500 };
    };

    if ( $format ) {
        my $text =<<'HTML';
<html>
<head>
<style>
a.button {
    -webkit-appearance: button;
    -moz-appearance: button;
    appearance: button;
    text-decoration: none;
    color: initial;
};
</style>
</head>
<body>
HTML

        for my $i ( sort @$data ) {
            $text .= qq|<p><a href="/del?a=$account&i=$i->{id}&f=$format" class="button">x</a> $i->{title} : <a href="$i->{url}">$i->{url}</a></p>\n|;
        }

        $text .= "</body>\n</html>\n";

        send_as html => $text;
    }
    else {
        return $data;
    }
};

=head2 /add

Add an item.

=cut

post '/add' => sub {
    my $data = params;

    my ( $msg, $code ) = ( '', 201 );
    if ( !$data->{account} ) {
        $msg  = 'Not authorized';
        $code = 401;
    }
    elsif ( !$data->{url} ) {
        $msg = 'No url provided';
        $code = 400;
    }
    if ( $msg && $code ) {
        error "ERROR: $code - $msg";
        return { error => $msg, code => $code };
    }

    my $file = 'public/accounts/' . $data->{account} . '.txt';

    try {
        open my $fh, '>>', $file or die "Can't write to $file: $!";
        print $fh time, " : $data->{title} : $data->{url}\n";
        close $fh or die "Can't close $file: $!";
        info "Wrote to $file";
    }
    catch {
        $msg  = $_;
        $code = 500;
        error "ERROR: $code - $msg";
        return { error => $msg, code => $code };
    };

    return { success => 1, code => $code };
};

=head2 /del

Delete an item.

=cut

get '/del' => sub {
    my $account = query_parameters->get('a');
    my $format  = query_parameters->get('f');
    my $item    = query_parameters->get('i');

    unless ( $account ) {
        my $code = 401;
        my $msg  = 'Not authorized';
        error "ERROR: $code - $msg";
        return { error => $msg, code => $code };
    }

    my $file = 'public/accounts/' . $account . '.txt';

    try {
        open my $fh, '<', $file or die "Can't read $file: $!";
        my @lines;
        while ( my $line = readline($fh) ) {
            chomp $line;
            push @lines, $line;
        }
        close $fh or die "Can't close $file: $!";
        open $fh, '>', $file or die "Can't write to $file: $!";
        for my $line ( @lines ) {
            my ( $id, $title, $url ) = split /\s+:\s+/, $line;
            next if $id eq $item;
            print $fh "$id : $title : $url\n";
        }
        close $fh or die "Can't close $file: $!";
        info "$item deleted";
    }
    catch {
        my $msg  = $_;
        my $code = 500;
        error "ERROR: $code - $msg";
        return { error => $msg, code => $code };
    };

    redirect "/?a=$account&f=$format";
};

true;

__END__

=head1 SEE ALSO

L<Dancer2>

L<Try::Tiny>

=cut
