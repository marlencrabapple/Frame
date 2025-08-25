use Object::Pad ':experimental(:all)';

package Frame::App::Media::Stream;

class Frame::App::Media::Stream : isa(Frame::App);

use utf8;
use v5.40;

use Const::Fast;

method startup {
    my $r = $self->routes;

    $r->get('/stream/:id');
    $r->get('/stream/:id.m3u8');
}

method view_m3u8 ($vid_id) {

}

method view_video_playback ($vid_id) {

}

const our $video_page => <<'...'
<!DOCTYPE html>
<html lang="en">
<head>
<title>%s</title>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link
  rel="stylesheet"
  href="/www/bulma.min.css"
>
<style type='text/css'>

</style>
</head>
<body>
<h1>%s</h1>
<video>
<video>
</body>
</html>
...

__END__

