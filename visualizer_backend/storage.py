import os
import time
from typing import BinaryIO

import firebase_admin
from firebase_admin import credentials, storage

_initialized = False


def _init_if_needed():
    global _initialized
    if _initialized:
        return
    sa_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    bucket_name = os.getenv("FIREBASE_STORAGE_BUCKET")
    if not sa_path or not os.path.exists(sa_path):
        raise RuntimeError(
            "Firebase service account not configured. Set GOOGLE_APPLICATION_CREDENTIALS to the JSON key path.")
    if not bucket_name:
        raise RuntimeError(
            "FIREBASE_STORAGE_BUCKET not set. Example: my-project.appspot.com")
    cred = credentials.Certificate(sa_path)
    firebase_admin.initialize_app(cred, {"storageBucket": bucket_name})
    _initialized = True


def upload_to_firebase(stream: BinaryIO, key: str, content_type: str = "image/jpeg") -> str:
    """
    Uploads a stream as a blob to Firebase Storage and returns a public URL.
    For signed URLs, switch to generate_signed_url.
    """
    _init_if_needed()
    bucket = storage.bucket()
    blob = bucket.blob(key)
    blob.upload_from_file(stream, content_type=content_type)

    # Make public or use signed URLs depending on your policy
    if os.getenv("PUBLIC_READ", "true").lower() == "true":
        blob.make_public()
        return blob.public_url
    else:
        # Signed URL valid for 7 days
        expiration = int(time.time()) + 7 * 24 * 3600
        return blob.generate_signed_url(expiration=expiration)
