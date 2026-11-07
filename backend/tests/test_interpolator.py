import pytest
import torch

from interpolator import pad_to_multiple, recursive_midpoints


def test_recursive_midpoints_order_n3():
    # Sayılarla orta nokta: a=0, b=1 → 0.25, 0.5, 0.75 sırasıyla
    assert recursive_midpoints(0.0, 1.0, 3, lambda x, y: (x + y) / 2) == [0.25, 0.5, 0.75]


def test_recursive_midpoints_n1_and_n7():
    mid = lambda x, y: (x + y) / 2  # noqa: E731
    assert recursive_midpoints(0.0, 1.0, 1, mid) == [0.5]
    assert recursive_midpoints(0.0, 1.0, 7, mid) == pytest.approx([i / 8 for i in range(1, 8)])


def test_recursive_midpoints_rejects_other_counts():
    with pytest.raises(ValueError):
        recursive_midpoints(0.0, 1.0, 2, lambda x, y: x)


def test_pad_to_multiple_and_back():
    t = torch.zeros(1, 3, 770, 580)
    padded, (h, w) = pad_to_multiple(t, 32)
    assert padded.shape[-2:] == (800, 608) and (h, w) == (770, 580)


def test_pad_noop_when_aligned():
    t = torch.zeros(1, 3, 768, 576)
    padded, _ = pad_to_multiple(t, 32)
    assert padded.shape[-2:] == (768, 576)
