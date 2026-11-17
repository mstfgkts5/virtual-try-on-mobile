"""Kişiyi kadrajda bulup etrafından 3:4 kırpma (GPU gerektirmez, test edilebilir).

Gerçek fotoğraflarda kişi kadrajın küçük bir kısmını kaplar; bütün fotoğraf 576x768'e
küçültülünce gövde ~250 piksele düşer ve CatVTON deseni/vücut sınırını bozar.
Model kişinin etrafındaki 3:4 kutuda çalıştırılır, sonuç fotoğrafa geri yapıştırılır.
"""
import numpy as np
from PIL import Image

MAX_CANVAS_HEIGHT = 1536  # Dönen görselin üst sınırı (PNG boyutu makul kalsın)
MIN_GAIN = 0.80  # Kutu kadrajın %80'inden büyükse kırpmanın faydası yok (VITON-HD gibi)


def canvas_of(person: Image.Image, width: int, height: int) -> Image.Image:
    """Orijinal fotoğrafın ortadan 3:4 kırpılmış hâli; en fazla 1536 piksel yükseklik,
    en az model çözünürlüğü. Önce/sonra karşılaştırması bu görsel üzerinden yapılır."""
    w, h = person.size
    aspect = width / height
    if w / h > aspect:
        cw, ch = round(h * aspect), h
    else:
        cw, ch = w, round(w / aspect)
    left, top = (w - cw) // 2, (h - ch) // 2
    crop = person.crop((left, top, left + cw, top + ch))
    out_h = max(height, min(ch, MAX_CANVAS_HEIGHT))
    out_w = round(out_h * aspect)
    return crop.resize((out_w, out_h), Image.LANCZOS)


def main_person(labels: np.ndarray) -> np.ndarray:
    """Ayrıştırma haritasında ana kişi: kişi piksellerinin (biraz genişletilip birleştirilmiş)
    en büyük bağlı bölgesi. Arka plandaki heykel, afiş, uzaktaki insanlar gibi küçük "kişi"
    parçaları kırpma kutusuna ve maskeye girmesin (Madrid fotoğrafı: gökyüzünde leke)."""
    import cv2

    person = (np.asarray(labels) != 0).astype(np.uint8)
    if person.sum() == 0:
        return person.astype(bool)
    k = max(3, max(person.shape) // 100) | 1
    joined = cv2.dilate(person, np.ones((k, k), np.uint8))  # kopuk kol/bacak parçalarını birleştir
    n, lab, st, _ = cv2.connectedComponentsWithStats(joined, connectivity=8)
    if n <= 2:
        return person.astype(bool)
    main = lab == 1 + int(np.argmax(st[1:, cv2.CC_STAT_AREA]))
    return main & (person > 0)


def person_bbox(labels: np.ndarray) -> tuple[int, int, int, int] | None:
    """Ana kişinin sınır kutusu: (sol, üst, sağ, alt). Kişi bulunamazsa None."""
    ys, xs = np.nonzero(main_person(labels))
    if len(xs) < 50:  # Kişi bulunamadı
        return None
    return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1


def limit_mask_to_person(mask: Image.Image, labels: np.ndarray, reach: float = 1 / 12) -> Image.Image:
    """Maskeyi ana kişinin geniş çevresiyle sınırlar. Yakın alan (kol-gövde arası, bol kıyafet)
    olduğu gibi kalır; yalnızca kişiden uzak, ayrık maske parçaları atılır."""
    import cv2

    main = main_person(labels).astype(np.uint8)
    if main.sum() == 0:
        return mask
    k = max(3, int(max(main.shape) * reach)) | 1
    near = cv2.dilate(main, np.ones((k, k), np.uint8)) > 0
    near = cv2.resize(near.astype(np.uint8), mask.size, interpolation=cv2.INTER_NEAREST) > 0
    m = np.array(mask.convert("L"))
    m[~near] = 0
    return Image.fromarray(m)


def fit_box(bbox, canvas_w: int, canvas_h: int, aspect: float = 3 / 4, margin: float = 0.10):
    """Kişi kutusunu kenar payı ekleyip tam 3:4 olacak şekilde büyütür ve kadrajın içine kaydırır.
    Kırpmaya gerek yoksa (kutu kadrajın büyük kısmı) None döner."""
    l, t, r, b = bbox
    bw, bh = r - l, b - t
    pad = margin * max(bw, bh)
    l, t, r, b = l - pad, t - pad, r + pad, b + pad
    bw, bh = r - l, b - t
    # 3:4'e genişlet
    if bw / bh < aspect:
        bw = bh * aspect
    else:
        bh = bw / aspect
    # Kadraja sığdır
    if bw > canvas_w:
        bw, bh = canvas_w, canvas_w / aspect
    if bh > canvas_h:
        bh, bw = canvas_h, canvas_h * aspect
    cx, cy = (l + r) / 2, (t + b) / 2
    left = min(max(cx - bw / 2, 0), canvas_w - bw)
    top = min(max(cy - bh / 2, 0), canvas_h - bh)
    box = (round(left), round(top), round(left + bw), round(top + bh))
    if (box[2] - box[0]) * (box[3] - box[1]) > MIN_GAIN * canvas_w * canvas_h:
        return None
    return box



def trim_garment(garment: Image.Image, margin: float = 0.04, tol: int = 18) -> Image.Image:
    """Ürün fotoğrafındaki boş fonu kırpar: köşe renginden belirgin farklı piksellerin kutusu
    + kenar payı. Kıyafet modele daha çok piksel ile gider."""
    a = np.asarray(garment.convert("RGB")).astype(np.int16)
    corners = np.stack([a[0, 0], a[0, -1], a[-1, 0], a[-1, -1]]).mean(axis=0)
    diff = np.abs(a - corners).max(axis=2) > tol
    ys, xs = np.nonzero(diff)
    if len(xs) < 100:
        return garment
    l, t, r, b = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
    pad = int(margin * max(r - l, b - t))
    w, h = garment.size
    box = (max(0, l - pad), max(0, t - pad), min(w, r + pad), min(h, b + pad))
    if (box[2] - box[0]) * (box[3] - box[1]) > 0.9 * w * h:
        return garment
    return garment.crop(box)


# SCHP-LIP etiketleri: kıyafet sınıfları (renk düzeltmede yalnız bu pikseller değişir)
CLOTH_LABELS = {
    "upper": (5, 6, 7, 10, 11),  # üst giysi, elbise, ceket, tulum, atkı
    "lower": (6, 9, 10, 12),  # elbise, pantolon, tulum, etek
    "overall": (5, 6, 7, 9, 10, 12),
}


def _foreground_by_corners(garment: Image.Image, tol: int = 18) -> np.ndarray:
    a = np.asarray(garment.convert("RGB")).astype(np.int16)
    corners = np.stack([a[0, 0], a[0, -1], a[-1, 0], a[-1, -1]]).mean(axis=0)
    return np.abs(a - corners).max(axis=2) > tol


def garment_foreground(garment: Image.Image) -> np.ndarray:
    """Ürün fotoğrafında kıyafet pikselleri. GrabCut (kenar şeridi = fon) gölgeli/degrade fonda ve
    açık renkli desenlerde köşe rengi eşiğinden çok daha doğru; en büyük parça alınır.
    Başarısız olursa köşe rengine göre basit ayrıma düşer."""
    import cv2

    a = np.asarray(garment.convert("RGB"))
    h, w = a.shape[:2]
    try:
        s = min(1.0, 320 / max(h, w))
        sm = cv2.resize(a, (max(8, int(w * s)), max(8, int(h * s))), interpolation=cv2.INTER_AREA)
        hh, ww = sm.shape[:2]
        m = np.zeros((hh, ww), np.uint8)
        rect = (int(ww * 0.03), int(hh * 0.03), int(ww * 0.94), int(hh * 0.94))
        bgd, fgd = np.zeros((1, 65), np.float64), np.zeros((1, 65), np.float64)
        cv2.grabCut(cv2.cvtColor(sm, cv2.COLOR_RGB2BGR), m, rect, bgd, fgd, 4, cv2.GC_INIT_WITH_RECT)
        fg = ((m == cv2.GC_FGD) | (m == cv2.GC_PR_FGD)).astype(np.uint8)
        n, lab, st, _ = cv2.connectedComponentsWithStats(fg, 8)
        if n > 1:
            fg = (lab == 1 + int(np.argmax(st[1:, cv2.CC_STAT_AREA]))).astype(np.uint8)
        fg = cv2.morphologyEx(fg, cv2.MORPH_CLOSE, np.ones((5, 5), np.uint8))
        fg = cv2.resize(fg, (w, h), interpolation=cv2.INTER_NEAREST) > 0
        if 0.03 < fg.mean() < 0.95:
            return fg
    except cv2.error:
        pass
    return _foreground_by_corners(garment)


def match_colors(result: Image.Image, cloth: np.ndarray, garment: Image.Image,
                 chroma: float = 0.85, lightness: float = 0.5) -> Image.Image:
    """Üretilen kıyafet bölgesinin renk dağılımını kıyafet görseline yaklaştırır (LAB uzayında
    Reinhard aktarımı). Difüzyon modeli az adımda ve sisli/loş fotoğraflarda renkleri soldurur.
    Renk tonu ve doygunluk (a, b) büyük ölçüde, parlaklık (L) yarı yarıya eşitlenir; parlaklığın
    yayılımı korunur ki kıvrım ve gölgeler kaybolmasın."""
    import cv2

    if cloth.sum() < 200:
        return result
    g = np.asarray(garment.convert("RGB"))
    fg = garment_foreground(garment)
    if fg.sum() < 200:
        return result
    g_lab = cv2.cvtColor(g, cv2.COLOR_RGB2LAB).astype(np.float32)[fg]
    r = np.asarray(result.convert("RGB"))
    r_lab = cv2.cvtColor(r, cv2.COLOR_RGB2LAB).astype(np.float32)
    px = r_lab[cloth]
    mu_r, sd_r = px.mean(0), px.std(0) + 1e-3
    mu_g, sd_g = g_lab.mean(0), g_lab.std(0) + 1e-3
    out = r_lab.copy()
    for c, k in ((1, chroma), (2, chroma)):
        ratio = float(np.clip(sd_g[c] / sd_r[c], 0.5, 2.5))
        target = (r_lab[..., c] - mu_r[c]) * ratio + mu_g[c]
        out[..., c] = r_lab[..., c] * (1 - k) + target * k
    out[..., 0] = r_lab[..., 0] + lightness * (mu_g[0] - mu_r[0])
    out = cv2.cvtColor(np.clip(out, 0, 255).astype(np.uint8), cv2.COLOR_LAB2RGB)
    soft = cv2.GaussianBlur(cloth.astype(np.float32), (0, 0), max(1.0, r.shape[0] / 400))[..., None]
    blended = r * (1 - soft) + out * soft
    return Image.fromarray(np.clip(blended, 0, 255).astype(np.uint8))
