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

    die 'Not authorized' unless $account;

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
        die 'Unknown account';
    };

    template index => {
        account => $account,
        data    => $data,
    };
};

=head2 POST /title

Update a title.

=cut

post '/title' => sub {
    my $account   = body_parameters->get('a');
    my $new_title = body_parameters->get('t');
    my $item      = body_parameters->get('i');

    die 'Not authorized' unless $account;

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
    };

    redirect "/?a=$account";
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
        return { error => $msg, code => $code };
    }

    return { success => 1, code => $code };
};

=head2 GET /del

Delete an item.

=cut

get '/del' => sub {
    my $account = query_parameters->get('a');
    my $item    = query_parameters->get('i');

    die 'Not authorized' unless $account;

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
    };

    redirect "/?a=$account";
};

true;

__END__

=head1 SEE ALSO

L<Dancer2>

L<Try::Tiny>

=cut
