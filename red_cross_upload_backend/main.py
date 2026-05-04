import time
from pathlib import Path

from fastapi import FastAPI, UploadFile, File, Form, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

app = FastAPI()

UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")


@app.post("/upload-emergency-image")
async def upload_emergency_image(
    request: Request,
    requestId: str = Form(...),
    file: UploadFile = File(...),
):
    filename = file.filename or "image.jpg"
    extension = filename.split(".")[-1].lower()

    allowed_extensions = ["jpg", "jpeg", "png", "webp"]
    allowed_content_types = [
        "image/jpeg",
        "image/jpg",
        "image/png",
        "image/webp",
        "application/octet-stream",
    ]

    if extension not in allowed_extensions:
        raise HTTPException(
            status_code=400,
            detail="Only JPG, JPEG, PNG, or WEBP images are allowed.",
        )

    if file.content_type not in allowed_content_types:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid file type: {file.content_type}",
        )

    safe_filename = f"{int(time.time() * 1000)}.{extension}"

    folder = UPLOAD_DIR / "emergency_requests" / requestId
    folder.mkdir(parents=True, exist_ok=True)

    file_path = folder / safe_filename

    content = await file.read()

    if len(content) == 0:
        raise HTTPException(
            status_code=400,
            detail="Uploaded file is empty.",
        )

    with open(file_path, "wb") as f:
        f.write(content)

    base_url = str(request.base_url).rstrip("/")

    image_url = (
        f"{base_url}/uploads/emergency_requests/{requestId}/{safe_filename}"
    )

    return {
        "success": True,
        "imageUrl": image_url,
        "imagePath": f"uploads/emergency_requests/{requestId}/{safe_filename}",
    }