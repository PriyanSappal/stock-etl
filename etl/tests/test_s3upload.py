import pytest
from app import s3upload  # adjust import path if needed

def test_upload_to_s3(monkeypatch, tmp_path):
    test_file = tmp_path / "dummy.txt"
    test_file.write_text("hello world")

    calls = {}

    class DummyS3:
        def upload_file(self, file_path, bucket, key):
            calls["file_path"] = file_path
            calls["bucket"] = bucket
            calls["key"] = key

    # Patch module-level s3 object
    monkeypatch.setattr(s3upload, "s3", DummyS3())
    monkeypatch.setenv("S3_BUCKET", "test-bucket")

    # Call function
    s3upload.upload_to_s3(str(test_file), "dummy.txt")

    assert calls["file_path"] == str(test_file)
    assert calls["bucket"] == "test-bucket"
    assert calls["key"] == "dummy.txt"


def test_upload_to_s3_missing_bucket(monkeypatch, tmp_path):
    monkeypatch.delenv("S3_BUCKET", raising=False)

    test_file = tmp_path / "dummy.txt"
    test_file.write_text("hello world")

    with pytest.raises(ValueError):
        s3upload.upload_to_s3(str(test_file), "dummy.txt")
