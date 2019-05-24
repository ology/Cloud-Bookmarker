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

=head1 ENDPOINTS

=head2 GET /

Main page.

=cut

get '/' => sub {
    my $account = query_parameters->get('a');
    my $format  = query_parameters->get('f');
    my $sort    = query_parameters->get('s');

    $sort ||= 'id';

    unless ( $account ) {
        my $code = 401;
        my $msg  = 'Not authorized';
        error "ERROR: $code - $msg";
        if ( $format ) {
            send_as html => $msg;
        }
        else {
            return { error => $msg, code => $code };
        }
    }

    my $file = 'public/accounts/' . $account . '.html';

    my $data = [];

    my ( $msg, $code );
    my $error = 0;
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
        $code = 400;
        $msg  = 'Unknown account';
        error "ERROR: $code - $_";
        $error++;
    };
    if ( $error ) {
        if ( $format ) {
            send_as html => $msg;
        }
        else {
            return { error => $msg, code => $code };
        }
    }

    if ( $format ) {
        my $html =<<'HTML';
<html>
<head>
  <title>Cloud::Bookmarker</title>
  <link rel="stylesheet" href="/css/style.css">
</head>
<body>
HTML

        for my $i ( sort { $a->{$sort} cmp $b->{$sort} } @$data ) {
            $html .= qq|<p><a href="/del?a=$account&i=$i->{id}&f=$format" class="button">x</a> $i->{title} : <a href="$i->{url}">$i->{url}</a></p>\n|;
        }

        $html .= "</body>\n</html>\n";

        send_as html => $html;
    }
    else {
        return $data;
    }
};

=head2 POST /add

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
        $msg  = 'No url provided';
        $code = 400;
    }
    if ( $msg && $code ) {
        error "ERROR: $code - $msg";
        return { error => $msg, code => $code };
    }

    $data->{title} ||= 'No title';

    my $file = 'public/accounts/' . $data->{account} . '.html';

    my $error = 0;
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
        $error++;
    };
    if ( $error ) {
        return { error => $msg, code => $code };
    }

    return { success => 1, code => $code };
};

=head2 GET /del

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

    my $file = 'public/accounts/' . $account . '.html';

    my ( $msg, $code );
    my $error = 0;
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
        $msg  = $_;
        $code = 500;
        error "ERROR: $code - $msg";
        $error++;
    };
    if ( $error ) {
        return { error => $msg, code => $code };
    }

    redirect "/?a=$account&f=$format";
};

true;

__END__

=head1 SEE ALSO

L<Dancer2>

L<Try::Tiny>

=cut
