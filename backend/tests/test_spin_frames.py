import numpy as np
import pytest

from spin_frames import VideoError, extract_frames, sample_times
from tests.videos import make_video


def test_sample_times_even_and_trimmed():
    t = sample_times(10.0, 8)
    assert len(t) == 8
    assert t[0] == pytest.approx(0.5)
    assert t[-1] < 9.5
    gaps = np.diff(t)
    assert gaps == pytest.approx([gaps[0]] * 7, abs=1e-6)
    assert sample_times(10.0, 4)[0] == pytest.approx(0.5)


def test_extract_returns_n_portrait_frames():
    frames = extract_frames(make_video(360, 640, 3), 8)
    assert len(frames) == 8
    assert all(f.size == (768, 1024) and f.mode == "RGB" for f in frames)
    first = np.asarray(frames[0]).mean()
    last = np.asarray(frames[-1]).mean()
    assert last > first + 50  # zamanla değişen kareler alınmış


def test_rotated_video_stays_portrait():
    # iPhone dikey videosu: sensör yatay kaydeder, ffprobe döndürmeyi -90 gösterir.
    # Doğru dik görüntüde (ffmpeg autorotate ile aynı) ham karenin sol tarafı ÜSTE gelir.
    frames = extract_frames(make_video(640, 360, 2, rotate=-90, marker=True), 4)
    assert all(f.size == (768, 1024) for f in frames)
    arr = np.asarray(frames[0]).astype(int)
    red = (arr[..., 0] > 200) & (arr[..., 1] < 80)
    top, bottom = red[: arr.shape[0] // 2].mean(), red[arr.shape[0] // 2 :].mean()
    assert top > 0.9 and bottom < 0.1


def test_invalid_bytes_raise_video_error():
    with pytest.raises(VideoError):
        extract_frames(b"not a video", 8)


def test_too_long_raises():
    with pytest.raises(VideoError, match="30"):
        extract_frames(make_video(64, 112, 31, fps=5), 8)


def test_too_few_decodable_frames_raises():
    with pytest.raises(VideoError):
        extract_frames(make_video(64, 112, 0.1), 8)
