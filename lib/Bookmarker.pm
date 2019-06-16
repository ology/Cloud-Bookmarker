package Bookmarker;

# ABSTRACT: Manage bookmarks

use Dancer2 qw/ !any /;
use Dancer2::Plugin::Database;
use HTTP::Simple qw/ getprint is_success /;
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

    my $sql = 'SELECT * FROM bookmarks WHERE account = ?';
    my $sth = database->prepare($sql);
    $sth->execute($account);
    my $res = $sth->fetchall_hashref('id');

    info request->remote_address, " read $account";

    template index => {
        account => $account,
        data    => [ sort { $a->{id} <=> $b->{id} } values %$res ],
        check   => '',
        search  => '',
    };
};

=head2 POST /search

Search items.

=cut

post '/search' => sub {
    my $account = body_parameters->get('a') || query_parameters->get('a');
    my $query   = body_parameters->get('q') || query_parameters->get('q');

    my $file = _auth($account);

    my $data = [];

    my @query = split /\s+/, $query;

    my $sql = 'SELECT * FROM bookmarks WHERE account = ?';
    my $sth = database->prepare($sql);
    $sth->execute($account);
    my $res = $sth->fetchall_hashref('id');

    for my $r ( sort { $a->{id} <=> $b->{id} } values %$res ) {
        if ( @query && any { $r->{title} =~ /\Q$_\E/i || $r->{url} =~ /\Q$_\E/i || $r->{tags} =~ /\Q$_\E/i } @query ) {
            push @$data, { id => $r->{id}, title => $r->{title}, url => $r->{url}, tags => $r->{tags} };
        }
    }

    info request->remote_address, " searched $account for '$query'";

    template index => {
        account => $account,
        data    => $data,
        check   => '',
        search  => $query,
    };
};

=head2 POST /update

Update an item.

=cut

post '/update' => sub {
    my $account = body_parameters->get('a');
    my $new     = body_parameters->get('n');
    my $item    = body_parameters->get('i');
    my $update  = body_parameters->get('u');

    my $file = _auth($account);

    send_error( 'No item id provided', 400 ) unless $item;

    $new ||= $update eq 'title' ? 'Untitled' : '';

    my $sql = "UPDATE bookmarks SET $update = ? WHERE account = ? AND id = ?";
    my $sth = database->prepare($sql);
    $sth->execute( $new, $account, $item );

    info request->remote_address, " updated $account $item";

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

    my $id = time();

    my $sql = 'INSERT INTO bookmarks (id, account, title, url, tags) VALUES (?, ?, ?, ?, ?)';
    my $sth = database->prepare($sql);
    $sth->execute( $id, $data->{account}, $data->{title}, $data->{url}, $data->{tags} );

    info request->remote_address, " added $data->{account} $id";

    send_as JSON => { success => 1, code => 201 };
};

=head2 GET /delete

Delete an item.

=cut

post '/delete' => sub {
    my $account = body_parameters->get('a');
    my $item    = body_parameters->get('i');
    my $query   = body_parameters->get('q');

    my $file = _auth($account);

    send_error( 'No item id provided', 400 ) unless $item;

    my $sql = "DELETE FROM bookmarks WHERE account = ? AND id = ?";
    my $sth = database->prepare($sql);
    $sth->execute( $account, $item );

    info request->remote_address, " deleted $account $item";

    redirect $query ? "/search?a=$account&q=$query" : "/?a=$account";
};

=head2 /check

Check item.

=cut

post '/check' => sub {
    my $account = body_parameters->get('a');
    my $item    = body_parameters->get('i');
    my $check   = '';

    my $file = _auth($account);

    send_error( 'No item id provided', 400 ) unless $item;

    my $sql = 'SELECT * FROM bookmarks WHERE account = ? AND id = ?';
    my $sth = database->prepare($sql);
    $sth->execute( $account, $item );
    my $res = $sth->fetchall_hashref('id');

    my $data = [ sort { $a->{id} <=> $b->{id} } values %$res ];

    unless ( is_success( eval { getprint $data->[0]{url} } ) ) {
        $check = $item;
    };
    info request->remote_address, " checked $account $item";

    template index => {
        account => $account,
        data    => $data,
        check   => $check,
        search  => '',
    };
};

sub _auth {
    my $account = shift;

    send_error( NOAUTH, 401 ) unless $account;

    my $file = PATH . $account . EXT;

    send_error( UNKNOWN, 400 ) unless -e $file;

    return $file;
}

true;

__END__

=head1 SEE ALSO

L<Dancer2>

L<HTTP::Simple>

L<List::Util>

L<Try::Tiny>

=cut
