package Bookmarker;

# ABSTRACT: Manage bookmarks in the cloud

use Dancer2;
use Dancer2::Plugin::Auth::Extensible;
use Dancer2::Plugin::Auth::Extensible::Provider::Database;
use Dancer2::Plugin::Database;
use HTTP::Simple qw/ getprint is_error /;
use List::Util;
use Netscape::Bookmarks;
use Try::Tiny;

use constant SQL1 => 'SELECT * FROM bookmarks WHERE account = ?';
use constant SQL2 => 'INSERT INTO bookmarks (id, account, title, url, tags) VALUES (?, ?, ?, ?, ?)';

our $VERSION = '0.01';

=head1 NAME

Bookmarker - Manage bookmarks in the cloud

=head1 DESCRIPTION

A C<Bookmarker> instance manages bookmarks in the cloud.

=head1 ENDPOINTS

=head2 GET /

List items.

=cut

get '/' => require_login sub {
    my $user = logged_in_user;

    my $sth = database->prepare(SQL1);
    $sth->execute( $user->{account} );
    my $res = $sth->fetchall_hashref('id');

    info request->remote_address, " read $user->{account}";

    template index => {
        data   => [ sort { $a->{id} <=> $b->{id} } values %$res ],
        check  => '',
        search => '',
    };
};

=head2 ANY /search

Search items.

=cut

any '/search' => require_login sub {
    my $query = body_parameters->get('q') || query_parameters->get('q');

    my $user = logged_in_user;

    my $data = _search_data( $user->{account}, $query );

    info request->remote_address, " searched $user->{account} for '$query'";

    template index => {
        data   => $data,
        check  => '',
        search => $query,
    };
};

sub _search_data {
    my ( $account, $query ) = @_;

    my $is_regex = 0;
    if ( $query =~ m|^/.*?/$| ) {
        $query =~ s|/||g;
        $is_regex = 1;
    }

    my $is_quoted = 0;
    if ( $query =~ m|^".*?"$| ) {
        $query =~ s|"||g;
        $is_quoted = 1;
    }

    my @query = split /\s+/, $query;

    my $sth = database->prepare(SQL1);
    $sth->execute($account);
    my $res = $sth->fetchall_hashref('id');

    my $data = [];

    for my $r ( sort { $a->{id} <=> $b->{id} } values %$res ) {
        if ( !@query ||
            ( @query && (
                ( $is_quoted && ( $r->{title} =~ /\Q$query\E/ || $r->{url} =~ /\Q$query\E/ || $r->{tags} =~ /\Q$query\E/ ) )
                ||
                ( !$is_quoted && $is_regex && List::Util::any { $r->{title} =~ /$_/i || $r->{url} =~ /$_/i || $r->{tags} =~ /$_/i } @query )
                ||
                ( !$is_quoted && !$is_regex && List::Util::any { $r->{title} =~ /\Q$_\E/i || $r->{url} =~ /\Q$_\E/i || $r->{tags} =~ /\Q$_\E/i } @query )
            ) )
        )
        {
            push @$data, $r;
        }
    }

    return $data;
}

=head2 POST /update

Update an item.

=cut

post '/update' => require_login sub {
    my $new     = body_parameters->get('n');
    my $item    = body_parameters->get('i');
    my $update  = body_parameters->get('u');
    my $query   = body_parameters->get('q');

    my $user = logged_in_user;

    send_error( 'No item id provided', 400 ) unless $item;

    $new ||= $update eq 'title' ? 'Untitled' : '';

    my $sql = "UPDATE bookmarks SET $update = ? WHERE account = ? AND id = ?";
    my $sth = database->prepare($sql);
    $sth->execute( $new, $user->{account}, $item );

    info request->remote_address, " updated $user->{account} $item";

    redirect $query ? "/search?q=$query" : '/';
};

=head2 POST /add

Add an item from JSON.

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

    $data->{title} ||= 'Untitled';
    $data->{tags}  ||= '';

    my $id = time();

    my $sth = database->prepare(SQL2);
    $sth->execute( $id, $data->{account}, $data->{title}, $data->{url}, $data->{tags} );

    info request->remote_address, " added $data->{account} $id";

    send_as JSON => { success => 1, code => 201, id => $id };
};

=head2 POST /new

Create a new item from the UI.

=cut

post '/new' => require_login sub {
    my $title = body_parameters->get('title') || 'Untitled';
    my $url   = body_parameters->get('url');
    my $tags  = body_parameters->get('tags') || '';

    my $user = logged_in_user;

    send_error( 'No URL provided', 400 ) unless $url;

    my $id = time();

    my $sth = database->prepare(SQL2);
    $sth->execute( $id, $user->{account}, $title, $url, $tags );

    info request->remote_address, " added $user->{account} $id";

    redirect '/';
};

=head2 POST /delete

Delete an item.

=cut

post '/delete' => require_login sub {
    my $item  = body_parameters->get('i');
    my $query = body_parameters->get('q');

    my $user = logged_in_user;

    send_error( 'No item id provided', 400 ) unless $item;

    my $sql = "DELETE FROM bookmarks WHERE account = ? AND id = ?";
    my $sth = database->prepare($sql);
    $sth->execute( $user->{account}, $item );

    info request->remote_address, " deleted $user->{account} $item";

    redirect $query ? "/search?q=$query" : '/';
};

=head2 POST /check

Check item.

=cut

post '/check' => require_login sub {
    my $item  = body_parameters->get('i');
    my $check = '';

    my $user = logged_in_user;

    send_error( 'No item id provided', 400 ) unless $item;

    my $sql = SQL1 . ' AND id = ?';
    my $sth = database->prepare($sql);
    $sth->execute( $user->{account}, $item );
    my $res = $sth->fetchall_hashref('id');

    my $data = [ values %$res ];

    if ( is_error( eval { getprint $data->[0]{url} } ) ) {
        $check = $item;
    };

    info request->remote_address, " checked $user->{account} $item";

    template index => {
        data   => $data,
        check  => $check,
        search => '',
    };
};

=head2 POST /export

Export items.

=cut

post '/export' => require_login sub {
    my $query = body_parameters->get('q');

    my $user = logged_in_user;

    my $data = _search_data( $user->{account}, $query );

    my $bookmarks = Netscape::Bookmarks::Category->new({
        add_date    => time(),
        description => 'Exported from Cloudbookmarker',
        folded      => 0,
        title       => 'Root',
    });

    for my $bookmark ( @$data ) {
        my $link = Netscape::Bookmarks::Link->new({
            ADD_DATE => $bookmark->{id},
            TITLE    => $bookmark->{title},
            HREF     => $bookmark->{url},
        });

        $bookmarks->add($link);
    }

    my $html = $bookmarks->as_string;

    send_file( \$html, content_type => 'text/html', filename => 'exported-bookmarks.html' );
};

=head2 POST /import

Import items.

=cut

post '/import' => require_login sub {
    my $query = body_parameters->get('q');

    my $user = logged_in_user;

    my $upload = request->upload('bookmarks');

    if ( $upload ) {
        my $tempname = $upload->tempname;

        my $sth = database->prepare(SQL2);

        my $id = time();

        my $add_link = sub {
            my $obj = shift;
            if ( ref $obj eq 'Netscape::Bookmarks::Link' ) {
                $sth->execute( $id++, $user->{account}, $obj->title, $obj->href, '' );
            }
        };

        my $bookmarks = Netscape::Bookmarks->new($tempname);

        $bookmarks->recurse( $add_link );

        info request->remote_address, " imported to $user->{account}";
    }

    redirect $query ? "/search?q=$query" : '/';
};

=head2 GET /help

Show help.

=cut

get '/help' => sub {
    template 'help';
};

true;

__END__

=head1 SEE ALSO

L<Dancer2>

L<Dancer2::Plugin::Auth::Extensible>

L<Dancer2::Plugin::Auth::Extensible::Provider::Database>

L<Dancer2::Plugin::Database>

L<DBD::SQLite>

L<HTTP::Simple>

L<List::Util>

L<Netscape::Bookmarks>

L<Try::Tiny>

=cut
