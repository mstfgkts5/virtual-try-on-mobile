import numpy as np
import pytest

from spin_frames import LIP_FACE, face_ratio


def test_face_ratio_front():
    lip = np.zeros((100, 100), np.uint8)
    lip.flat[:2000] = 5  # kişi (üst giyim)
    lip.flat[:200] = LIP_FACE  # bunların 200'ü yüz
    assert face_ratio(lip) == pytest.approx(0.1)


def test_face_ratio_back_is_zero():
    lip = np.zeros((100, 100), np.uint8)
    lip.flat[:2000] = 5
    assert face_ratio(lip) == 0.0


def test_face_ratio_empty_is_zero():
    assert face_ratio(np.zeros((10, 10), np.uint8)) == 0.0
