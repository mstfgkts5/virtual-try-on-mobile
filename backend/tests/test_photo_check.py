import numpy as np

from photo_check import (BACK_VIEW, LOW_RESOLUTION, MULTIPLE_PEOPLE, NO_PERSON, PERSON_SMALL, REGION_MISSING,
                         assess_photo)

H, W = 400, 300
BIG = (1200, 1600)


def person(top=20, bottom=390, left=100, right=200, face=True, shirt=True, body=True):
    lip = np.zeros((H, W), dtype=np.uint8)
    lip[top:bottom, left:right] = 9  # pantolon / gövde
    if body:
        lip[top + 60: top + 200, left - 8: left] = 14  # sol kol
        lip[top + 60: top + 200, right: right + 8] = 15  # sağ kol
    if shirt:
        lip[top + 60: top + 200, left:right] = 5  # üst giysi
    if face:
        lip[top: top + 40, left + 30: right - 30] = 13  # yüz
    return lip


def test_good_photo_has_no_warnings():
    assert assess_photo(person(), BIG, "upper") == []


def test_empty_photo():
    assert assess_photo(np.zeros((H, W), dtype=np.uint8), BIG, "upper") == [NO_PERSON]


def test_small_person_far_away():
    # Göl fotoğrafı gibi: kişi kadrajın alt yarısında
    assert PERSON_SMALL in assess_photo(person(top=230, bottom=399, left=130, right=170), BIG, "upper")


def test_back_view():
    assert BACK_VIEW in assess_photo(person(face=False), BIG, "upper")


def test_two_people():
    lip = person(left=20, right=110)
    lip |= person(left=180, right=270)
    assert MULTIPLE_PEOPLE in assess_photo(lip, BIG, "upper")


def test_upper_region_missing():
    assert REGION_MISSING in assess_photo(person(shirt=False), BIG, "upper")
    assert REGION_MISSING not in assess_photo(person(shirt=False), BIG, "lower")


def test_low_resolution():
    assert LOW_RESOLUTION in assess_photo(person(), (300, 400), "upper")


def test_garment_product_photo_is_not_a_person():
    # Yalnız kıyafet: ayrıştırıcı kıyafet etiketleri bulur ama yüz/kol/bacak yok
    lip = np.zeros((H, W), dtype=np.uint8)
    lip[60:340, 60:240] = 7  # ceket
    assert assess_photo(lip, BIG, "upper") == [NO_PERSON]
