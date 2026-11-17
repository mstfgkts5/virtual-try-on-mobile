"""Deneme öncesi fotoğraf kontrolü (GPU gerektirmez; SCHP-LIP etiket haritası üzerinde çalışır).

CatVTON stüdyoda, önden çekilmiş, kadrajı dolduran kişilerle eğitildi. Bu dağılımın dışındaki
fotoğraflarda (kişi çok küçük, arkası dönük, birden fazla kişi...) sonuç belirgin şekilde bozulur.
Uygulama bu uyarıları kullanıcıya gösterir; kullanıcı yine de devam edebilir.
"""
import numpy as np

from spin_frames import BACK_FACE_RATIO, face_ratio

# Uyarı kodları (uygulama bunları çevirir); önem sırasına göre
NO_PERSON = "no_person"
MULTIPLE_PEOPLE = "multiple_people"
BACK_VIEW = "back_view"
PERSON_SMALL = "person_small"
REGION_MISSING = "region_missing"
LOW_RESOLUTION = "low_resolution"

MIN_PERSON_RATIO = 0.02  # kişi pikselleri / kadraj
MIN_PERSON_HEIGHT = 0.5  # kişinin boyu / kadraj yüksekliği
MIN_REGION_RATIO = 0.08  # denenecek bölge pikselleri / kişi pikselleri
MIN_SIDE_PX = 512  # orijinal fotoğrafın kısa kenarı
SECOND_PERSON = 0.25  # ikinci en büyük kişi / en büyük kişi
MIN_BODY_RATIO = 0.02  # vücut parçaları / kişi pikselleri; altındaysa yalnız kıyafet (ürün fotoğrafı)
BODY_LABELS = (2, 13, 14, 15, 16, 17)  # saç, yüz, kollar, bacaklar

# SCHP-LIP: kıyafetin gideceği bölge (eski kıyafet + ilgili uzuvlar)
REGION_LABELS = {
    "upper": (5, 6, 7, 10, 14, 15),  # üst giysi, elbise, ceket, tulum, kollar
    "lower": (6, 9, 10, 12, 16, 17),  # elbise, pantolon, tulum, etek, bacaklar
    "overall": (5, 6, 7, 9, 10, 12, 14, 15, 16, 17),
}


def _people_count(person: np.ndarray) -> int:
    """Birbirinden ayrık büyük kişi bölgelerinin sayısı (küçük parçalar sayılmaz)."""
    import cv2

    n, _, stats, _ = cv2.connectedComponentsWithStats(person.astype(np.uint8), connectivity=8)
    areas = sorted((int(a) for a in stats[1:, cv2.CC_STAT_AREA]), reverse=True)
    if not areas:
        return 0
    big = [a for a in areas if a >= SECOND_PERSON * areas[0] and a >= 0.01 * person.size]
    return max(1, len(big))


def assess_photo(lip: np.ndarray, original_size: tuple[int, int], category: str) -> list[str]:
    """Fotoğraf için uyarı kodları; boş liste = sorun yok."""
    lip = np.asarray(lip)
    person = lip != 0
    if person.mean() < MIN_PERSON_RATIO:
        return [NO_PERSON]
    # Ürün fotoğrafı: ayrıştırıcı kıyafeti "kişi" sayar ama ortada saç, yüz, kol, bacak yoktur
    if np.isin(lip, BODY_LABELS).sum() / person.sum() < MIN_BODY_RATIO:
        return [NO_PERSON]
    warnings = []
    if _people_count(person) > 1:
        warnings.append(MULTIPLE_PEOPLE)
    if face_ratio(lip) < BACK_FACE_RATIO:
        warnings.append(BACK_VIEW)
    ys = np.nonzero(person.any(axis=1))[0]
    if (ys[-1] - ys[0] + 1) / lip.shape[0] < MIN_PERSON_HEIGHT:
        warnings.append(PERSON_SMALL)
    region = np.isin(lip, REGION_LABELS.get(category, REGION_LABELS["upper"])).sum()
    if region / person.sum() < MIN_REGION_RATIO:
        warnings.append(REGION_MISSING)
    if min(original_size) < MIN_SIDE_PX:
        warnings.append(LOW_RESOLUTION)
    return warnings
