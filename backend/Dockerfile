# SeeItOn backend: FastAPI + CatVTON, NVIDIA GPU gerekir (CUDA 12.8, RTX 50 serisi dahil).
#
# Derleme (proje kökünden):
#   docker build -f backend/Dockerfile -t seeiton-backend .
# Çalıştırma (model ağırlıkları kalıcı bir birimde tutulur, ilk açılışta ~6 GB iner):
#   docker run --gpus all -p 8000:8000 -v seeiton-hf:/root/.cache/huggingface seeiton-backend
#
# Sürümler requirements.lock ile sabittir; CatVTON kaynağı aşağıdaki commit'e sabitlenmiştir.
FROM nvidia/cuda:12.8.1-cudnn-runtime-ubuntu22.04

ARG CATVTON_COMMIT=7818397f25613beedb3d861a34769f607cfcf3b1
ENV DEBIAN_FRONTEND=noninteractive PYTHONUNBUFFERED=1 HF_HUB_DISABLE_XET=1

RUN apt-get update && apt-get install -y --no-install-recommends \
        python3.11 python3.11-venv python3-pip git ffmpeg libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN python3.11 -m venv /venv
ENV PATH="/venv/bin:$PATH"

# PyTorch CUDA 12.8 tekerlekleri, sonra kilitli bağımlılıklar
COPY backend/requirements.lock /app/backend/requirements.lock
RUN pip install --no-cache-dir torch torchvision --index-url https://download.pytorch.org/whl/cu128 \
 && grep -v -E "^(torch|torchvision|pywin32|pywinpty)==" backend/requirements.lock > /tmp/req.txt \
 && pip install --no-cache-dir -r /tmp/req.txt

# CatVTON kaynak kodu, sabit commit
RUN git clone https://github.com/Zheng-Chong/CatVTON.git ai/CatVTON \
 && git -C ai/CatVTON checkout ${CATVTON_COMMIT}

COPY backend /app/backend
WORKDIR /app/backend
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s --start-period=180s CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health')"
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
