# CatVTON örnek görselleriyle üst giyim ve tam kıyafet testlerini çalıştırır (proje kökünden).
$env:PYTHONIOENCODING = "utf-8"
$env:HF_HUB_DISABLE_XET = "1"  # Xet indirmesi bazı ağlarda takılıyor; klasik HTTP indirmesini kullan
$py = "backend\venv\Scripts\python.exe"
$ex = "ai\CatVTON\resource\demo\example"

& $py -m pip install -q av
& $py backend\download_models.py
& $py tests\smoke_tryon.py "$ex\person\women\049713_0.jpg" "$ex\condition\upper\21514384_52353349_1000.jpg" upper tests\output_upper.png
& $py tests\smoke_tryon.py "$ex\person\men\model_5.png" "$ex\condition\overall\21744571_51588794_1000.jpg" overall tests\output_overall.png
