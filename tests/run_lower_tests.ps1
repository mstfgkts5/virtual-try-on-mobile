# Alt giyim testleri: üretilen kıyafetleri hazır mankenlere backend API üzerinden giydirir (proje kökünden, backend açıkken).
$env:PYTHONIOENCODING = "utf-8"
$py = "backend\venv\Scripts\python.exe"
$m = "see_it_on\assets\images\mannequins"
$g = "test_images\garments"

& $py tests\api_tryon.py "$m\w-m.jpg" "$g\jeans-w\2000.png" lower tests\output_lower_wm_jeans.png
& $py tests\api_tryon.py "$m\w-s.jpg" "$g\skirt-w\3003.png" lower tests\output_lower_ws_skirt.png
& $py tests\api_tryon.py "$m\w-l.jpg" "$g\shorts-w\2000.png" lower tests\output_lower_wl_shorts.png
& $py tests\api_tryon.py "$m\m-m.jpg" "$g\chino-m\2000.png" lower tests\output_lower_mm_chino.png
& $py tests\api_tryon.py "$m\m-xl.jpg" "$g\trousers-m\2002.png" lower tests\output_lower_mxl_trousers.png
