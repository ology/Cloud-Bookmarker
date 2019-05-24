package Bookmarker;

# ABSTRACT: Manage bookmarks

use Dancer2;
use Try::Tiny;

our $VERSION = '0.01';

=head1 NAME

Bookmarker - Manage bookmarks

=head1 DESCRIPTION

A C<Bookmarker> instance manages bookmarks.

=head1 ENDPOINTS

=head2 GET /

List items.

=cut

get '/' => sub {
    my $account = query_parameters->get('a');

    send_error( 'Not authorized', 401 ) unless $account;

    my $file = 'public/accounts/' . $account . '.html';

    my $data = [];

    try {
        open my $fh, '< :encoding(UTF-8)', $file or die "Can't read $file: $!";
        while ( my $line = readline($fh) ) {
            chomp $line;
            my ( $id, $title, $url ) = split /\s+:\s+/, $line;
            push @$data, { id => $id, title => $title, url => $url };
        }
        close $fh or die "Can't close $file: $!";
        info "Read $file";
    }
    catch {
        error "ERROR: $_";
        send_error( 'Unknown account', 400 );
    };

    template index => {
        account => $account,
        data    => $data,
    };
};

=head2 POST /update

Update an item.

=cut

post '/update' => sub {
    my $account   = body_parameters->get('a');
    my $new_title = body_parameters->get('t');
    my $item      = body_parameters->get('i');

    send_error( 'Not authorized', 401 ) unless $account;

    my $file = 'public/accounts/' . $account . '.html';

    try {
        open my $fh, '< :encoding(UTF-8)', $file or die "Can't read $file: $!";
        my @lines;
        while ( my $line = readline($fh) ) {
            chomp $line;
            push @lines, $line;
        }
        close $fh or die "Can't close $file: $!";
        open $fh, '> :encoding(UTF-8)', $file or die "Can't write to $file: $!";
        for my $line ( @lines ) {
            my ( $id, $title, $url ) = split /\s+:\s+/, $line;
            $title = $new_title if $id eq $item;
            print $fh "$id : $title : $url\n";
        }
        close $fh or die "Can't close $file: $!";
        info "$item retitled";
    }
    catch {
        error "ERROR: $_";
        send_error( "Can't update title", 500 );
    };

    redirect "/?a=$account";
};

=head2 POST /add

Add an item.

=cut

post '/add' => sub {
    my $data = request->body;

    try {
        $data = decode_json $data;
    }
    catch {
        send_as JSON => { error => "Can't decode JSON", code => 400 };
    };

    send_as JSON => { error => 'Not authorized', code => 401 } unless $data->{account};

    send_as JSON => { error => 'No url provided', code => 400 } unless $data->{url};

    my $file = 'public/accounts/' . $data->{account} . '.html';

    send_as JSON => { error => 'No such account', code => 401 } unless -e $file;

    $data->{title} ||= 'No title';

    my ( $msg, $code );
    my $error = 0;
    try {
        open my $fh, '>> :encoding(UTF-8)', $file or die "Can't write to $file: $!";
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
        send_as JSON => { error => $msg, code => $code };
    }

    send_as JSON => { success => 1, code => 201 };
};

=head2 GET /del

Delete an item.

=cut

get '/del' => sub {
    my $account = query_parameters->get('a');
    my $item    = query_parameters->get('i');

    send_error( 'Not authorized', 401 ) unless $account;

    my $file = 'public/accounts/' . $account . '.html';

    try {
        open my $fh, '< :encoding(UTF-8)', $file or die "Can't read $file: $!";
        my @lines;
        while ( my $line = readline($fh) ) {
            chomp $line;
            push @lines, $line;
        }
        close $fh or die "Can't close $file: $!";
        open $fh, '> :encoding(UTF-8)', $file or die "Can't write to $file: $!";
        for my $line ( @lines ) {
            my ( $id, $title, $url ) = split /\s+:\s+/, $line;
            next if $id eq $item;
            print $fh "$id : $title : $url\n";
        }
        close $fh or die "Can't close $file: $!";
        info "$item deleted";
    }
    catch {
        error "ERROR: $_";
        send_error( "Can't delete $item", 500 );
    };

    redirect "/?a=$account";
};

true;

__END__

=head1 SEE ALSO

L<Dancer2>

L<Try::Tiny>

=cut
