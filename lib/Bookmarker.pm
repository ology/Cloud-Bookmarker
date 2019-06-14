package Bookmarker;

# ABSTRACT: Manage bookmarks

use Dancer2 qw/ !any /;
use List::Util qw/ any /;
use Try::Tiny;

use constant PATH     => 'public/accounts/';
use constant EXT      => '.txt';
use constant ENCODING => ':encoding(UTF-8)';
use constant NOAUTH   => 'Not authorized';
use constant UNKNOWN  => 'Unknown account';

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

    send_error( NOAUTH, 401 ) unless $account;

    my $file = PATH . $account . EXT;

    send_error( UNKNOWN, 400 ) unless -e $file;

    my $data = [];

    try {
        open my $fh, '<' . ENCODING, $file or die "Can't read $file: $!";
        while ( my $line = readline($fh) ) {
            chomp $line;
            my ( $id, $title, $url, $tags ) = split /\s+:\s+/, $line;
            push @$data, { id => $id, title => $title, url => $url, tags => $tags };
        }
        close $fh or die "Can't close $file: $!";

        info request->remote_address, " read $file";
    }
    catch {
        error "ERROR: $_";
        send_error( UNKNOWN, 400 );
    };

    template index => {
        account => $account,
        data    => $data,
    };
};

=head2 POST /search

Search items.

=cut

post '/search' => sub {
    my $account = body_parameters->get('a');
    my $query   = body_parameters->get('q');

    send_error( NOAUTH, 401 ) unless $account;

    my $file = PATH . $account . EXT;

    send_error( UNKNOWN, 400 ) unless -e $file;

    my $data = [];

    my @query = split /\s+/, $query;

    try {
        open my $fh, '<' . ENCODING, $file or die "Can't read $file: $!";
        while ( my $line = readline($fh) ) {
            chomp $line;

            my ( $id, $title, $url, $tags ) = split /\s+:\s+/, $line;

            if ( @query ) {
                if ( any { $title =~ /$_/ || $url =~ /$_/ || $tags =~ /$_/ } @query ) {
                    push @$data, { id => $id, title => $title, url => $url, tags => $tags };
                }
            }
        }
        close $fh or die "Can't close $file: $!";

        info request->remote_address, " searched $file for '$query'";
    }
    catch {
        error "ERROR: $_";
        send_error( UNKNOWN, 400 );
    };

    template index => {
        account => $account,
        data    => $data,
    };
};

=head2 POST /update_title

Update an item.

=cut

post '/update' => sub {
    my $account = body_parameters->get('a');
    my $new     = body_parameters->get('n');
    my $item    = body_parameters->get('i');
    my $update  = body_parameters->get('u');

    send_error( NOAUTH, 401 ) unless $account;

    my $file = PATH . $account . EXT;

    send_error( UNKNOWN, 400 ) unless -e $file;

    send_error( 'No item id provided', 400 ) unless $item;

    $new ||= $update eq 'title' ? 'Untitled' : '';

    try {
        my @lines = _read_file($file);

        open my $fh, '>' . ENCODING, $file or die "Can't write to $file: $!";
        for my $line ( @lines ) {
            my ( $id, $title, $url, $tags ) = split /\s+:\s+/, $line;
            if ( $update eq 'title' ) {
                $title = $new if $id eq $item;
            }
            elsif ( $update eq 'tags' ) {
                $tags = $new if $id eq $item;
            }
            print $fh "$id : $title : $url : $tags\n";
        }
        close $fh or die "Can't close $file: $!";

        info request->remote_address, " updated $item";
    }
    catch {
        error "ERROR: $_";
        send_error( "Can't update item", 500 );
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

    send_as JSON => { error => NOAUTH, code => 401 } unless $data->{account};

    my $file = PATH . $data->{account} . EXT;

    send_as JSON => { error => UNKNOWN, code => 400 } unless -e $file;

    send_as JSON => { error => 'No url provided', code => 400 } unless $data->{url};

    $data->{title} ||= 'Untitled';
    $data->{tags}  ||= '';

    try {
        open my $fh, '>>' . ENCODING, $file or die "Can't write to $file: $!";
        print $fh time, " : $data->{title} : $data->{url} : $data->{tags}\n";
        close $fh or die "Can't close $file: $!";

        info request->remote_address, " wrote to $file";
    }
    catch {
        error "ERROR: $_";
        send_as JSON => { error => "Can't add item", code => 500 };
    };

    send_as JSON => { success => 1, code => 201 };
};

=head2 GET /delete

Delete an item.

=cut

get '/delete' => sub {
    my $account = query_parameters->get('a');
    my $item    = query_parameters->get('i');

    send_error( NOAUTH, 401 ) unless $account;

    my $file = PATH . $account . EXT;

    send_error( UNKNOWN, 400 ) unless -e $file;

    send_error( 'No item id provided', 400 ) unless $item;

    try {
        my @lines = _read_file($file);

        open my $fh, '>' . ENCODING, $file or die "Can't write to $file: $!";
        for my $line ( @lines ) {
            my ( $id, $title, $url, $tags ) = split /\s+:\s+/, $line;
            next if $id eq $item;
            print $fh "$id : $title : $url : $tags\n";
        }
        close $fh or die "Can't close $file: $!";

        info request->remote_address, " deleted $item";
    }
    catch {
        error "ERROR: $_";
        send_error( "Can't delete item", 500 );
    };

    redirect "/?a=$account";
};

sub _read_file {
    my ($file) = @_;

    open my $fh, '<' . ENCODING, $file or die "Can't read $file: $!";

    my @lines;
    while ( my $line = readline($fh) ) {
        chomp $line;
        push @lines, $line;
    }

    close $fh or die "Can't close $file: $!";

    return @lines;
}

true;

__END__

=head1 SEE ALSO

L<Dancer2>

L<Try::Tiny>

=cut
